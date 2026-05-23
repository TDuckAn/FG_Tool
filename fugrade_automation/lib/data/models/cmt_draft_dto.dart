import 'package:json_annotation/json_annotation.dart';
import 'student_dto.dart';
import 'student_decision_dto.dart';
import 'member_contribution_dto.dart';
import 'group_match_result.dart';

part 'cmt_draft_dto.g.dart';

enum DraftStatus { notStarted, draft, complete }

@JsonSerializable()
class CmtDraftDto {
  // Identity — from .fg
  final String teacherLogin;
  final String semester;
  final String subjectCode;
  final String classCode;
  final List<StudentDto> students;
  final String fgVersion;

  // Text fields — from GSheet, editable by teacher
  final String titleVN;
  final String titleEN;
  final String content;
  final String formComment;
  final String attitude;
  final String achievement;
  final String limitation;
  final String conclusion;

  // Section 4.3 — teacher fills in app
  final List<StudentDecisionDto> decisions;

  // Per-student contribution percentages (from Google Sheet)
  final List<MemberContributionDto> contributions;

  // Per-student grading data entered by teacher.
  final Map<String, Map<String, double>> grades;

  // Grading component names shown as columns in the grading panel.
  final List<String> gradingComponents;

  // App state
  final DraftStatus status;
  final MatchStatus matchStatus;
  final DateTime? lastEditedAt;
  final DateTime? exportedAt;

  const CmtDraftDto({
    required this.teacherLogin,
    required this.semester,
    required this.subjectCode,
    required this.classCode,
    required this.students,
    required this.fgVersion,
    this.titleVN = '',
    this.titleEN = '',
    this.content = '',
    this.formComment = '',
    this.attitude = '',
    this.achievement = '',
    this.limitation = '',
    this.conclusion = '',
    required this.decisions,
    this.contributions = const [],
    this.grades = const {},
    this.gradingComponents = const [],
    this.status = DraftStatus.notStarted,
    this.matchStatus = MatchStatus.none,
    this.lastEditedAt,
    this.exportedAt,
  });

  CmtDraftDto copyWith({
    String? titleVN,
    String? titleEN,
    String? content,
    String? formComment,
    String? attitude,
    String? achievement,
    String? limitation,
    String? conclusion,
    List<StudentDecisionDto>? decisions,
    List<MemberContributionDto>? contributions,
    Map<String, Map<String, double>>? grades,
    List<String>? gradingComponents,
    DraftStatus? status,
    MatchStatus? matchStatus,
    DateTime? lastEditedAt,
    DateTime? exportedAt,
  }) =>
      CmtDraftDto(
        teacherLogin: teacherLogin,
        semester: semester,
        subjectCode: subjectCode,
        classCode: classCode,
        students: students,
        fgVersion: fgVersion,
        titleVN: titleVN ?? this.titleVN,
        titleEN: titleEN ?? this.titleEN,
        content: content ?? this.content,
        formComment: formComment ?? this.formComment,
        attitude: attitude ?? this.attitude,
        achievement: achievement ?? this.achievement,
        limitation: limitation ?? this.limitation,
        conclusion: conclusion ?? this.conclusion,
        decisions: decisions ?? this.decisions,
        contributions: contributions ?? this.contributions,
        grades: grades ?? this.grades,
        gradingComponents: gradingComponents ?? this.gradingComponents,
        status: status ?? this.status,
        matchStatus: matchStatus ?? this.matchStatus,
        lastEditedAt: lastEditedAt ?? this.lastEditedAt,
        exportedAt: exportedAt ?? this.exportedAt,
      );

  factory CmtDraftDto.fromJson(Map<String, dynamic> json) =>
      _$CmtDraftDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CmtDraftDtoToJson(this);

  /// Returns the list of required-but-empty fields for this draft.
  /// Used as a pre-flight check before writing a `.cmt` file.
  /// Empty list means the draft is valid for export.
  List<String> validateForExport() {
    final issues = <String>[];
    if (titleVN.trim().isEmpty) issues.add('TitleVN — Tên đề tài (Tiếng Việt)');
    if (titleEN.trim().isEmpty) issues.add('TitleEN — Thesis title (English)');
    if (content.trim().isEmpty) issues.add('3.1 Content — Nội dung');
    if (formComment.trim().isEmpty) issues.add('3.2 Form — Hình thức');
    if (attitude.trim().isEmpty) issues.add('3.3 Attitude — Thái độ');
    if (achievement.trim().isEmpty) issues.add('4.1 Achievement — Kết quả đạt được');
    if (limitation.trim().isEmpty) issues.add('4.2 Limitation — Hạn chế');
    if (conclusion.trim().isEmpty) issues.add('Conclusion — Kết luận');
    return issues;
  }
}
