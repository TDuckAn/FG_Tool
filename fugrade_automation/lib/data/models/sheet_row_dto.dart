import 'package:json_annotation/json_annotation.dart';
import 'member_contribution_dto.dart';
import 'student_decision_dto.dart';
import 'cmt_draft_dto.dart';

part 'sheet_row_dto.g.dart';

@JsonSerializable()
class SheetRowDto {
  // Matching keys (all 4 required — spec §9.3)
  final String semester;
  final String subjectCode;
  final String classCode;
  final String teacher;

  // Thesis titles
  final String titleVN;
  final String titleEN;

  // Comment sections (all required in Google Form — spec §10.1)
  final String content;
  final String form;
  final String attitude;
  final String achievement;
  final String limitation;
  final String conclusion;

  // Member contributions
  final List<MemberContributionDto> contributions;

  // FINAL sheet persisted editor state.
  final DraftStatus? status;
  final List<StudentDecisionDto> decisions;
  final Map<String, Map<String, double>> grades;
  final List<String> gradingComponents;

  // Timestamp from Google Form submission (for duplicate resolution)
  final String? timestamp;

  const SheetRowDto({
    required this.semester,
    required this.subjectCode,
    required this.classCode,
    required this.teacher,
    required this.titleVN,
    required this.titleEN,
    required this.content,
    required this.form,
    required this.attitude,
    required this.achievement,
    required this.limitation,
    required this.conclusion,
    required this.contributions,
    this.status,
    this.decisions = const [],
    this.grades = const {},
    this.gradingComponents = const [],
    this.timestamp,
  });

  factory SheetRowDto.fromJson(Map<String, dynamic> json) =>
      _$SheetRowDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SheetRowDtoToJson(this);
}
