import 'package:json_annotation/json_annotation.dart';

part 'student_decision_dto.g.dart';

enum DefenseOutcome { agree, revisedForSecondDefense, disagree }

@JsonSerializable()
class StudentDecisionDto {
  final String roll;
  final String name;
  final DefenseOutcome outcome;
  final String note;

  const StudentDecisionDto({
    required this.roll,
    required this.name,
    required this.outcome,
    required this.note,
  });

  StudentDecisionDto copyWith({
    DefenseOutcome? outcome,
    String? note,
  }) =>
      StudentDecisionDto(
        roll: roll,
        name: name,
        outcome: outcome ?? this.outcome,
        note: note ?? this.note,
      );

  factory StudentDecisionDto.fromJson(Map<String, dynamic> json) =>
      _$StudentDecisionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$StudentDecisionDtoToJson(this);
}
