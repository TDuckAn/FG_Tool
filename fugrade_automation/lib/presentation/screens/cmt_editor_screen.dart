import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fugrade_automation/core/theme/app_theme.dart';
import 'package:fugrade_automation/core/utils/app_logger.dart';
import 'package:fugrade_automation/core/utils/roll_utils.dart';
import 'package:fugrade_automation/data/models/cmt_draft_dto.dart';
import 'package:fugrade_automation/data/models/group_match_result.dart';
import 'package:fugrade_automation/data/models/student_decision_dto.dart';
import 'package:fugrade_automation/presentation/blocs/cmt_editor/cmt_editor_bloc.dart';
import 'package:fugrade_automation/presentation/blocs/export/export_bloc.dart';
import 'package:fugrade_automation/presentation/blocs/sheet_sync/sheet_sync_bloc.dart';

class CmtEditorScreen extends StatefulWidget {
  final CmtDraftDto draft;

  const CmtEditorScreen({super.key, required this.draft});

  @override
  State<CmtEditorScreen> createState() => _CmtEditorScreenState();
}

class _CmtEditorScreenState extends State<CmtEditorScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CmtEditorBloc>().add(DraftLoaded(widget.draft));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CmtEditorBloc, CmtEditorState>(
          listener: (context, state) {
            if (state is CmtEditorSaved) {
              final msg = state.draft.status == DraftStatus.complete
                  ? 'Marked complete · ${state.draft.classCode}'
                  : 'Draft saved · ${state.draft.classCode}';
              AppLogger.info(msg, tag: 'CmtEditor');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
              if (state.draft.status == DraftStatus.complete) {
                Navigator.of(context).pop();
              }
            }
            if (state is CmtEditorEditing &&
                state.validationErrors.isNotEmpty) {
              showDialog(
                context: context,
                builder: (_) =>
                    _ValidationDialog(errors: state.validationErrors),
              );
            }
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
            } else if (state is ExportCompleted && state.successCount > 0) {
              final result = state.results.first;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exported to ${result.outputPath}'),
                  duration: const Duration(seconds: 5),
                ),
              );
            } else if (state is ExportCompleted && state.failCount > 0) {
              final r = state.results.first;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Export failed: ${r.error}'),
                  backgroundColor: AppTheme.rust,
                ),
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
      child: BlocBuilder<CmtEditorBloc, CmtEditorState>(
        buildWhen: (prev, curr) =>
            curr is CmtEditorEditing || curr is CmtEditorIdle,
        builder: (context, state) {
          final draft = state is CmtEditorEditing ? state.draft : widget.draft;

          return Scaffold(
            body: PaperBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    _EditorMasthead(draft: draft),
                    _EditorToolBar(draft: draft),
                    Expanded(child: _EditorBody(draft: draft)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Masthead ───────────────────────────────────────────────────────────────

class _EditorMasthead extends StatelessWidget {
  final CmtDraftDto draft;
  const _EditorMasthead({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 22, 40, 24),
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
              Kicker(
                  text: 'Thesis Comment · Editor',
                  number: '§ ${draft.subjectCode}'),
              const SizedBox(height: 8),
              Text(
                draft.classCode,
                style: AppTheme.display(36, weight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          _MiniMeta('TEACHER', draft.teacherLogin),
          const SizedBox(width: 32),
          _MiniMeta('SEMESTER', draft.semester),
          const SizedBox(width: 32),
          _MiniMeta('STUDENTS', '${draft.students.length}'),
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  final String label;
  final String value;
  const _MiniMeta(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTheme.label(9, color: AppTheme.inkMuted)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTheme.mono(13, weight: FontWeight.w600)),
      ],
    );
  }
}

// ── Toolbar ────────────────────────────────────────────────────────────────

class _EditorToolBar extends StatelessWidget {
  final CmtDraftDto draft;
  const _EditorToolBar({required this.draft});

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
          _PopulateFromSheetButton(draft: draft),
          const Spacer(),
          if (draft.lastEditedAt != null)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'Edited ${_fmtTime(draft.lastEditedAt!)}',
                style: AppTheme.label(10, color: AppTheme.inkMuted),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<CmtEditorBloc>().add(SaveDraftRequested()),
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('SAVE DRAFT'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _exportNow(context),
            icon: const Icon(Icons.arrow_outward, size: 16),
            label: const Text('EXPORT .CMT'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () =>
                context.read<CmtEditorBloc>().add(MarkCompleteRequested()),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('MARK COMPLETE'),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '${t.month}/${t.day} · $h:$m';
  }

  Future<void> _exportNow(BuildContext context) async {
    // Save the current edit state first so the exported .cmt reflects the
    // latest changes the user just typed.
    context.read<CmtEditorBloc>().add(SaveDraftRequested());

    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select export folder for ${draft.classCode}',
    );
    if (dir == null || !context.mounted) return;

    context.read<ExportBloc>().add(ExportOutputDirSelected(dir));
    context.read<ExportBloc>().add(ExportSingleRequested(draft));
  }
}

class _PopulateFromSheetButton extends StatelessWidget {
  final CmtDraftDto draft;
  const _PopulateFromSheetButton({required this.draft});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SheetSyncBloc, SheetSyncState>(
      builder: (ctx, state) {
        if (state is! SheetSyncLoaded) return const SizedBox.shrink();
        final match = state.matchResults.firstWhere(
          (r) => r.group.classCode == draft.classCode,
          orElse: () => GroupMatchResult.none(state.matchResults.first.group),
        );
        if (match.matchedRow == null) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.accent, width: 1),
            boxShadow: const [
              BoxShadow(
                  offset: Offset(3, 3), color: AppTheme.accent, spreadRadius: -1),
            ],
          ),
          child: FilledButton.icon(
            onPressed: () => ctx.read<CmtEditorBloc>().add(
                DraftPopulatedFromSheet(match, match.matchedRow!.contributions)),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.paper,
            ),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('POPULATE FROM SHEET'),
          ),
        );
      },
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────

class _EditorBody extends StatelessWidget {
  final CmtDraftDto draft;
  const _EditorBody({required this.draft});

  static double? _findPct(CmtDraftDto draft, String roll) {
    for (final c in draft.contributions) {
      if (rollsMatch(c.roll, roll)) return c.percentage;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionBlock(
                number: 'I',
                title: 'Thesis Titles',
                subtitle: 'Tên đề tài bằng tiếng Việt và tiếng Anh',
                children: [
                  _EditorField(
                      field: 'titleVN',
                      label: 'Tên đề tài (Tiếng Việt)',
                      value: draft.titleVN),
                  const SizedBox(height: 14),
                  _EditorField(
                      field: 'titleEN',
                      label: 'Thesis Title (English)',
                      value: draft.titleEN),
                ],
              ),
              _SectionBlock(
                number: 'II',
                title: 'Evaluation',
                subtitle: 'Nhận xét chi tiết · Phần 3.1 — 3.3',
                children: [
                  _EditorField(
                      field: 'content',
                      label: '3.1 · Content (Nội dung)',
                      value: draft.content,
                      multiline: true),
                  const SizedBox(height: 14),
                  _EditorField(
                      field: 'formComment',
                      label: '3.2 · Form (Hình thức)',
                      value: draft.formComment,
                      multiline: true),
                  const SizedBox(height: 14),
                  _EditorField(
                      field: 'attitude',
                      label: '3.3 · Attitude (Thái độ)',
                      value: draft.attitude,
                      multiline: true),
                ],
              ),
              _SectionBlock(
                number: 'III',
                title: 'Results & Conclusion',
                subtitle: 'Kết quả đạt được, hạn chế, kết luận · Phần 4.1 — 4.2',
                children: [
                  _EditorField(
                      field: 'achievement',
                      label: '4.1 · Achievement (Kết quả đạt được)',
                      value: draft.achievement,
                      multiline: true),
                  const SizedBox(height: 14),
                  _EditorField(
                      field: 'limitation',
                      label: '4.2 · Limitation (Hạn chế)',
                      value: draft.limitation,
                      multiline: true),
                  const SizedBox(height: 14),
                  _EditorField(
                      field: 'conclusion',
                      label: 'Conclusion (Kết luận)',
                      value: draft.conclusion,
                      multiline: true),
                ],
              ),
              _SectionBlock(
                number: 'IV',
                title: 'Defense Decisions',
                subtitle:
                    'Quyết định cho từng sinh viên · ${draft.students.length} students',
                children: [
                  for (final d in draft.decisions)
                    _DecisionRow(
                      decision: d,
                      contributionPct: _findPct(draft, d.roll),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Block — the oversized numbered chapter mark ────────────────────

class _SectionBlock extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _SectionBlock({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 56),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display number — oversized serif numeral
          SizedBox(
            width: 220,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: AppTheme.display(96,
                            weight: FontWeight.w300,
                            color: AppTheme.accent,
                            height: 0.9)
                        .copyWith(
                      fontFeatures: const [FontFeature.enable('lnum')],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(width: 40, height: 1, color: AppTheme.ink),
                  const SizedBox(height: 16),
                  Text(title,
                      style: AppTheme.display(22, weight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: AppTheme.body(12,
                          color: AppTheme.inkSoft, height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 64),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Editor Field ───────────────────────────────────────────────────────────

class _EditorField extends StatefulWidget {
  final String field;
  final String label;
  final String value;
  final bool multiline;

  const _EditorField({
    required this.field,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  State<_EditorField> createState() => _EditorFieldState();
}

class _EditorFieldState extends State<_EditorField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focus = FocusNode()
      ..addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void didUpdateWidget(_EditorField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text && !_focus.hasFocus) {
      _ctrl.text = widget.value;
    } else if (widget.value != old.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(
          color: _focused ? AppTheme.ink : AppTheme.rule,
          width: _focused ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _focused ? AppTheme.accent : AppTheme.inkMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(widget.label.toUpperCase(),
                    style: AppTheme.label(10,
                        color:
                            _focused ? AppTheme.ink : AppTheme.inkMuted)),
                const Spacer(),
                Text('${_ctrl.text.length} CHARS',
                    style: AppTheme.mono(9, color: AppTheme.inkMuted)),
              ],
            ),
          ),
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            maxLines: widget.multiline ? null : 1,
            minLines: widget.multiline ? 3 : 1,
            style: widget.multiline
                ? AppTheme.body(14, height: 1.6)
                : AppTheme.display(20, weight: FontWeight.w500, height: 1.3),
            decoration: const InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  EdgeInsets.fromLTRB(16, 4, 16, 16),
            ),
            onChanged: (v) {
              context
                  .read<CmtEditorBloc>()
                  .add(FieldUpdated(widget.field, v));
              setState(() {}); // refresh char count
            },
          ),
        ],
      ),
    );
  }
}

// ── Decision Row ───────────────────────────────────────────────────────────

class _DecisionRow extends StatelessWidget {
  final StudentDecisionDto decision;
  final double? contributionPct;
  const _DecisionRow({required this.decision, this.contributionPct});

  @override
  Widget build(BuildContext context) {
    final outcomeColor = switch (decision.outcome) {
      DefenseOutcome.agree => AppTheme.forest,
      DefenseOutcome.revisedForSecondDefense => AppTheme.ochre,
      DefenseOutcome.disagree => AppTheme.rust,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.rule),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: student identity + contribution
          SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      color: outcomeColor,
                    ),
                    const SizedBox(width: 10),
                    Text(decision.roll,
                        style:
                            AppTheme.mono(13, weight: FontWeight.w600)),
                    const Spacer(),
                    if (contributionPct != null) _ContribTag(pct: contributionPct!),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(decision.name,
                      style:
                          AppTheme.body(13, color: AppTheme.inkSoft)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Center: segmented decision
          SizedBox(
            width: 360,
            child: SegmentedButton<DefenseOutcome>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: DefenseOutcome.agree,
                  label: Text('AGREE'),
                  icon: Icon(Icons.check, size: 14),
                ),
                ButtonSegment(
                  value: DefenseOutcome.revisedForSecondDefense,
                  label: Text('REVISED'),
                  icon: Icon(Icons.refresh, size: 14),
                ),
                ButtonSegment(
                  value: DefenseOutcome.disagree,
                  label: Text('DISAGREE'),
                  icon: Icon(Icons.close, size: 14),
                ),
              ],
              selected: {decision.outcome},
              onSelectionChanged: (s) => context
                  .read<CmtEditorBloc>()
                  .add(DecisionUpdated(decision.roll, s.first)),
            ),
          ),
          const SizedBox(width: 16),
          // Right: note
          Expanded(child: _NoteField(roll: decision.roll, value: decision.note)),
        ],
      ),
    );
  }
}

class _ContribTag extends StatelessWidget {
  final double pct;
  const _ContribTag({required this.pct});

  @override
  Widget build(BuildContext context) {
    final formatted = pct == pct.roundToDouble()
        ? pct.toStringAsFixed(0)
        : pct.toStringAsFixed(1);
    // Color shifts from rust (low) → ochre (mid) → forest (full)
    final color = pct >= 95
        ? AppTheme.forest
        : pct >= 60
            ? AppTheme.ochre
            : AppTheme.rust;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatted,
              style: AppTheme.mono(12, weight: FontWeight.w700, color: color)),
          const SizedBox(width: 2),
          Text('%', style: AppTheme.mono(10, color: color)),
        ],
      ),
    );
  }
}

class _NoteField extends StatefulWidget {
  final String roll;
  final String value;
  const _NoteField({required this.roll, required this.value});

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(_NoteField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text && !_focus.hasFocus) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      style: AppTheme.body(13),
      decoration: InputDecoration(
        labelText: 'NOTE',
        labelStyle: AppTheme.label(9, color: AppTheme.inkMuted),
        hintText: 'optional remark',
        hintStyle: AppTheme.body(12, color: AppTheme.inkMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (v) =>
          context.read<CmtEditorBloc>().add(NoteUpdated(widget.roll, v)),
    );
  }
}

// ── Validation Dialog ──────────────────────────────────────────────────────

class _ExportMissingFieldsDialog extends StatelessWidget {
  final String classCode;
  final List<String> missing;
  const _ExportMissingFieldsDialog(
      {required this.classCode, required this.missing});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Kicker(
              text: 'Export Blocked', number: '§', color: AppTheme.rust),
          const Spacer(),
          Text('${missing.length}',
              style: AppTheme.display(40,
                  weight: FontWeight.w600, color: AppTheme.rust)),
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

class _ValidationDialog extends StatelessWidget {
  final List<String> errors;
  const _ValidationDialog({required this.errors});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Kicker(text: 'Validation', number: '§', color: AppTheme.rust),
          const Spacer(),
          Text('${errors.length}',
              style: AppTheme.display(40,
                  weight: FontWeight.w600, color: AppTheme.rust)),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Required fields are empty.',
                style: AppTheme.body(14, color: AppTheme.inkSoft)),
            const SizedBox(height: 20),
            for (final e in errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 4,
                        height: 14,
                        margin: const EdgeInsets.only(top: 4, right: 12),
                        color: AppTheme.rust),
                    Expanded(child: Text(e, style: AppTheme.body(13))),
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
