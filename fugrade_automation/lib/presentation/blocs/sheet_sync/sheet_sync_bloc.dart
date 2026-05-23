import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fugrade_automation/core/utils/app_logger.dart';
import 'package:fugrade_automation/data/datasources/sheets_api_datasource.dart';
import 'package:fugrade_automation/data/models/group_match_result.dart';
import 'package:fugrade_automation/data/models/sheet_row_dto.dart';
import 'package:fugrade_automation/data/models/subject_class_grade_dto.dart';
import 'package:fugrade_automation/domain/services/matching_service.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class SheetSyncEvent {}

class SheetUrlSubmitted extends SheetSyncEvent {
  final String url;
  final List<SubjectClassGradeDto> fgGroups;
  final String fgSemester;
  final String fgLogin;
  SheetUrlSubmitted({
    required this.url,
    required this.fgGroups,
    required this.fgSemester,
    required this.fgLogin,
  });
}

class SheetSyncRequested extends SheetSyncEvent {
  final List<SubjectClassGradeDto> fgGroups;
  final String fgSemester;
  final String fgLogin;
  SheetSyncRequested({
    required this.fgGroups,
    required this.fgSemester,
    required this.fgLogin,
  });
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class SheetSyncState {}

class SheetSyncInitial extends SheetSyncState {}

class SheetSyncLoading extends SheetSyncState {}

class SheetSyncLoaded extends SheetSyncState {
  final List<GroupMatchResult> matchResults;
  final List<SheetRowDto> allRows;
  final String sheetUrl;
  final bool usingCache;
  SheetSyncLoaded({
    required this.matchResults,
    required this.allRows,
    required this.sheetUrl,
    this.usingCache = false,
  });
}

class SheetSyncError extends SheetSyncState {
  final String message;
  SheetSyncError(this.message);
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class SheetSyncBloc extends Bloc<SheetSyncEvent, SheetSyncState> {
  final SheetsApiDatasource _sheets;
  final MatchingService _matcher;
  String? _lastUrl;

  SheetSyncBloc(this._sheets, this._matcher) : super(SheetSyncInitial()) {
    on<SheetUrlSubmitted>(_onUrlSubmitted);
    on<SheetSyncRequested>(_onSyncRequested);
  }

  Future<void> _onUrlSubmitted(
      SheetUrlSubmitted event, Emitter<SheetSyncState> emit) async {
    _lastUrl = event.url;
    await _doSync(event.url, event.fgGroups, event.fgSemester, event.fgLogin, emit);
  }

  Future<void> _onSyncRequested(
      SheetSyncRequested event, Emitter<SheetSyncState> emit) async {
    if (_lastUrl == null) return;
    await _doSync(_lastUrl!, event.fgGroups, event.fgSemester, event.fgLogin, emit);
  }

  Future<void> _doSync(String url, List<SubjectClassGradeDto> groups,
      String semester, String login, Emitter<SheetSyncState> emit) async {
    emit(SheetSyncLoading());
    try {
      bool usingCache = false;
      List<SheetRowDto> rows;
      try {
        rows = await _sheets.fetchRows(url);
      } catch (_) {
        rows = await _sheets.fetchRowsCached(url);
        usingCache = true;
      }
      final results = _matcher.match(
          fgGroups: groups,
          sheetRows: rows,
          fgSemester: semester,
          fgLogin: login);
      emit(SheetSyncLoaded(
          matchResults: results,
          allRows: rows,
          sheetUrl: url,
          usingCache: usingCache));
    } on SheetsApiException catch (e, st) {
      AppLogger.error('SheetsApi error: ${e.message}', tag: 'SheetSync', error: e, stack: st);
      emit(SheetSyncError(e.message));
    } catch (e, st) {
      AppLogger.error('Unexpected error during sheet sync', tag: 'SheetSync', error: e, stack: st);
      emit(SheetSyncError(e.toString()));
    }
  }
}
