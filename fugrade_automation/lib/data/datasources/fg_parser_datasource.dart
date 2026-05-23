import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:fugrade_automation/data/models/teacher_grade_dto.dart';

class FgParseException implements Exception {
  final String message;
  final int exitCode;
  FgParseException(this.message, this.exitCode);
  @override
  String toString() => 'FgParseException($exitCode): $message';
}

class FgParserDatasource {
  /// Resolves the bundled FuGradeHelper.exe path relative to the executable.
  static Future<String> _helperPath() async {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    // In release build: data\flutter_assets\assets\helper\FuGradeHelper.exe
    // In debug build:   flutter_assets\assets\helper\FuGradeHelper.exe
    for (final candidate in [
      p.join(exeDir, 'data', 'flutter_assets', 'assets', 'helper', 'FuGradeHelper.exe'),
      p.join(exeDir, 'flutter_assets', 'assets', 'helper', 'FuGradeHelper.exe'),
    ]) {
      if (await File(candidate).exists()) return candidate;
    }
    throw StateError('FuGradeHelper.exe not found. Reinstall the application.');
  }

  Future<Map<String, dynamic>> readCmtFile(String filePath) async {
    final helper = await _helperPath();
    final result = await Process.run(
      helper,
      ['read-cmt', filePath],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw FgParseException((result.stderr as String).trim(), result.exitCode);
    }
    return jsonDecode(result.stdout as String) as Map<String, dynamic>;
  }

  Future<TeacherGradeDto> parseFgFile(String filePath) async {
    final helper = await _helperPath();
    final result = await Process.run(
      helper,
      ['parse-fg', filePath],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      throw FgParseException(
          (result.stderr as String).trim(), result.exitCode);
    }

    final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    return TeacherGradeDto.fromJson(json);
  }
}
