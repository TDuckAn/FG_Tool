// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sheet_row_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SheetRowDto _$SheetRowDtoFromJson(Map<String, dynamic> json) => SheetRowDto(
  semester: json['semester'] as String,
  subjectCode: json['subjectCode'] as String,
  classCode: json['classCode'] as String,
  teacher: json['teacher'] as String,
  titleVN: json['titleVN'] as String,
  titleEN: json['titleEN'] as String,
  content: json['content'] as String,
  form: json['form'] as String,
  attitude: json['attitude'] as String,
  achievement: json['achievement'] as String,
  limitation: json['limitation'] as String,
  conclusion: json['conclusion'] as String,
  contributions: (json['contributions'] as List<dynamic>)
      .map((e) => MemberContributionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: $enumDecodeNullable(_$DraftStatusEnumMap, json['status']),
  decisions:
      (json['decisions'] as List<dynamic>?)
          ?.map((e) => StudentDecisionDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  grades:
      (json['grades'] as Map<String, dynamic>?)?.map(
        (studentId, scores) => MapEntry(
          studentId,
          (scores as Map<String, dynamic>).map(
            (component, score) => MapEntry(component, (score as num).toDouble()),
          ),
        ),
      ) ??
      const {},
  gradingComponents:
      (json['gradingComponents'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  timestamp: json['timestamp'] as String?,
);

Map<String, dynamic> _$SheetRowDtoToJson(SheetRowDto instance) =>
    <String, dynamic>{
      'semester': instance.semester,
      'subjectCode': instance.subjectCode,
      'classCode': instance.classCode,
      'teacher': instance.teacher,
      'titleVN': instance.titleVN,
      'titleEN': instance.titleEN,
      'content': instance.content,
      'form': instance.form,
      'attitude': instance.attitude,
      'achievement': instance.achievement,
      'limitation': instance.limitation,
      'conclusion': instance.conclusion,
      'contributions': instance.contributions,
      'status': _$DraftStatusEnumMap[instance.status],
      'decisions': instance.decisions,
      'grades': instance.grades,
      'gradingComponents': instance.gradingComponents,
      'timestamp': instance.timestamp,
    };

const _$DraftStatusEnumMap = {
  DraftStatus.notStarted: 'notStarted',
  DraftStatus.draft: 'draft',
  DraftStatus.complete: 'complete',
};
