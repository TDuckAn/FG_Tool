import 'package:json_annotation/json_annotation.dart';
import 'package:fugrade_automation/core/constants/capstone_subjects.dart';
import 'student_dto.dart';

part 'subject_class_grade_dto.g.dart';

@JsonSerializable()
class SubjectClassGradeDto {
  final String subject;
  final String classCode;
  final List<StudentDto> students;
  final List<String> gradingComponents;

  const SubjectClassGradeDto({
    required this.subject,
    required this.classCode,
    required this.students,
    this.gradingComponents = const [],
  });

  bool get isCapstone => isCapstoneSubject(subject);

  factory SubjectClassGradeDto.fromJson(Map<String, dynamic> json) =>
      _$SubjectClassGradeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SubjectClassGradeDtoToJson(this);
}
