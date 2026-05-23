import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fugrade_automation/core/utils/app_logger.dart';
import 'package:fugrade_automation/data/datasources/cmt_writer_datasource.dart';
import 'package:fugrade_automation/data/models/cmt_draft_dto.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ExportEvent {}

class ExportOutputDirSelected extends ExportEvent {
  final String dirPath;
  ExportOutputDirSelected(this.dirPath);
}

class ExportAllRequested extends ExportEvent {
  final List<CmtDraftDto> drafts;
  ExportAllRequested(this.drafts);
}

class ExportSingleRequested extends ExportEvent {
  final CmtDraftDto draft;
  ExportSingleRequested(this.draft);
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class ExportState {}

class ExportIdle extends ExportState {
  final String? outputDir;
  ExportIdle({this.outputDir});
}

class ExportInProgress extends ExportState {
  final int done;
  final int total;
  ExportInProgress(this.done, this.total);
}

class ExportResult {
  final CmtDraftDto draft;
  final bool success;
  final String? outputPath;
  final String? error;
  ExportResult.success(this.draft, this.outputPath) : success = true, error = null;
  ExportResult.failure(this.draft, this.error) : success = false, outputPath = null;
}

class ExportCompleted extends ExportState {
  final List<ExportResult> results;
  final String outputDir;
  ExportCompleted(this.results, this.outputDir);

  int get successCount => results.where((r) => r.success).length;
  int get failCount => results.where((r) => !r.success).length;
}

class ExportError extends ExportState {
  final String message;
  ExportError(this.message);
}

/// Emitted when a single-export pre-flight finds missing required fields.
class ExportValidationFailed extends ExportState {
  final String classCode;
  final List<String> missingFields;
  ExportValidationFailed(this.classCode, this.missingFields);
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final CmtWriterDatasource _writer;
  String? _outputDir;

  ExportBloc(this._writer) : super(ExportIdle()) {
    on<ExportOutputDirSelected>((e, emit) {
      _outputDir = e.dirPath;
      emit(ExportIdle(outputDir: e.dirPath));
    });
    on<ExportAllRequested>(_onExportAll);
    on<ExportSingleRequested>(_onExportSingle);
  }

  /// Single-group export — bypasses the Complete-only filter so users can
  /// preview-export an in-progress draft, but still validates required fields.
  Future<void> _onExportSingle(
      ExportSingleRequested event, Emitter<ExportState> emit) async {
    if (_outputDir == null) {
      emit(ExportError('No output folder selected. Choose a folder first.'));
      return;
    }

    final missing = event.draft.validateForExport();
    if (missing.isNotEmpty) {
      AppLogger.warning(
          'Pre-flight validation failed for ${event.draft.classCode}: '
          '${missing.length} required field(s) empty',
          tag: 'Export');
      emit(ExportValidationFailed(event.draft.classCode, missing));
      return;
    }

    AppLogger.info('Exporting single draft: ${event.draft.classCode}',
        tag: 'Export');
    emit(ExportInProgress(0, 1));
    final results = <ExportResult>[];
    try {
      final path = await _writer.writeCmt(event.draft, _outputDir!);
      AppLogger.info('Exported ${event.draft.classCode} → $path', tag: 'Export');
      results.add(ExportResult.success(event.draft, path));
    } catch (e, st) {
      AppLogger.error('Export failed: ${event.draft.classCode}',
          tag: 'Export', error: e, stack: st);
      results.add(ExportResult.failure(event.draft, e.toString()));
    }
    emit(ExportCompleted(results, _outputDir!));
  }

  Future<void> _onExportAll(
      ExportAllRequested event, Emitter<ExportState> emit) async {
    if (_outputDir == null) {
      emit(ExportError('No output folder selected. Choose a folder first.'));
      return;
    }
    final drafts = event.drafts
        .where((d) => d.status == DraftStatus.complete)
        .toList();
    if (drafts.isEmpty) {
      emit(ExportError('No complete drafts to export.'));
      return;
    }

    AppLogger.info('Exporting ${drafts.length} drafts to $_outputDir', tag: 'Export');
    emit(ExportInProgress(0, drafts.length));
    final results = <ExportResult>[];
    for (int i = 0; i < drafts.length; i++) {
      final missing = drafts[i].validateForExport();
      if (missing.isNotEmpty) {
        final msg = 'Missing required field(s): ${missing.join(", ")}';
        AppLogger.warning('Skipped ${drafts[i].classCode} — $msg', tag: 'Export');
        results.add(ExportResult.failure(drafts[i], msg));
        emit(ExportInProgress(i + 1, drafts.length));
        continue;
      }
      try {
        final path = await _writer.writeCmt(drafts[i], _outputDir!);
        AppLogger.info('Exported ${drafts[i].classCode} → $path', tag: 'Export');
        results.add(ExportResult.success(drafts[i], path));
      } catch (e, st) {
        AppLogger.error('Export failed: ${drafts[i].classCode}', tag: 'Export', error: e, stack: st);
        results.add(ExportResult.failure(drafts[i], e.toString()));
      }
      emit(ExportInProgress(i + 1, drafts.length));
    }
    final completed = ExportCompleted(results, _outputDir!);
    AppLogger.info('Export done: ${completed.successCount} ok, ${completed.failCount} failed', tag: 'Export');
    emit(completed);
  }
}
