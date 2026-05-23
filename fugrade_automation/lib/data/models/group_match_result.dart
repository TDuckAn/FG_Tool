import 'subject_class_grade_dto.dart';
import 'sheet_row_dto.dart';

enum MatchStatus { exact, partial, none }

class GroupMatchResult {
  final SubjectClassGradeDto group;
  final MatchStatus matchStatus;
  final SheetRowDto? matchedRow;
  final String? mismatchField;

  const GroupMatchResult._({
    required this.group,
    required this.matchStatus,
    this.matchedRow,
    this.mismatchField,
  });

  factory GroupMatchResult.exact(SubjectClassGradeDto group, SheetRowDto row) =>
      GroupMatchResult._(
          group: group, matchStatus: MatchStatus.exact, matchedRow: row);

  factory GroupMatchResult.partial(
          SubjectClassGradeDto group, SheetRowDto row, String mismatchField) =>
      GroupMatchResult._(
          group: group,
          matchStatus: MatchStatus.partial,
          matchedRow: row,
          mismatchField: mismatchField);

  factory GroupMatchResult.none(SubjectClassGradeDto group) =>
      GroupMatchResult._(group: group, matchStatus: MatchStatus.none);
}
