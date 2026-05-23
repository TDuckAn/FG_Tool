import 'package:json_annotation/json_annotation.dart';

part 'member_contribution_dto.g.dart';

@JsonSerializable()
class MemberContributionDto {
  final String roll;
  final double percentage;

  const MemberContributionDto({required this.roll, required this.percentage});

  factory MemberContributionDto.fromJson(Map<String, dynamic> json) =>
      _$MemberContributionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MemberContributionDtoToJson(this);
}
