import 'package:json_annotation/json_annotation.dart';
import 'subject_class_grade_dto.dart';

part 'teacher_grade_dto.g.dart';

@JsonSerializable()
class TeacherGradeDto {
  final String version;
  final String semester;
  final String login;
  final List<SubjectClassGradeDto> groups;

  const TeacherGradeDto({
    required this.version,
    required this.semester,
    required this.login,
    required this.groups,
  });

  List<SubjectClassGradeDto> get capstoneGroups =>
      groups.where((g) => g.isCapstone).toList();

  factory TeacherGradeDto.fromJson(Map<String, dynamic> json) =>
      _$TeacherGradeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherGradeDtoToJson(this);
}
