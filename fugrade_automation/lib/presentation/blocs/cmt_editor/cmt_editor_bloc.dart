import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fugrade_automation/core/utils/app_logger.dart';
import 'package:fugrade_automation/data/datasources/local_storage_datasource.dart';
import 'package:fugrade_automation/data/datasources/sheets_api_datasource.dart';
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

class DraftPopulatedFromFinalRequested extends CmtEditorEvent {}

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

class GradingUpdated extends CmtEditorEvent {
  final Map<String, Map<String, double>> grades;
  GradingUpdated(this.grades);
}

class ContributionsManuallyUpdated extends CmtEditorEvent {
  final List<MemberContributionDto> contributions;
  ContributionsManuallyUpdated(this.contributions);
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
  final bool finalSynced;
  final String? warningMessage;
  CmtEditorSaved(this.draft, {this.finalSynced = false, this.warningMessage});
}

class CmtEditorActionFailed extends CmtEditorState {
  final CmtDraftDto draft;
  final String message;
  CmtEditorActionFailed(this.draft, this.message);
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class CmtEditorBloc extends Bloc<CmtEditorEvent, CmtEditorState> {
  final LocalStorageDatasource _storage;
  final SheetsApiDatasource _sheets;

  CmtEditorBloc(this._storage, this._sheets) : super(CmtEditorIdle()) {
    on<DraftLoaded>((e, emit) => emit(CmtEditorEditing(e.draft)));
    on<DraftPopulatedFromSheet>(_onPopulateFromSheet);
    on<DraftPopulatedFromFinalRequested>(_onPopulateFromFinal);
    on<FieldUpdated>(_onFieldUpdated);
    on<DecisionUpdated>(_onDecisionUpdated);
    on<NoteUpdated>(_onNoteUpdated);
    on<GradingUpdated>(_onGradingUpdated);
    on<ContributionsManuallyUpdated>(_onContributionsManuallyUpdated);
    on<MarkCompleteRequested>(_onMarkComplete);
    on<SaveDraftRequested>(_onSaveDraft);
  }

  CmtDraftDto? get _current {
    if (state is CmtEditorEditing) return (state as CmtEditorEditing).draft;
    if (state is CmtEditorSaved) return (state as CmtEditorSaved).draft;
    if (state is CmtEditorActionFailed) {
      return (state as CmtEditorActionFailed).draft;
    }
    return null;
  }

  void _onPopulateFromSheet(
    DraftPopulatedFromSheet event,
    Emitter<CmtEditorState> emit,
  ) {
    final draft = _current;
    if (draft == null || event.matchResult.matchedRow == null) return;
    final row = event.matchResult.matchedRow!;
    emit(
      CmtEditorEditing(
        draft.copyWith(
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
        ),
      ),
    );
  }

  Future<void> _onPopulateFromFinal(
    DraftPopulatedFromFinalRequested event,
    Emitter<CmtEditorState> emit,
  ) async {
    final draft = _current;
    if (draft == null) return;

    final finalSheetUrl = await _storage.loadFinalSheetUrl();
    if (finalSheetUrl.trim().isEmpty) {
      emit(
        CmtEditorActionFailed(
          draft,
          'FINAL sheet URL is not configured. Connect the FINAL sheet first.',
        ),
      );
      emit(CmtEditorEditing(draft));
      return;
    }

    try {
      final rows = await _sheets.fetchRows(finalSheetUrl);
      final row = rows.cast<dynamic>().firstWhere(
        (r) =>
            r.semester == draft.semester &&
            r.subjectCode == draft.subjectCode &&
            r.classCode == draft.classCode &&
            r.teacher == draft.teacherLogin,
        orElse: () => null,
      );
      if (row == null) {
        emit(
          CmtEditorActionFailed(
            draft,
            'No matching FINAL row found for ${draft.classCode}.',
          ),
        );
        emit(CmtEditorEditing(draft));
        return;
      }

      emit(
        CmtEditorEditing(
          draft.copyWith(
            titleVN: row.titleVN,
            titleEN: row.titleEN,
            content: row.content,
            formComment: row.form,
            attitude: row.attitude,
            achievement: row.achievement,
            limitation: row.limitation,
            conclusion: row.conclusion,
            contributions: row.contributions,
            decisions: row.decisions.isNotEmpty
                ? row.decisions
                : draft.decisions,
            grades: row.grades,
            gradingComponents: row.gradingComponents,
            status: row.status ?? DraftStatus.draft,
            lastEditedAt: DateTime.now(),
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to populate from FINAL',
        tag: 'CmtEditor',
        error: e,
        stack: st,
      );
      emit(
        CmtEditorActionFailed(
          draft,
          'Failed to populate from FINAL: ${e.toString()}',
        ),
      );
      emit(CmtEditorEditing(draft));
    }
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
    emit(
      CmtEditorEditing(
        updated.copyWith(
          status: DraftStatus.draft,
          lastEditedAt: DateTime.now(),
        ),
      ),
    );
  }

  void _onDecisionUpdated(DecisionUpdated event, Emitter<CmtEditorState> emit) {
    final draft = _current;
    if (draft == null) return;
    final decisions = draft.decisions
        .map(
          (d) => d.roll == event.roll ? d.copyWith(outcome: event.outcome) : d,
        )
        .toList();
    emit(
      CmtEditorEditing(
        draft.copyWith(decisions: decisions, lastEditedAt: DateTime.now()),
      ),
    );
  }

  void _onNoteUpdated(NoteUpdated event, Emitter<CmtEditorState> emit) {
    final draft = _current;
    if (draft == null) return;
    final decisions = draft.decisions
        .map((d) => d.roll == event.roll ? d.copyWith(note: event.note) : d)
        .toList();
    emit(
      CmtEditorEditing(
        draft.copyWith(decisions: decisions, lastEditedAt: DateTime.now()),
      ),
    );
  }

  void _onGradingUpdated(GradingUpdated event, Emitter<CmtEditorState> emit) {
    final draft = _current;
    if (draft == null) return;
    emit(
      CmtEditorEditing(
        draft.copyWith(
          grades: event.grades,
          status: DraftStatus.draft,
          lastEditedAt: DateTime.now(),
        ),
      ),
    );
  }

  void _onContributionsManuallyUpdated(
    ContributionsManuallyUpdated event,
    Emitter<CmtEditorState> emit,
  ) {
    final draft = _current;
    if (draft == null) return;
    emit(
      CmtEditorEditing(
        draft.copyWith(
          contributions: event.contributions,
          status: DraftStatus.draft,
          lastEditedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onMarkComplete(
    MarkCompleteRequested event,
    Emitter<CmtEditorState> emit,
  ) async {
    final draft = _current;
    if (draft == null) return;
    final errors = _validate(draft);
    if (errors.isNotEmpty) {
      AppLogger.info(
        'Validation failed (${errors.length} missing fields) — staying in draft mode',
        tag: 'CmtEditor',
      );
      emit(CmtEditorEditing(draft, validationErrors: errors));
      return;
    }
    final completed = draft.copyWith(
      status: DraftStatus.complete,
      lastEditedAt: DateTime.now(),
    );
    try {
      await _storage.saveDraft(completed);
      final syncResult = await _saveToFinalIfConfigured(completed);
      AppLogger.info(
        'Draft marked complete: ${draft.classCode}',
        tag: 'CmtEditor',
      );
      emit(
        CmtEditorSaved(
          completed,
          finalSynced: syncResult.synced,
          warningMessage: syncResult.warningMessage,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to save completed draft',
        tag: 'CmtEditor',
        error: e,
        stack: st,
      );
    }
  }

  Future<void> _onSaveDraft(
    SaveDraftRequested event,
    Emitter<CmtEditorState> emit,
  ) async {
    final draft = _current;
    if (draft == null) return;
    try {
      await _storage.saveDraft(draft);
      final syncResult = await _saveToFinalIfConfigured(draft);
      AppLogger.info('Draft saved: ${draft.classCode}', tag: 'CmtEditor');
      emit(
        CmtEditorSaved(
          draft,
          finalSynced: syncResult.synced,
          warningMessage: syncResult.warningMessage,
        ),
      );
      emit(CmtEditorEditing(draft));
    } catch (e, st) {
      AppLogger.error(
        'Failed to save draft',
        tag: 'CmtEditor',
        error: e,
        stack: st,
      );
    }
  }

  Future<_FinalSyncResult> _saveToFinalIfConfigured(CmtDraftDto draft) async {
    final finalSheetUrl = await _storage.loadFinalSheetUrl();
    if (finalSheetUrl.trim().isEmpty) {
      return const _FinalSyncResult(
        synced: false,
        warningMessage:
            'Draft saved locally only. FINAL sheet URL is not configured.',
      );
    }
    try {
      await _sheets.saveDraftToFinalSheet(finalSheetUrl, draft);
      return const _FinalSyncResult(synced: true);
    } catch (e, st) {
      AppLogger.error(
        'Failed to save draft to FINAL',
        tag: 'CmtEditor',
        error: e,
        stack: st,
      );
      return _FinalSyncResult(
        synced: false,
        warningMessage: 'Draft saved locally, but FINAL sync failed: $e',
      );
    }
  }

  List<String> _validate(CmtDraftDto draft) {
    final issues = <String>[];
    if (draft.matchStatus == MatchStatus.none) {
      if (draft.titleVN.trim().isEmpty) {
        issues.add('Thesis title (Vietnamese) is required');
      }
      if (draft.titleEN.trim().isEmpty) {
        issues.add('Thesis title (English) is required');
      }
      if (draft.content.trim().isEmpty) {
        issues.add('Section 3.1 Content is required');
      }
      if (draft.formComment.trim().isEmpty) {
        issues.add('Section 3.2 Form is required');
      }
      if (draft.attitude.trim().isEmpty) {
        issues.add('Section 3.3 Attitude is required');
      }
      if (draft.achievement.trim().isEmpty) {
        issues.add('Section 4.1 Achievement is required');
      }
      if (draft.limitation.trim().isEmpty) {
        issues.add('Section 4.2 Limitation is required');
      }
      if (draft.conclusion.trim().isEmpty) {
        issues.add('Conclusion is required');
      }
    }
    return issues;
  }
}

class _FinalSyncResult {
  final bool synced;
  final String? warningMessage;

  const _FinalSyncResult({required this.synced, this.warningMessage});
}
