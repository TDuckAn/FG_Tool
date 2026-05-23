import 'package:fugrade_automation/core/constants/app_strings.dart';
import 'package:fugrade_automation/core/utils/roll_utils.dart';
import 'package:fugrade_automation/data/models/member_contribution_dto.dart';
import 'package:fugrade_automation/data/models/student_dto.dart';

class ContributionMergeService {
  /// Appends the contribution block to the attitude narrative text.
  /// Names are resolved from the .fg student list (authoritative source).
  String buildAttitudeText({
    required String attitudeNarrative,
    required List<MemberContributionDto> contributions,
    required List<StudentDto> fgStudents,
    List<String> warnings = const [],
  }) {
    if (contributions.isEmpty) return attitudeNarrative;

    final buf = StringBuffer(attitudeNarrative.trimRight());
    buf.write('\n\n${AppStrings.contributionHeader}\n');

    for (final c in contributions) {
      final student = fgStudents
          .cast<StudentDto?>()
          .firstWhere((s) => rollsMatch(s!.roll, c.roll), orElse: () => null);
      final label = student?.name ?? c.roll;
      buf.write('- $label (${c.roll}): ${c.percentage.toStringAsFixed(0)}%\n');
    }

    return buf.toString();
  }

  /// Returns rolls from [contributions] that cannot be matched to [fgStudents].
  List<String> findUnmatchedRolls({
    required List<MemberContributionDto> contributions,
    required List<StudentDto> fgStudents,
  }) {
    return contributions
        .where((c) => !fgStudents.any((s) => rollsMatch(s.roll, c.roll)))
        .map((c) => c.roll)
        .toList();
  }
}
