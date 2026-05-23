import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:fugrade_automation/data/models/cmt_draft_dto.dart';
import 'package:fugrade_automation/data/models/student_decision_dto.dart';
import 'package:fugrade_automation/core/utils/file_utils.dart';

class CmtWriteException implements Exception {
  final String message;
  CmtWriteException(this.message);
  @override
  String toString() => 'CmtWriteException: $message';
}

class CmtWriterDatasource {
  static Future<String> _helperPath() async {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    for (final candidate in [
      p.join(exeDir, 'data', 'flutter_assets', 'assets', 'helper', 'FuGradeHelper.exe'),
      p.join(exeDir, 'flutter_assets', 'assets', 'helper', 'FuGradeHelper.exe'),
    ]) {
      if (await File(candidate).exists()) return candidate;
    }
    throw StateError('FuGradeHelper.exe not found. Reinstall the application.');
  }

  Future<String> writeCmt(CmtDraftDto draft, String outputDirectory) async {
    final filename = buildCmtFilename(
      login: draft.teacherLogin,
      semester: draft.semester,
      classCode: draft.classCode,
      fgVersion: draft.fgVersion,
    );
    final outputPath = p.join(outputDirectory, filename);

    final payload = {
      'teacherLogin': draft.teacherLogin,
      'semester': draft.semester,
      'subjectCode': draft.subjectCode,
      'classCode': draft.classCode,
      'titleVN': draft.titleVN,
      'titleEN': draft.titleEN,
      'content': draft.content,
      'formComment': draft.formComment,
      'attitude': draft.attitude,
      'achievement': draft.achievement,
      'limitation': draft.limitation,
      'conclusion': draft.conclusion,
      'students': draft.decisions
          .map((d) => {
                'roll': d.roll,
                'name': d.name,
                'outcome': _outcomeString(d.outcome),
                'note': d.note,
              })
          .toList(),
    };

    final helper = await _helperPath();
    final result = await Process.run(
      helper,
      ['write-cmt', '--data', jsonEncode(payload), '--output', outputPath],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      throw CmtWriteException((result.stderr as String).trim());
    }

    return outputPath;
  }

  String _outcomeString(DefenseOutcome outcome) {
    return switch (outcome) {
      DefenseOutcome.agree => 'agree',
      DefenseOutcome.revisedForSecondDefense => 'revised',
      DefenseOutcome.disagree => 'disagree',
    };
  }
}
