// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_decision_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentDecisionDto _$StudentDecisionDtoFromJson(Map<String, dynamic> json) =>
    StudentDecisionDto(
      roll: json['roll'] as String,
      name: json['name'] as String,
      outcome: $enumDecode(_$DefenseOutcomeEnumMap, json['outcome']),
      note: json['note'] as String,
    );

Map<String, dynamic> _$StudentDecisionDtoToJson(StudentDecisionDto instance) =>
    <String, dynamic>{
      'roll': instance.roll,
      'name': instance.name,
      'outcome': _$DefenseOutcomeEnumMap[instance.outcome]!,
      'note': instance.note,
    };

const _$DefenseOutcomeEnumMap = {
  DefenseOutcome.agree: 'agree',
  DefenseOutcome.revisedForSecondDefense: 'revisedForSecondDefense',
  DefenseOutcome.disagree: 'disagree',
};
