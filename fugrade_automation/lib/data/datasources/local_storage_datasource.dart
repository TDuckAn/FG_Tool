import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:fugrade_automation/data/models/cmt_draft_dto.dart';

class LocalStorageDatasource {
  static String get _appDataRoot =>
      Platform.environment['APPDATA'] ?? Directory.systemTemp.path;

  Future<Directory> _draftsDir(String semester, String login) async {
    final dir = Directory(
        p.join(_appDataRoot, 'fugrade_automation', 'drafts', '${semester}_$login'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> _configFile() async {
    return File(p.join(_appDataRoot, 'fugrade_automation', 'config.json'));
  }

  Future<String> loadFinalSheetUrl() async {
    final config = await loadConfig();
    return (config['finalSheetUrl'] ?? '').toString();
  }

  Future<void> saveSheetUrls({
    required String responseSheetUrl,
    required String finalSheetUrl,
  }) async {
    final config = await loadConfig();
    config['responseSheetUrl'] = responseSheetUrl;
    config['finalSheetUrl'] = finalSheetUrl;
    await saveConfig(config);
  }

  Future<void> saveDraft(CmtDraftDto draft) async {
    final dir = await _draftsDir(draft.semester, draft.teacherLogin);
    final file = File(p.join(dir.path, '${draft.classCode}.json'));
    // Atomic write: write to .tmp then rename
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(draft.toJson()), encoding: utf8);
    await tmp.rename(file.path);
  }

  Future<CmtDraftDto?> loadDraft(
      String semester, String login, String classCode) async {
    final dir = await _draftsDir(semester, login);
    final file = File(p.join(dir.path, '$classCode.json'));
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString(encoding: utf8))
        as Map<String, dynamic>;
    return CmtDraftDto.fromJson(json);
  }

  Future<List<CmtDraftDto>> loadAllDrafts(String semester, String login) async {
    final dir = await _draftsDir(semester, login);
    final results = <CmtDraftDto>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final json = jsonDecode(await entity.readAsString(encoding: utf8))
              as Map<String, dynamic>;
          results.add(CmtDraftDto.fromJson(json));
        } catch (_) {}
      }
    }
    return results;
  }

  Future<Map<String, dynamic>> loadConfig() async {
    final file = await _configFile();
    if (!await file.exists()) return {};
    try {
      return jsonDecode(await file.readAsString(encoding: utf8))
          as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveConfig(Map<String, dynamic> config) async {
    final file = await _configFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(config), encoding: utf8);
  }
}
