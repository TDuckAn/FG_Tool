import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fugrade_automation/core/theme/app_theme.dart';
import 'package:fugrade_automation/data/datasources/fg_parser_datasource.dart';
import 'package:fugrade_automation/data/models/cmt_draft_dto.dart';
import 'package:fugrade_automation/data/models/student_decision_dto.dart';
import 'package:fugrade_automation/data/models/student_dto.dart';
import 'package:fugrade_automation/presentation/blocs/fg_loader/fg_loader_bloc.dart';
import 'cmt_editor_screen.dart';
import 'group_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: BlocListener<FgLoaderBloc, FgLoaderState>(
          listener: (context, state) {
            if (state is FgLoaderLoaded) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupListScreen(
                    grade: state.grade,
                    fgFilePath: state.filePath,
                  ),
                ),
              );
            }
            if (state is FgLoaderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.rust,
                ),
              );
            }
          },
          child: Stack(
            children: [
              _CornerStamp(),
              Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 64),
                          const Kicker(
                            text: 'FU Capstone · Grading Pipeline',
                            number: 'v1.0',
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'FuGrade Automation',
                            style:
                                AppTheme.display(
                                  72,
                                  weight: FontWeight.w600,
                                  height: 0.95,
                                ).copyWith(
                                  fontFeatures: const [
                                    FontFeature.enable('ss01'),
                                  ],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Text(
                              'Automates capstone comment file creation for FU Grading Editor 1.1.',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(
                                15,
                                color: AppTheme.inkSoft,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 56),
                          _DropZone(),
                          const SizedBox(height: 28),
                          const _OrDivider(),
                          const SizedBox(height: 28),
                          _OpenCmtButton(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerStamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 32,
      left: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '§',
            style: AppTheme.display(
              40,
              weight: FontWeight.w500,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 2),
          Container(width: 32, height: 1, color: AppTheme.ink),
        ],
      ),
    );
  }
}

class _DropZone extends StatefulWidget {
  @override
  State<_DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['fg'],
      dialogTitle: 'Select .fg file',
    );
    if (result != null && result.files.single.path != null && mounted) {
      context.read<FgLoaderBloc>().add(
        FgFileSelected(result.files.single.path!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FgLoaderBloc, FgLoaderState>(
      builder: (context, state) {
        final loading = state is FgLoaderLoading;

        return MouseRegion(
          cursor: loading ? SystemMouseCursors.wait : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: loading ? null : _pickFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 480,
              height: 220,
              decoration: BoxDecoration(
                color: _hovering ? AppTheme.ink : AppTheme.card,
                border: Border.all(
                  color: _hovering ? AppTheme.ink : AppTheme.ink,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(_hovering ? 8 : 6, _hovering ? 8 : 6),
                    color: AppTheme.ink,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: loading ? _loadingContent() : _idleContent(_hovering),
            ),
          ),
        );
      },
    );
  }

  Widget _loadingContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'PARSING BINARY',
            style: AppTheme.label(11, color: AppTheme.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _idleContent(bool hovering) {
    final fg = hovering ? AppTheme.paper : AppTheme.ink;
    final muted = hovering ? AppTheme.paperDeep : AppTheme.inkSoft;
    return Stack(
      children: [
        Positioned(
          top: 12,
          left: 16,
          child: Text(
            '01',
            style: AppTheme.mono(10, color: muted, weight: FontWeight.w600),
          ),
        ),
        Positioned(
          top: 12,
          right: 16,
          child: Text(
            '.FG',
            style: AppTheme.mono(10, color: muted, weight: FontWeight.w600),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _pulseCtrl.drive(Tween(begin: 0.65, end: 1.0)),
                child: Icon(Icons.north_east, size: 28, color: fg),
              ),
              const SizedBox(height: 14),
              Text(
                hovering ? 'Release to open' : 'Drop .fg file here',
                style: AppTheme.display(22, weight: FontWeight.w500, color: fg),
              ),
              const SizedBox(height: 4),
              Text(
                'or click to browse',
                style: AppTheme.body(12, color: muted),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FuGradeLib.TeacherGrade',
                style: AppTheme.mono(10, color: muted),
              ),
              Text(
                '.NET BinaryFormatter',
                style: AppTheme.mono(10, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppTheme.rule)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'OR',
              style: AppTheme.label(10, color: AppTheme.inkMuted),
            ),
          ),
          const Expanded(child: Divider(color: AppTheme.rule)),
        ],
      ),
    );
  }
}

class _OpenCmtButton extends StatefulWidget {
  @override
  State<_OpenCmtButton> createState() => _OpenCmtButtonState();
}

class _OpenCmtButtonState extends State<_OpenCmtButton> {
  bool _loading = false;

  Future<void> _open() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['cmt'],
      dialogTitle: 'Select .cmt file to edit',
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final parser = context.read<FgParserDatasource>();
      final json = await parser.readCmtFile(path);

      final rawStudents = (json['students'] as List);
      final decisions = rawStudents.map((s) {
        final outcomeStr = s['outcome'] as String? ?? 'agree';
        final outcome = switch (outcomeStr) {
          'revised' => DefenseOutcome.revisedForSecondDefense,
          'disagree' => DefenseOutcome.disagree,
          _ => DefenseOutcome.agree,
        };
        return StudentDecisionDto(
          roll: s['roll'] as String? ?? '',
          name: s['name'] as String? ?? '',
          outcome: outcome,
          note: s['note'] as String? ?? '',
        );
      }).toList();

      final studentDtos = rawStudents
          .map(
            (s) => StudentDto(
              roll: s['roll'] as String? ?? '',
              name: s['name'] as String? ?? '',
            ),
          )
          .toList();

      final draft = CmtDraftDto(
        teacherLogin: json['teacher'] as String? ?? '',
        semester: json['semester'] as String? ?? '',
        subjectCode: json['subjectCode'] as String? ?? '',
        classCode: json['className'] as String? ?? '',
        students: studentDtos,
        fgVersion: '1.1',
        titleVN: json['titleVN'] as String? ?? '',
        titleEN: json['titleEN'] as String? ?? '',
        content: json['content'] as String? ?? '',
        formComment: json['form'] as String? ?? '',
        attitude: json['attitude'] as String? ?? '',
        achievement: json['achievement'] as String? ?? '',
        limitation: json['limitation'] as String? ?? '',
        decisions: decisions,
        status: DraftStatus.draft,
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CmtEditorScreen(draft: draft)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open .cmt: $e'),
            backgroundColor: AppTheme.rust,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: OutlinedButton(
        onPressed: _loading ? null : _open,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          side: const BorderSide(color: AppTheme.rule, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '02',
                  style: AppTheme.mono(
                    11,
                    color: AppTheme.inkMuted,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 20, height: 1, color: AppTheme.rule),
                const SizedBox(width: 16),
                Text(
                  _loading ? 'Opening…' : 'Edit existing .cmt file',
                  style: AppTheme.body(
                    14,
                    weight: FontWeight.w500,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
            _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.4,
                      color: AppTheme.ink,
                    ),
                  )
                : const Icon(Icons.arrow_forward, size: 16),
          ],
        ),
      ),
    );
  }
}
