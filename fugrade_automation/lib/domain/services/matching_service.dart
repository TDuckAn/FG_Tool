import 'package:fugrade_automation/core/utils/app_logger.dart';
import 'package:fugrade_automation/data/models/group_match_result.dart';
import 'package:fugrade_automation/data/models/sheet_row_dto.dart';
import 'package:fugrade_automation/data/models/subject_class_grade_dto.dart';

class MatchingService {
  /// Matches each capstone group from the .fg file against sheet rows using
  /// the 4-field composite key: semester + subjectCode + classCode + teacher.
  List<GroupMatchResult> match({
    required List<SubjectClassGradeDto> fgGroups,
    required List<SheetRowDto> sheetRows,
    required String fgSemester,
    required String fgLogin,
  }) {
    final capstone = fgGroups.where((g) => g.isCapstone).toList();

    AppLogger.info(
        'Matching ${capstone.length} capstone groups against ${sheetRows.length} sheet rows',
        tag: 'Matcher');
    AppLogger.info(
        '.fg side → semester="$fgSemester" (normalized="${_n(fgSemester)}"), teacher="$fgLogin" (normalized="${_n(fgLogin)}")',
        tag: 'Matcher');

    return capstone.map((group) {
      AppLogger.info(
          'Group: subject="${group.subject}" class="${group.classCode}" '
          '(normalized: "${_n(group.subject)}", "${_n(group.classCode)}")',
          tag: 'Matcher');

      GroupMatchResult? bestPartial;

      for (final row in sheetRows) {
        final s = _n(row.semester) == _n(fgSemester);
        final c = _n(row.subjectCode) == _n(group.subject);
        final k = _n(row.classCode) == _n(group.classCode);
        final t = _n(row.teacher) == _n(fgLogin);

        if (s && c && k && t) {
          AppLogger.info(
              '  ✓ EXACT MATCH ← sheet row [${row.semester} | ${row.subjectCode} | ${row.classCode} | ${row.teacher}]',
              tag: 'Matcher');
          return GroupMatchResult.exact(group, row);
        }

        final matchCount = [s, c, k, t].where((b) => b).length;
        if (matchCount >= 2) {
          AppLogger.info(
              '  · row [${row.semester} | ${row.subjectCode} | ${row.classCode} | ${row.teacher}] → '
              'semester=${s ? "✓" : "✗"} subject=${c ? "✓" : "✗"} class=${k ? "✓" : "✗"} teacher=${t ? "✓" : "✗"} ($matchCount/4)',
              tag: 'Matcher');
        }

        if (matchCount == 3 && bestPartial == null) {
          final mismatched = !t
              ? 'teacher'
              : !k
                  ? 'classCode'
                  : !c
                      ? 'subject'
                      : 'semester';
          bestPartial = GroupMatchResult.partial(group, row, mismatched);
        }
      }

      if (bestPartial == null) {
        AppLogger.info('  ✗ NO MATCH for ${group.classCode}', tag: 'Matcher');
      }

      return bestPartial ?? GroupMatchResult.none(group);
    }).toList();
  }

  String _n(String s) =>
      s.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
}
