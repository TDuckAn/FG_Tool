import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fugrade_automation/core/utils/app_logger.dart';
import 'package:fugrade_automation/data/datasources/fg_parser_datasource.dart';
import 'package:fugrade_automation/data/models/teacher_grade_dto.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class FgLoaderEvent {}

class FgFileSelected extends FgLoaderEvent {
  final String filePath;
  FgFileSelected(this.filePath);
}

class FgReloadRequested extends FgLoaderEvent {
  final String filePath;
  FgReloadRequested(this.filePath);
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class FgLoaderState {}

class FgLoaderInitial extends FgLoaderState {}

class FgLoaderLoading extends FgLoaderState {}

class FgLoaderLoaded extends FgLoaderState {
  final TeacherGradeDto grade;
  final String filePath;
  FgLoaderLoaded(this.grade, this.filePath);
}

class FgLoaderError extends FgLoaderState {
  final String message;
  final int exitCode;
  FgLoaderError(this.message, {this.exitCode = 2});
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class FgLoaderBloc extends Bloc<FgLoaderEvent, FgLoaderState> {
  final FgParserDatasource _parser;

  FgLoaderBloc(this._parser) : super(FgLoaderInitial()) {
    on<FgFileSelected>(_onFileSelected);
    on<FgReloadRequested>(_onFileSelected);
  }

  Future<void> _onFileSelected(
    FgLoaderEvent event,
    Emitter<FgLoaderState> emit,
  ) async {
    final path = event is FgFileSelected
        ? event.filePath
        : (event as FgReloadRequested).filePath;

    emit(FgLoaderLoading());
    try {
      final grade = await _parser.parseFgFile(path);
      emit(FgLoaderLoaded(grade, path));
    } on FgParseException catch (e, st) {
      AppLogger.error(
        'FgParser failed (exit ${e.exitCode}): ${e.message}',
        tag: 'FgLoader',
        error: e,
        stack: st,
      );
      emit(FgLoaderError(e.message, exitCode: e.exitCode));
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error parsing .fg file',
        tag: 'FgLoader',
        error: e,
        stack: st,
      );
      emit(FgLoaderError(e.toString()));
    }
  }
}
