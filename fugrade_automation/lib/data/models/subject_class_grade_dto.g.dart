// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_class_grade_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectClassGradeDto _$SubjectClassGradeDtoFromJson(
  Map<String, dynamic> json,
) => SubjectClassGradeDto(
  subject: json['subject'] as String,
  classCode: json['classCode'] as String,
  students: (json['students'] as List<dynamic>)
      .map((e) => StudentDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  gradingComponents:
      (json['gradingComponents'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubjectClassGradeDtoToJson(
  SubjectClassGradeDto instance,
) => <String, dynamic>{
  'subject': instance.subject,
  'classCode': instance.classCode,
  'students': instance.students,
  'gradingComponents': instance.gradingComponents,
};
