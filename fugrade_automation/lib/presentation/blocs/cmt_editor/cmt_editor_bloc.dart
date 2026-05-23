import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fugrade_automation/core/utils/app_logger.dart';
import 'package:fugrade_automation/data/datasources/local_storage_datasource.dart';
import 'package:fugrade_automation/data/models/cmt_draft_dto.dart';
import 'package:fugrade_automation/data/models/group_match_result.dart';
import 'package:fugrade_automation/data/models/member_contribution_dto.dart';
import 'package:fugrade_automation/data/models/student_decision_dto.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class CmtEditorEvent {}

class DraftLoaded extends CmtEditorEvent {
  final CmtDraftDto draft;
  DraftLoaded(this.draft);
}

class DraftPopulatedFromSheet extends CmtEditorEvent {
  final GroupMatchResult matchResult;
  final List<MemberContributionDto> contributions;
  DraftPopulatedFromSheet(this.matchResult, this.contributions);
}

class FieldUpdated extends CmtEditorEvent {
  final String field; // 'titleVN' | 'titleEN' | 'content' | etc.
  final String value;
  FieldUpdated(this.field, this.value);
}

class DecisionUpdated extends CmtEditorEvent {
  final String roll;
  final DefenseOutcome outcome;
  DecisionUpdated(this.roll, this.outcome);
}

class NoteUpdated extends CmtEditorEvent {
  final String roll;
  final String note;
  NoteUpdated(this.roll, this.note);
}

class MarkCompleteRequested extends CmtEditorEvent {}

class SaveDraftRequested extends CmtEditorEvent {}

// ── States ────────────────────────────────────────────────────────────────────

abstract class CmtEditorState {}

class CmtEditorIdle extends CmtEditorState {}

class CmtEditorEditing extends CmtEditorState {
  final CmtDraftDto draft;
  final List<String> validationErrors;
  CmtEditorEditing(this.draft, {this.validationErrors = const []});
}

class CmtEditorSaved extends CmtEditorState {
  final CmtDraftDto draft;
  CmtEditorSaved(this.draft);
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class CmtEditorBloc extends Bloc<CmtEditorEvent, CmtEditorState> {
  final LocalStorageDatasource _storage;

  CmtEditorBloc(this._storage) : super(CmtEditorIdle()) {
    on<DraftLoaded>((e, emit) => emit(CmtEditorEditing(e.draft)));
    on<DraftPopulatedFromSheet>(_onPopulateFromSheet);
    on<FieldUpdated>(_onFieldUpdated);
    on<DecisionUpdated>(_onDecisionUpdated);
    on<NoteUpdated>(_onNoteUpdated);
    on<MarkCompleteRequested>(_onMarkComplete);
    on<SaveDraftRequested>(_onSaveDraft);
  }

  CmtDraftDto? get _current =>
      state is CmtEditorEditing ? (state as CmtEditorEditing).draft : null;

  void _onPopulateFromSheet(
      DraftPopulatedFromSheet event, Emitter<CmtEditorState> emit) {
    final draft = _current;
    if (draft == null || event.matchResult.matchedRow == null) return;
    final row = event.matchResult.matchedRow!;
    emit(CmtEditorEditing(draft.copyWith(
      titleVN: row.titleVN,
      titleEN: row.titleEN,
      content: row.content,
      formComment: row.form,
      attitude: row.attitude,
      achievement: row.achievement,
      limitation: row.limitation,
      conclusion: row.conclusion,
      contributions: event.contributions,
      matchStatus: event.matchResult.matchStatus,
      status: DraftStatus.draft,
      lastEditedAt: DateTime.now(),
    )));
  }

  void _onFieldUpdated(FieldUpdated event, Emitter<CmtEditorState> emit) {
    final draft = _current;
    if (draft == null) return;
    final updated = switch (event.field) {
      'titleVN' => draft.copyWith(titleVN: event.value),
      'titleEN' => draft.copyWith(titleEN: event.value),
      'content' => draft.copyWith(content: event.value),
      'formComment' => draft.copyWith(formComment: event.value),
      'attitude' => draft.copyWith(attitude: event.value),
      'achievement' => draft.copyWith(achievement: event.value),
      'limitation' => draft.copyWith(limitation: event.value),
      'conclusion' => draft.copyWith(conclusion: event.value),
      _ => draft,
    };
    emit(CmtEditorEditing(
        updated.copyWith(status: DraftStatus.draft, lastEditedAt: DateTime.now())));
  }

  void _onDecisionUpdated(DecisionUpdated event, Emitter<CmtEditorState> emit) {
    final draft = _current;
    if (draft == null) return;
    final decisions = draft.decisions
        .map((d) => d.roll == event.roll ? d.copyWith(outcome: event.outcome) : d)
        .toList();
    emit(CmtEditorEditing(
        draft.copyWith(decisions: decisions, lastEditedAt: DateTime.now())));
  }

  void _onNoteUpdated(NoteUpdated event, Emitter<CmtEditorState> emit) {
    final draft = _current;
    if (draft == null) return;
    final decisions = draft.decisions
        .map((d) => d.roll == event.roll ? d.copyWith(note: event.note) : d)
        .toList();
    emit(CmtEditorEditing(
        draft.copyWith(decisions: decisions, lastEditedAt: DateTime.now())));
  }

  Future<void> _onMarkComplete(
      MarkCompleteRequested event, Emitter<CmtEditorState> emit) async {
    final draft = _current;
    if (draft == null) return;
    final errors = _validate(draft);
    if (errors.isNotEmpty) {
      AppLogger.info(
          'Validation failed (${errors.length} missing fields) — staying in draft mode',
          tag: 'CmtEditor');
      emit(CmtEditorEditing(draft, validationErrors: errors));
      return;
    }
    final completed = draft.copyWith(
        status: DraftStatus.complete, lastEditedAt: DateTime.now());
    try {
      await _storage.saveDraft(completed);
      AppLogger.info('Draft marked complete: ${draft.classCode}', tag: 'CmtEditor');
      emit(CmtEditorSaved(completed));
    } catch (e, st) {
      AppLogger.error('Failed to save completed draft', tag: 'CmtEditor', error: e, stack: st);
    }
  }

  Future<void> _onSaveDraft(
      SaveDraftRequested event, Emitter<CmtEditorState> emit) async {
    final draft = _current;
    if (draft == null) return;
    try {
      await _storage.saveDraft(draft);
      AppLogger.info('Draft saved: ${draft.classCode}', tag: 'CmtEditor');
      emit(CmtEditorSaved(draft));
    } catch (e, st) {
      AppLogger.error('Failed to save draft', tag: 'CmtEditor', error: e, stack: st);
    }
  }

  List<String> _validate(CmtDraftDto draft) {
    final issues = <String>[];
    if (draft.matchStatus == MatchStatus.none) {
      if (draft.titleVN.trim().isEmpty) issues.add('Thesis title (Vietnamese) is required');
      if (draft.titleEN.trim().isEmpty) issues.add('Thesis title (English) is required');
      if (draft.content.trim().isEmpty) issues.add('Section 3.1 Content is required');
      if (draft.formComment.trim().isEmpty) issues.add('Section 3.2 Form is required');
      if (draft.attitude.trim().isEmpty) issues.add('Section 3.3 Attitude is required');
      if (draft.achievement.trim().isEmpty) issues.add('Section 4.1 Achievement is required');
      if (draft.limitation.trim().isEmpty) issues.add('Section 4.2 Limitation is required');
      if (draft.conclusion.trim().isEmpty) issues.add('Conclusion is required');
    }
    return issues;
  }
}
