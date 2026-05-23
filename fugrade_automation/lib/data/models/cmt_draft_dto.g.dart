// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cmt_draft_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CmtDraftDto _$CmtDraftDtoFromJson(Map<String, dynamic> json) => CmtDraftDto(
  teacherLogin: json['teacherLogin'] as String,
  semester: json['semester'] as String,
  subjectCode: json['subjectCode'] as String,
  classCode: json['classCode'] as String,
  students: (json['students'] as List<dynamic>)
      .map((e) => StudentDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  fgVersion: json['fgVersion'] as String,
  titleVN: json['titleVN'] as String? ?? '',
  titleEN: json['titleEN'] as String? ?? '',
  content: json['content'] as String? ?? '',
  formComment: json['formComment'] as String? ?? '',
  attitude: json['attitude'] as String? ?? '',
  achievement: json['achievement'] as String? ?? '',
  limitation: json['limitation'] as String? ?? '',
  conclusion: json['conclusion'] as String? ?? '',
  decisions: (json['decisions'] as List<dynamic>)
      .map((e) => StudentDecisionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  contributions:
      (json['contributions'] as List<dynamic>?)
          ?.map(
            (e) => MemberContributionDto.fromJson(e as Map<String, dynamic>),
          )
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
  status:
      $enumDecodeNullable(_$DraftStatusEnumMap, json['status']) ??
      DraftStatus.notStarted,
  matchStatus:
      $enumDecodeNullable(_$MatchStatusEnumMap, json['matchStatus']) ??
      MatchStatus.none,
  lastEditedAt: json['lastEditedAt'] == null
      ? null
      : DateTime.parse(json['lastEditedAt'] as String),
  exportedAt: json['exportedAt'] == null
      ? null
      : DateTime.parse(json['exportedAt'] as String),
);

Map<String, dynamic> _$CmtDraftDtoToJson(CmtDraftDto instance) =>
    <String, dynamic>{
      'teacherLogin': instance.teacherLogin,
      'semester': instance.semester,
      'subjectCode': instance.subjectCode,
      'classCode': instance.classCode,
      'students': instance.students,
      'fgVersion': instance.fgVersion,
      'titleVN': instance.titleVN,
      'titleEN': instance.titleEN,
      'content': instance.content,
      'formComment': instance.formComment,
      'attitude': instance.attitude,
      'achievement': instance.achievement,
      'limitation': instance.limitation,
      'conclusion': instance.conclusion,
      'decisions': instance.decisions,
      'contributions': instance.contributions,
      'grades': instance.grades,
      'gradingComponents': instance.gradingComponents,
      'status': _$DraftStatusEnumMap[instance.status]!,
      'matchStatus': _$MatchStatusEnumMap[instance.matchStatus]!,
      'lastEditedAt': instance.lastEditedAt?.toIso8601String(),
      'exportedAt': instance.exportedAt?.toIso8601String(),
    };

const _$DraftStatusEnumMap = {
  DraftStatus.notStarted: 'notStarted',
  DraftStatus.draft: 'draft',
  DraftStatus.complete: 'complete',
};

const _$MatchStatusEnumMap = {
  MatchStatus.exact: 'exact',
  MatchStatus.partial: 'partial',
  MatchStatus.none: 'none',
};
