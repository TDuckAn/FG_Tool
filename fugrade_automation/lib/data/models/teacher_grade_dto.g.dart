// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_grade_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherGradeDto _$TeacherGradeDtoFromJson(Map<String, dynamic> json) =>
    TeacherGradeDto(
      version: json['version'] as String,
      semester: json['semester'] as String,
      login: json['login'] as String,
      groups: (json['groups'] as List<dynamic>)
          .map((e) => SubjectClassGradeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TeacherGradeDtoToJson(TeacherGradeDto instance) =>
    <String, dynamic>{
      'version': instance.version,
      'semester': instance.semester,
      'login': instance.login,
      'groups': instance.groups,
    };
