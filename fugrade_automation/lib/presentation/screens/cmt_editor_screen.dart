import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fugrade_automation/core/theme/app_theme.dart';
import 'package:fugrade_automation/core/utils/app_logger.dart';
import 'package:fugrade_automation/core/utils/roll_utils.dart';
import 'package:fugrade_automation/data/datasources/fg_parser_datasource.dart';
import 'package:fugrade_automation/data/datasources/local_storage_datasource.dart';
import 'package:fugrade_automation/data/datasources/sheets_api_datasource.dart';
import 'package:fugrade_automation/data/models/cmt_draft_dto.dart';
import 'package:fugrade_automation/data/models/group_match_result.dart';
import 'package:fugrade_automation/data/models/member_contribution_dto.dart';
import 'package:fugrade_automation/data/models/student_decision_dto.dart';
import 'package:fugrade_automation/presentation/blocs/cmt_editor/cmt_editor_bloc.dart';
import 'package:fugrade_automation/presentation/blocs/export/export_bloc.dart';
import 'package:fugrade_automation/presentation/blocs/sheet_sync/sheet_sync_bloc.dart';

class CmtEditorScreen extends StatefulWidget {
  final CmtDraftDto draft;
  final String? fgFilePath;

  const CmtEditorScreen({super.key, required this.draft, this.fgFilePath});

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
              final saved = state;
              final localMsg = saved.draft.status == DraftStatus.complete
                  ? 'Marked complete · ${saved.draft.classCode}'
                  : 'Draft saved · ${saved.draft.classCode}';

              if (saved.warningMessage != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('$localMsg  ·  ⚠ ${saved.warningMessage}'),
                      backgroundColor: AppTheme.ochre,
                      duration: const Duration(seconds: 5),
                    ),
                  );
              } else {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('$localMsg  ·  FINAL synced ✓')),
                  );
              }

              if (saved.draft.status == DraftStatus.complete) {
                Navigator.of(context).pop();
              }
            }
            if (state is CmtEditorActionFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.rust,
                ),
              );
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
            curr is CmtEditorEditing ||
            curr is CmtEditorSaved ||
            curr is CmtEditorIdle,
        builder: (context, state) {
          final draft = switch (state) {
            CmtEditorEditing s => s.draft,
            CmtEditorSaved s => s.draft,
            _ => widget.draft,
          };

          return Scaffold(
            body: PaperBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    _EditorMasthead(draft: draft),
                    _EditorToolBar(draft: draft, fgFilePath: widget.fgFilePath),
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

// â”€â”€ Masthead â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                number: '§ ${draft.subjectCode}',
              ),
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
        Text(value, style: AppTheme.mono(13, weight: FontWeight.w600)),
      ],
    );
  }
}

// â”€â”€ Toolbar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EditorToolBar extends StatelessWidget {
  final CmtDraftDto draft;
  final String? fgFilePath;
  const _EditorToolBar({required this.draft, this.fgFilePath});

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
            onPressed: () => _openContributions(context),
            icon: const Icon(Icons.people_outline, size: 16),
            label: const Text('CONTRIBUTIONS'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _openGrading(context),
            icon: const Icon(Icons.grade_outlined, size: 16),
            label: const Text('GRADING'),
          ),
          const SizedBox(width: 12),
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

  Future<void> _openContributions(BuildContext context) async {
    final updated = await showDialog<List<MemberContributionDto>>(
      context: context,
      builder: (_) => _ContributionInputDialog(existing: draft.contributions),
    );
    if (updated == null || !context.mounted) return;
    context.read<CmtEditorBloc>().add(ContributionsManuallyUpdated(updated));
  }

  Future<void> _openGrading(BuildContext context) async {
    final updatedGrades = await showDialog<Map<String, Map<String, double>>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GradingDialog(draft: draft),
    );

    if (updatedGrades == null || !context.mounted) return;
    final editorBloc = context.read<CmtEditorBloc>();
    final storage = context.read<LocalStorageDatasource>();
    final parser = context.read<FgParserDatasource>();
    final messenger = ScaffoldMessenger.of(context);

    editorBloc.add(GradingUpdated(updatedGrades));

    final updatedDraft = draft.copyWith(
      grades: updatedGrades,
      status: DraftStatus.draft,
      lastEditedAt: DateTime.now(),
    );

    try {
      await storage.saveDraft(updatedDraft);
      if (fgFilePath != null) {
        await parser.writeFgGrades(
          inputPath: fgFilePath!,
          classCode: draft.classCode,
          grades: updatedGrades,
        );
      }
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            fgFilePath == null
                ? 'Grading saved locally.'
                : 'Grading saved locally and written to .fg.',
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to persist grading',
        tag: 'CmtEditor',
        error: e,
        stack: st,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Grading saved in editor, but .fg write failed: $e'),
          backgroundColor: AppTheme.rust,
        ),
      );
    }
  }

  static String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '${t.month}/${t.day} Â· $h:$m';
  }

  Future<void> _exportNow(BuildContext context) async {
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

class _GradingDialog extends StatefulWidget {
  final CmtDraftDto draft;
  const _GradingDialog({required this.draft});

  @override
  State<_GradingDialog> createState() => _GradingDialogState();
}

class _GradingDialogState extends State<_GradingDialog> {
  final Map<String, TextEditingController> _controllers = {};
  late List<String> _components;
  late Set<String> _selectedComponents;
  bool _dirty = false;
  late ScrollController _verticalScrollController;
  late ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _components = _resolveComponents(widget.draft);
    _selectedComponents = widget.draft.grades.values
        .expand((row) => row.keys)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (_selectedComponents.isEmpty && _components.isNotEmpty) {
      _selectedComponents = {_components.first};
    }
    for (final student in widget.draft.students) {
      for (final component in _components) {
        final score = widget.draft.grades[student.roll]?[component];
        _controllers['${student.roll}|$component'] = TextEditingController(
          text: score == null ? '' : _formatScore(score),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedComponents = _components
        .where((component) => _selectedComponents.contains(component))
        .toList();

    return AlertDialog(
      title: const Row(
        children: [
          Kicker(text: 'Grading', number: 'Â§'),
          Spacer(),
        ],
      ),
      content: SizedBox(
        width: 1120,
        height: 520,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.rule),
                  color: AppTheme.paper,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Text(
                        'GRADING COMPONENTS (${_components.length})',
                        style: AppTheme.mono(12, weight: FontWeight.w700),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _components.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No grading components defined for this class.',
                                style: AppTheme.body(
                                  13,
                                  color: AppTheme.inkSoft,
                                  height: 1.4,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_components.length} items',
                                        style: AppTheme.body(
                                          12,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedComponents =
                                                    _components
                                                        .map((e) => e.trim())
                                                        .where(
                                                          (e) => e.isNotEmpty,
                                                        )
                                                        .toSet();
                                                _dirty = true;
                                              });
                                            },
                                            child: const Text('Select all'),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedComponents.clear();
                                                _dirty = true;
                                              });
                                            },
                                            child: const Text('Clear'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _components.length,
                                    itemBuilder: (context, index) {
                                      final component = _components[index];
                                      final selected = _selectedComponents
                                          .contains(component);

                                      return CheckboxListTile(
                                        value: selected,
                                        dense: true,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        title: Text(
                                          component,
                                          style: AppTheme.body(13),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedComponents.add(
                                                component,
                                              );
                                            } else {
                                              _selectedComponents.remove(
                                                component,
                                              );
                                            }
                                            _dirty = true;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: selectedComponents.isEmpty
                  ? Center(
                      child: Text(
                        _components.isEmpty
                            ? 'No grading components defined for this class.'
                            : 'Choose at least one grading component.',
                        style: AppTheme.body(14, color: AppTheme.inkSoft),
                      ),
                    )
                  : Scrollbar(
                      controller: _verticalScrollController,
                      thumbVisibility: true,
                      thickness: 12,
                      radius: const Radius.circular(6),
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        child: RawScrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          thickness: 12,
                          radius: const Radius.circular(6),
                          thumbColor: AppTheme.ink.withOpacity(0.6),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _horizontalScrollController,
                            child: DataTable(
                              columns: [
                                const DataColumn(label: Text('ROLL')),
                                const DataColumn(label: Text('NAME')),
                                for (final component in selectedComponents)
                                  DataColumn(
                                    label: Text(component.toUpperCase()),
                                  ),
                              ],
                              rows: widget.draft.students.map((student) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        student.roll,
                                        style: AppTheme.mono(12),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        student.name,
                                        style: AppTheme.body(12),
                                      ),
                                    ),
                                    for (final component in selectedComponents)
                                      DataCell(
                                        SizedBox(
                                          width: 96,
                                          child: TextField(
                                            controller:
                                                _controllers['${student.roll}|$component'],
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              hintText: '0-10',
                                            ),
                                            onChanged: (_) => _dirty = true,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('CANCEL')),
        FilledButton(
          onPressed: _components.isEmpty ? null : _save,
          child: const Text('SAVE'),
        ),
      ],
    );
  }

  Future<void> _cancel() async {
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard grading changes?'),
        content: const Text('Unsaved grading values will be discarded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('KEEP EDITING'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _save() {
    if (_selectedComponents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose at least one grading component.'),
          backgroundColor: AppTheme.rust,
        ),
      );
      return;
    }

    final grades = <String, Map<String, double>>{};
    final selectedComponents = _components
        .where((component) => _selectedComponents.contains(component))
        .toList();

    for (final student in widget.draft.students) {
      final row = <String, double>{};
      for (final component in selectedComponents) {
        final raw =
            _controllers['${student.roll}|$component']?.text.trim() ?? '';
        if (raw.isEmpty) continue;

        final score = double.tryParse(raw.replaceAll(',', '.'));
        if (score == null || score < 0 || score > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invalid score for ${student.roll} / $component. Use 0-10.',
              ),
              backgroundColor: AppTheme.rust,
            ),
          );
          return;
        }
        row[component] = score;
      }
      if (row.isNotEmpty) grades[student.roll] = row;
    }

    Navigator.pop(context, grades);
  }

  List<String> _resolveComponents(CmtDraftDto draft) {
    final components = <String>[
      ...draft.gradingComponents,
      for (final row in draft.grades.values) ...row.keys,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    return components;
  }

  String _formatScore(double score) => score == score.roundToDouble()
      ? score.toStringAsFixed(0)
      : score.toString();
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

        return Row(
          children: [
            if (match.matchedRow != null) ...[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.accent, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(3, 3),
                      color: AppTheme.accent,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () => ctx.read<CmtEditorBloc>().add(
                    DraftPopulatedFromSheet(
                      match,
                      match.matchedRow!.contributions,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.paper,
                  ),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('POPULATE FROM SHEET'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            OutlinedButton.icon(
              onPressed: () => ctx.read<CmtEditorBloc>().add(
                DraftPopulatedFromFinalRequested(),
              ),
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: const Text('POPULATE FROM FINAL'),
            ),
          ],
        );
      },
    );
  }
}

class _ContributionInputDialog extends StatefulWidget {
  final List<MemberContributionDto> existing;
  const _ContributionInputDialog({required this.existing});

  @override
  State<_ContributionInputDialog> createState() =>
      _ContributionInputDialogState();
}

class _ContributionInputDialogState extends State<_ContributionInputDialog> {
  late final TextEditingController _ctrl;
  List<MemberContributionDto> _parsed = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    final text = widget.existing
        .map((c) => '${c.roll} - ${_fmtPct(c.percentage)}')
        .join('\n');
    _ctrl = TextEditingController(text: text);
    if (text.isNotEmpty) _parse(text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _parse(String text) {
    String? err;
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final match = RegExp(
        r'^([A-Za-z]{1,3}\d{5,})\s*-\s*(\d+(?:[.,]\d+)?)$',
      ).firstMatch(line);
      if (match == null) {
        err = 'Cannot parse line: "$line". Use format "SE160015 - 50".';
        break;
      }
      final pct = double.tryParse(match.group(2)!.replaceAll(',', '.'));
      if (pct == null || pct < 0 || pct > 100) {
        err = 'Invalid percentage on line: "$line".';
        break;
      }
    }

    final parsed = err == null
        ? SheetsApiDatasource.parseContributionParagraph(text)
        : <MemberContributionDto>[];

    setState(() {
      _parsed = parsed;
      _error = err;
    });
  }

  String _fmtPct(double pct) =>
      pct == pct.roundToDouble() ? pct.toStringAsFixed(0) : pct.toString();

  @override
  Widget build(BuildContext context) {
    final total = _parsed.fold<double>(0, (sum, c) => sum + c.percentage);
    final totalOk = _parsed.isNotEmpty && (total - 100).abs() < 0.01;

    return AlertDialog(
      title: const Text('Member Contributions'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter one member per line: roll number - contribution %',
              style: AppTheme.body(13, color: AppTheme.inkSoft),
            ),
            const SizedBox(height: 4),
            Text(
              'e.g.  SE160015 - 50',
              style: AppTheme.mono(12, color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 8,
              style: AppTheme.mono(13),
              decoration: InputDecoration(
                hintText: 'SE160015 - 50\nSE160020 - 30\nSE160030 - 20',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onChanged: _parse,
            ),
            if (_parsed.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final c in _parsed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(c.roll, style: AppTheme.mono(12)),
                      const Spacer(),
                      Text(
                        '${_fmtPct(c.percentage)} %',
                        style: AppTheme.mono(
                          12,
                          weight: FontWeight.w600,
                          color: totalOk ? AppTheme.accent : AppTheme.rust,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Total: ${_fmtPct(total)} % ${totalOk ? 'OK' : 'should be 100'}',
                style: AppTheme.label(
                  11,
                  color: totalOk ? AppTheme.accent : AppTheme.rust,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: (_error == null && _parsed.isNotEmpty)
              ? () => Navigator.pop(context, _parsed)
              : null,
          child: const Text('APPLY'),
        ),
      ],
    );
  }
}

// â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                subtitle: 'Thesis titles in Vietnamese and English',
                children: [
                  _EditorField(
                    field: 'titleVN',
                    label: 'Thesis Title (Vietnamese)',
                    value: draft.titleVN,
                  ),
                  const SizedBox(height: 14),
                  _EditorField(
                    field: 'titleEN',
                    label: 'Thesis Title (English)',
                    value: draft.titleEN,
                  ),
                ],
              ),
              _SectionBlock(
                number: 'II',
                title: 'Evaluation',
                subtitle: 'Detailed comments · Sections 3.1 — 3.3',
                children: [
                  _EditorField(
                    field: 'content',
                    label: '3.1 · Content',
                    value: draft.content,
                    multiline: true,
                  ),
                  const SizedBox(height: 14),
                  _EditorField(
                    field: 'formComment',
                    label: '3.2 · Form',
                    value: draft.formComment,
                    multiline: true,
                  ),
                  const SizedBox(height: 14),
                  _EditorField(
                    field: 'attitude',
                    label: '3.3 · Attitude',
                    value: draft.attitude,
                    multiline: true,
                  ),
                ],
              ),
              _SectionBlock(
                number: 'III',
                title: 'Results & Conclusion',
                subtitle:
                    'Results achieved, limitations, conclusion · Sections 4.1 — 4.2',
                children: [
                  _EditorField(
                    field: 'achievement',
                    label: '4.1 · Achievement',
                    value: draft.achievement,
                    multiline: true,
                  ),
                  const SizedBox(height: 14),
                  _EditorField(
                    field: 'limitation',
                    label: '4.2 · Limitation',
                    value: draft.limitation,
                    multiline: true,
                  ),
                  const SizedBox(height: 14),
                  _EditorField(
                    field: 'conclusion',
                    label: 'Conclusion',
                    value: draft.conclusion,
                    multiline: true,
                  ),
                ],
              ),
              _SectionBlock(
                number: 'IV',
                title: 'Defense Decisions',
                subtitle:
                    'Decisions for Each Student · ${draft.students.length} students',
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

// â”€â”€ Section Block â€” the oversized numbered chapter mark â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          // Display number â€” oversized serif numeral
          SizedBox(
            width: 220,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style:
                        AppTheme.display(
                          96,
                          weight: FontWeight.w300,
                          color: AppTheme.accent,
                          height: 0.9,
                        ).copyWith(
                          fontFeatures: const [FontFeature.enable('lnum')],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(width: 40, height: 1, color: AppTheme.ink),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: AppTheme.display(22, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTheme.body(
                      12,
                      color: AppTheme.inkSoft,
                      height: 1.5,
                    ),
                  ),
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

// â”€â”€ Editor Field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                Text(
                  widget.label.toUpperCase(),
                  style: AppTheme.label(
                    10,
                    color: _focused ? AppTheme.ink : AppTheme.inkMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_ctrl.text.length} CHARS',
                  style: AppTheme.mono(9, color: AppTheme.inkMuted),
                ),
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
              contentPadding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            ),
            onChanged: (v) {
              context.read<CmtEditorBloc>().add(FieldUpdated(widget.field, v));
              setState(() {}); // refresh char count
            },
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Decision Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                    Container(width: 4, height: 16, color: outcomeColor),
                    const SizedBox(width: 10),
                    Text(
                      decision.roll,
                      style: AppTheme.mono(13, weight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (contributionPct != null)
                      _ContribTag(pct: contributionPct!),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    decision.name,
                    style: AppTheme.body(13, color: AppTheme.inkSoft),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Center + Right: decision + note stacked
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
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
                const SizedBox(height: 12),
                _NoteField(
                  roll: decision.roll,
                  value: decision.note,
                  minLines: 3,
                  maxLines: 4,
                ),
              ],
            ),
          ),
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
    // Color shifts from rust (low) â†’ ochre (mid) â†’ forest (full)
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
          Text(
            formatted,
            style: AppTheme.mono(12, weight: FontWeight.w700, color: color),
          ),
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
  final int minLines;
  final int maxLines;
  const _NoteField({
    required this.roll,
    required this.value,
    this.minLines = 2,
    this.maxLines = 3,
  });

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
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: AppTheme.body(13),
      decoration: InputDecoration(
        labelText: 'NOTE',
        labelStyle: AppTheme.label(9, color: AppTheme.inkMuted),
        hintText: 'optional remark',
        hintStyle: AppTheme.body(12, color: AppTheme.inkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (v) =>
          context.read<CmtEditorBloc>().add(NoteUpdated(widget.roll, v)),
    );
  }
}

// â”€â”€ Validation Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
            number: 'Â§',
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

class _ValidationDialog extends StatelessWidget {
  final List<String> errors;
  const _ValidationDialog({required this.errors});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Kicker(text: 'Validation', number: 'Â§', color: AppTheme.rust),
          const Spacer(),
          Text(
            '${errors.length}',
            style: AppTheme.display(
              40,
              weight: FontWeight.w600,
              color: AppTheme.rust,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Required fields are empty.',
              style: AppTheme.body(14, color: AppTheme.inkSoft),
            ),
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
                      color: AppTheme.rust,
                    ),
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
