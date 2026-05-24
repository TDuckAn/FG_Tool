import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fugrade_automation/core/theme/app_theme.dart';
import 'package:fugrade_automation/data/datasources/local_storage_datasource.dart';
import 'package:fugrade_automation/data/models/cmt_draft_dto.dart';
import 'package:fugrade_automation/data/models/group_match_result.dart';
import 'package:fugrade_automation/data/models/student_decision_dto.dart';
import 'package:fugrade_automation/data/models/teacher_grade_dto.dart';
import 'package:fugrade_automation/presentation/blocs/cmt_editor/cmt_editor_bloc.dart';
import 'package:fugrade_automation/presentation/blocs/export/export_bloc.dart';
import 'package:fugrade_automation/presentation/blocs/sheet_sync/sheet_sync_bloc.dart';
import 'cmt_editor_screen.dart';

class GroupListScreen extends StatefulWidget {
  final TeacherGradeDto grade;
  final String fgFilePath;

  const GroupListScreen({
    super.key,
    required this.grade,
    required this.fgFilePath,
  });

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  Map<String, DraftStatus> _draftStatusByClass = {};

  @override
  void initState() {
    super.initState();
    _reloadDrafts();
  }

  Future<void> _reloadDrafts() async {
    final storage = context.read<LocalStorageDatasource>();
    final drafts = await storage.loadAllDrafts(
      widget.grade.semester,
      widget.grade.login,
    );
    if (!mounted) return;
    setState(() {
      _draftStatusByClass = {for (final d in drafts) d.classCode: d.status};
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CmtEditorBloc, CmtEditorState>(
          listener: (_, state) {
            if (state is CmtEditorSaved) _reloadDrafts();
          },
        ),
        BlocListener<ExportBloc, ExportState>(
          listener: (context, state) {
            if (state is ExportValidationFailed) {
              showDialog(
                context: context,
                builder: (_) => _ExportMissingFieldsDialog(
                  classCode: state.classCode,
                  missing: state.missingFields,
                ),
              );
            } else if (state is ExportCompleted) {
              showDialog(
                context: context,
                builder: (_) => _ExportResultDialog(state: state),
              );
            } else if (state is ExportError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.rust,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Column(
              children: [
                _Masthead(grade: widget.grade),
                _ToolBar(grade: widget.grade, onExport: _exportAll),
                Expanded(
                  child: BlocBuilder<SheetSyncBloc, SheetSyncState>(
                    builder: (context, syncState) {
                      if (syncState is SheetSyncLoading) {
                        return const _LoadingBlock();
                      }

                      final matchResults = syncState is SheetSyncLoaded
                          ? syncState.matchResults
                          : widget.grade.capstoneGroups
                                .map((g) => GroupMatchResult.none(g))
                                .toList();

                      return Column(
                        children: [
                          if (syncState is SheetSyncLoaded &&
                              syncState.usingCache)
                            _Banner(
                              kind: _BannerKind.info,
                              text:
                                  'Showing cached sheet data. Click Sync to refresh.',
                            ),
                          if (syncState is SheetSyncError)
                            _Banner(
                              kind: _BannerKind.error,
                              text: syncState.message,
                            ),
                          Expanded(
                            child: _Ledger(
                              grade: widget.grade,
                              fgFilePath: widget.fgFilePath,
                              matchResults: matchResults,
                              draftStatusByClass: _draftStatusByClass,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportAll(BuildContext context) async {
    final storage = context.read<LocalStorageDatasource>();
    final drafts = await storage.loadAllDrafts(
      widget.grade.semester,
      widget.grade.login,
    );
    final completeDrafts = drafts
        .where((d) => d.status == DraftStatus.complete)
        .toList();

    if (!context.mounted) return;
    final missing = _firstMissingExportFields(completeDrafts);
    if (missing != null) {
      showDialog(
        context: context,
        builder: (_) => _ExportMissingFieldsDialog(
          classCode: missing.$1,
          missing: missing.$2,
        ),
      );
      return;
    }

    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select export folder',
    );
    if (dir == null || !context.mounted) return;

    context.read<ExportBloc>().add(ExportOutputDirSelected(dir));
    context.read<ExportBloc>().add(ExportAllRequested(drafts));
  }

  (String, List<String>)? _firstMissingExportFields(List<CmtDraftDto> drafts) {
    for (final draft in drafts) {
      final missing = draft.validateForExport();
      if (missing.isNotEmpty) return (draft.classCode, missing);
    }
    return null;
  }
}

// ── Masthead — the editorial header ────────────────────────────────────────

class _Masthead extends StatelessWidget {
  final TeacherGradeDto grade;
  const _Masthead({required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 28),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.rule, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker(text: 'Capstone Groups'),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    grade.login,
                    style: AppTheme.display(36, weight: FontWeight.w600),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    ' / ',
                    style: AppTheme.display(
                      28,
                      weight: FontWeight.w300,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    grade.semester,
                    style: AppTheme.display(
                      28,
                      weight: FontWeight.w400,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _MetaCol(label: 'GROUPS', value: '${grade.capstoneGroups.length}'),
          const SizedBox(width: 40),
          _MetaCol(
            label: 'STUDENTS',
            value:
                '${grade.capstoneGroups.fold<int>(0, (a, g) => a + g.students.length)}',
          ),
          const SizedBox(width: 40),
          _MetaCol(label: 'VERSION', value: grade.version),
        ],
      ),
    );
  }
}

class _MetaCol extends StatelessWidget {
  final String label;
  final String value;
  const _MetaCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTheme.label(9, color: AppTheme.inkMuted)),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.display(22, weight: FontWeight.w500)),
      ],
    );
  }
}

// ── Tool Bar ───────────────────────────────────────────────────────────────

class _ToolBar extends StatelessWidget {
  final TeacherGradeDto grade;
  final Future<void> Function(BuildContext) onExport;
  const _ToolBar({required this.grade, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.paperDeep,
        border: Border(bottom: BorderSide(color: AppTheme.rule, width: 1)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => _showSheetDialog(context),
            icon: const Icon(Icons.link, size: 16),
            label: const Text('CONNECT SHEET'),
          ),
          const SizedBox(width: 12),
          BlocBuilder<SheetSyncBloc, SheetSyncState>(
            builder: (ctx, state) => OutlinedButton.icon(
              onPressed: state is SheetSyncLoaded
                  ? () => ctx.read<SheetSyncBloc>().add(
                      SheetSyncRequested(
                        fgGroups: grade.capstoneGroups,
                        fgSemester: grade.semester,
                        fgLogin: grade.login,
                      ),
                    )
                  : null,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('SYNC'),
            ),
          ),
          const Spacer(),
          BlocBuilder<SheetSyncBloc, SheetSyncState>(
            builder: (ctx, state) {
              if (state is SheetSyncLoaded) {
                final matched = state.matchResults
                    .where((r) => r.matchStatus == MatchStatus.exact)
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    '$matched of ${state.matchResults.length} matched',
                    style: AppTheme.body(12, color: AppTheme.inkSoft),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          BlocBuilder<ExportBloc, ExportState>(
            builder: (ctx, state) => FilledButton.icon(
              onPressed: state is ExportInProgress ? null : () => onExport(ctx),
              icon: state is ExportInProgress
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.4,
                        color: AppTheme.paper,
                        value: state.total == 0
                            ? null
                            : state.done / state.total,
                      ),
                    )
                  : const Icon(Icons.arrow_outward, size: 16),
              label: Text(
                state is ExportInProgress
                    ? 'EXPORTING  ${state.done} / ${state.total}'
                    : 'EXPORT ALL',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSheetDialog(BuildContext context) {
    final responseCtrl = TextEditingController();
    final finalCtrl = TextEditingController();
    context.read<LocalStorageDatasource>().loadConfig().then((config) {
      responseCtrl.text = (config['responseSheetUrl'] ?? '').toString();
      finalCtrl.text = (config['finalSheetUrl'] ?? '').toString();
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Kicker(text: 'Connect Sheet', number: '§'),
            const Spacer(),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste the response sheet URL and optional FINAL sheet URL.',
                style: AppTheme.body(14, color: AppTheme.inkSoft),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: responseCtrl,
                style: AppTheme.mono(13),
                decoration: const InputDecoration(
                  labelText: 'Google Form Response Sheet URL',
                  hintText: 'https://docs.google.com/spreadsheets/d/…',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: finalCtrl,
                style: AppTheme.mono(13),
                decoration: const InputDecoration(
                  labelText: 'Google FINAL Sheet URL',
                  hintText: 'https://docs.google.com/spreadsheets/d/…',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              final responseUrl = responseCtrl.text.trim();
              final finalUrl = finalCtrl.text.trim();
              Navigator.pop(ctx);

              await context.read<LocalStorageDatasource>().saveSheetUrls(
                responseSheetUrl: responseUrl,
                finalSheetUrl: finalUrl,
              );

              if (!context.mounted) return;
              context.read<SheetSyncBloc>().add(
                SheetUrlSubmitted(
                  url: responseUrl,
                  fgGroups: grade.capstoneGroups,
                  fgSemester: grade.semester,
                  fgLogin: grade.login,
                ),
              );
            },
            child: const Text('CONNECT'),
          ),
        ],
      ),
    );
  }
}

// ── Banner ─────────────────────────────────────────────────────────────────

enum _BannerKind { info, error }

class _Banner extends StatelessWidget {
  final _BannerKind kind;
  final String text;
  const _Banner({required this.kind, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      _BannerKind.info => AppTheme.ochre,
      _BannerKind.error => AppTheme.rust,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: AppTheme.body(13, color: AppTheme.ink)),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 1.4,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Fetching Google Sheet',
            style: AppTheme.label(11, color: AppTheme.inkSoft),
          ),
        ],
      ),
    );
  }
}

// ── Ledger — the academic table ────────────────────────────────────────────

class _Ledger extends StatelessWidget {
  final TeacherGradeDto grade;
  final String fgFilePath;
  final List<GroupMatchResult> matchResults;
  final Map<String, DraftStatus> draftStatusByClass;
  const _Ledger({
    required this.grade,
    required this.fgFilePath,
    required this.matchResults,
    required this.draftStatusByClass,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border.all(color: AppTheme.ink, width: 1),
        ),
        child: Column(
          children: [
            _LedgerHeader(),
            const Divider(height: 1, color: AppTheme.ink),
            Expanded(
              child: ListView.separated(
                itemCount: matchResults.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppTheme.rule),
                itemBuilder: (context, i) => _LedgerRow(
                  index: i + 1,
                  grade: grade,
                  fgFilePath: fgFilePath,
                  result: matchResults[i],
                  draftStatus:
                      draftStatusByClass[matchResults[i].group.classCode] ??
                      DraftStatus.notStarted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppTheme.ink,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('#', style: AppTheme.label(10, color: AppTheme.paper)),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'SUBJECT',
              style: AppTheme.label(10, color: AppTheme.paper),
            ),
          ),
          Expanded(
            child: Text(
              'GROUP / CLASS CODE',
              style: AppTheme.label(10, color: AppTheme.paper),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'STUDENTS',
              style: AppTheme.label(10, color: AppTheme.paper),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              'COMPLETION',
              style: AppTheme.label(10, color: AppTheme.paper),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              'SHEET MATCH',
              style: AppTheme.label(10, color: AppTheme.paper),
            ),
          ),
          const SizedBox(width: 120),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatefulWidget {
  final int index;
  final TeacherGradeDto grade;
  final String fgFilePath;
  final GroupMatchResult result;
  final DraftStatus draftStatus;
  const _LedgerRow({
    required this.index,
    required this.grade,
    required this.fgFilePath,
    required this.result,
    required this.draftStatus,
  });

  @override
  State<_LedgerRow> createState() => _LedgerRowState();
}

class _LedgerRowState extends State<_LedgerRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.result.group;
    final (matchLabel, matchColor) = switch (widget.result.matchStatus) {
      MatchStatus.exact => ('MATCHED', AppTheme.forest),
      MatchStatus.partial => ('PARTIAL', AppTheme.ochre),
      MatchStatus.none => ('NO MATCH', AppTheme.rust),
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hover
            ? AppTheme.accentSoft.withValues(alpha: 0.4)
            : AppTheme.card,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                widget.index.toString().padLeft(2, '0'),
                style: AppTheme.mono(
                  13,
                  color: AppTheme.inkMuted,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                group.subject,
                style: AppTheme.mono(13, weight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                group.classCode,
                style: AppTheme.body(14, weight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 90,
              child: Row(
                children: [
                  Text(
                    '${group.students.length}',
                    style: AppTheme.display(20, weight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'STD',
                    style: AppTheme.label(9, color: AppTheme.inkMuted),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 140,
              child: StatusPill(
                label: widget.draftStatus == DraftStatus.complete
                    ? 'COMPLETED'
                    : 'NOT COMPLETED',
                color: widget.draftStatus == DraftStatus.complete
                    ? AppTheme.forest
                    : AppTheme.ochre,
                filled: widget.draftStatus == DraftStatus.complete,
              ),
            ),
            SizedBox(
              width: 140,
              child: StatusPill(label: matchLabel, color: matchColor),
            ),
            Tooltip(
              message: 'Export this group as .cmt',
              child: SizedBox(
                width: 34,
                height: 34,
                child: OutlinedButton(
                  onPressed: () => _exportSingle(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.ink,
                    side: const BorderSide(color: AppTheme.rule, width: 1),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 34),
                  ),
                  child: const Icon(Icons.arrow_outward, size: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                offset: _hover ? const Offset(0.04, 0) : Offset.zero,
                child: FilledButton(
                  onPressed: () => _openEditor(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.ink,
                    foregroundColor: AppTheme.paper,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    minimumSize: const Size(0, 34),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('EDIT'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSingle(BuildContext context) async {
    final storage = context.read<LocalStorageDatasource>();
    final draft = await storage.loadDraft(
      widget.grade.semester,
      widget.grade.login,
      widget.result.group.classCode,
    );

    if (!context.mounted) return;

    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No draft yet. Click EDIT to create one first.'),
        ),
      );
      return;
    }

    final missing = draft.validateForExport();
    if (missing.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => _ExportMissingFieldsDialog(
          classCode: draft.classCode,
          missing: missing,
        ),
      );
      return;
    }

    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select export folder for ${widget.result.group.classCode}',
    );
    if (dir == null || !context.mounted) return;

    context.read<ExportBloc>().add(ExportOutputDirSelected(dir));
    context.read<ExportBloc>().add(ExportSingleRequested(draft));
  }

  Future<void> _openEditor(BuildContext context) async {
    final storage = context.read<LocalStorageDatasource>();
    CmtDraftDto? draft = await storage.loadDraft(
      widget.grade.semester,
      widget.grade.login,
      widget.result.group.classCode,
    );
    draft ??= _buildNewDraft();
    final group = widget.result.group;
    if (draft.gradingComponents.isEmpty && group.gradingComponents.isNotEmpty) {
      draft = draft.copyWith(gradingComponents: group.gradingComponents);
      await storage.saveDraft(draft);
    }

    if (!context.mounted) return;
    context.read<CmtEditorBloc>().add(DraftLoaded(draft));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CmtEditorScreen(draft: draft!, fgFilePath: widget.fgFilePath),
      ),
    );
  }

  CmtDraftDto _buildNewDraft() {
    final group = widget.result.group;
    return CmtDraftDto(
      teacherLogin: widget.grade.login,
      semester: widget.grade.semester,
      subjectCode: group.subject,
      classCode: group.classCode,
      students: group.students,
      fgVersion: widget.grade.version,
      gradingComponents: group.gradingComponents,
      decisions: group.students
          .map(
            (s) => StudentDecisionDto(
              roll: s.roll,
              name: s.name,
              outcome: DefenseOutcome.agree,
              note: '',
            ),
          )
          .toList(),
      matchStatus: widget.result.matchStatus,
    );
  }
}

// ── Export Result Dialog ──────────────────────────────────────────────────

class _ExportMissingFieldsDialog extends StatelessWidget {
  final String classCode;
  final List<String> missing;
  const _ExportMissingFieldsDialog({
    required this.classCode,
    required this.missing,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Kicker(
            text: 'Export Blocked',
            number: '§',
            color: AppTheme.rust,
          ),
          const Spacer(),
          Text(
            '${missing.length}',
            style: AppTheme.display(
              40,
              weight: FontWeight.w600,
              color: AppTheme.rust,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Group $classCode is missing ${missing.length} required field(s). '
              'Fill them in before exporting to .cmt.',
              style: AppTheme.body(14, color: AppTheme.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.rust.withValues(alpha: 0.06),
                border: Border.all(color: AppTheme.rust.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in missing)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 14,
                            margin: const EdgeInsets.only(top: 3, right: 12),
                            color: AppTheme.rust,
                          ),
                          Expanded(child: Text(f, style: AppTheme.body(13))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('GOT IT'),
        ),
      ],
    );
  }
}

class _ExportResultDialog extends StatelessWidget {
  final ExportCompleted state;
  const _ExportResultDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final failures = state.results.where((r) => !r.success).toList();

    return AlertDialog(
      title: Row(
        children: [
          const Kicker(text: 'Export Complete', number: '§'),
          const Spacer(),
          Text(
            '${state.successCount}',
            style: AppTheme.display(
              40,
              weight: FontWeight.w600,
              color: AppTheme.forest,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Files written',
                style: AppTheme.label(10, color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.paperDeep,
                  border: Border.all(color: AppTheme.rule),
                ),
                child: SelectableText(
                  state.outputDir,
                  style: AppTheme.mono(12),
                ),
              ),
              if (failures.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    StatusPill(
                      label: '${state.failCount} FAILED',
                      color: AppTheme.rust,
                      filled: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.rust.withValues(alpha: 0.06),
                    border: Border.all(
                      color: AppTheme.rust.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final f in failures)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 14,
                                    margin: const EdgeInsets.only(right: 10),
                                    color: AppTheme.rust,
                                  ),
                                  Text(
                                    f.draft.classCode,
                                    style: AppTheme.mono(
                                      13,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 14,
                                  top: 4,
                                ),
                                child: Text(
                                  f.error ?? 'Unknown error',
                                  style: AppTheme.body(
                                    12,
                                    color: AppTheme.inkSoft,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('DISMISS'),
        ),
      ],
    );
  }
}
