// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_contribution_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberContributionDto _$MemberContributionDtoFromJson(
  Map<String, dynamic> json,
) => MemberContributionDto(
  roll: json['roll'] as String,
  percentage: (json['percentage'] as num).toDouble(),
);

Map<String, dynamic> _$MemberContributionDtoToJson(
  MemberContributionDto instance,
) => <String, dynamic>{
  'roll': instance.roll,
  'percentage': instance.percentage,
};
