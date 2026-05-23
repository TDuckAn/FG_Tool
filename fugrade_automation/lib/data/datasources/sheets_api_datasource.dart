import 'dart:convert';
import 'dart:io';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;
import 'package:fugrade_automation/core/utils/app_logger.dart';
import 'package:fugrade_automation/data/models/cmt_draft_dto.dart';
import 'package:fugrade_automation/data/models/member_contribution_dto.dart';
import 'package:fugrade_automation/data/models/sheet_row_dto.dart';
import 'package:fugrade_automation/data/models/student_decision_dto.dart';

class SheetsApiException implements Exception {
  final String message;
  SheetsApiException(this.message);
  @override
  String toString() => 'SheetsApiException: $message';
}

class SheetsApiDatasource {
  static const _scopes = [SheetsApi.spreadsheetsScope];

  static const _finalHeaders = [
    'timestamp',
    'semester',
    'subjectCode',
    'classCode',
    'teacher',
    'titleVN',
    'titleEN',
    'content',
    'form',
    'attitude',
    'achievement',
    'limitation',
    'conclusion',
    'status',
    'contributionsJson',
    'decisionsJson',
    'gradesJson',
    'gradingComponentsJson',
  ];

  /// Column name aliases (case-insensitive, trim-safe) — spec §9.2
  static const _colAliases = {
    'semester': ['semester', 'học kỳ'],
    'subjectCode': ['subjectcode', 'subject code', 'mã môn'],
    'classCode': ['classcode', 'class code', 'class', 'lớp'],
    'teacher': ['teacher', 'giáo viên', 'gvhd'],
    'titleVN': ['titlevn', 'title vn', 'tên khóa luận', 'tiêu đề tiếng việt'],
    'titleEN': ['titleen', 'title en', 'english title', 'tiêu đề tiếng anh'],
    'content': ['content', 'nội dung', '3.1'],
    'form': ['form', 'hình thức', '3.2'],
    'attitude': ['attitude', 'thái độ', '3.3'],
    'achievement': ['achievement', 'mức đạt', '4.1'],
    'limitation': ['limitation', 'hạn chế', '4.2'],
    'conclusion': ['conclusion', 'kết luận'],
    'timestamp': ['timestamp', 'thời gian'],
    'status': ['status', 'completion', 'completed'],
    'contributionsJson': ['contributionsjson', 'contributions json'],
    'decisionsJson': ['decisionsjson', 'decisions json'],
    'gradesJson': ['gradesjson', 'grades json'],
    'gradingComponentsJson': [
      'gradingcomponentsjson',
      'grading components json',
      'componentsjson',
      'components json'
    ],
  };

  Future<SheetsApi> _buildApi() async {
    // Service account JSON bundled in assets/helper/
    final exeDir = p.dirname(Platform.resolvedExecutable);
    String? jsonPath;
    for (final candidate in [
      p.join(exeDir, 'data', 'flutter_assets', 'assets', 'helper', 'service_account.json'),
      p.join(exeDir, 'flutter_assets', 'assets', 'helper', 'service_account.json'),
    ]) {
      if (await File(candidate).exists()) {
        jsonPath = candidate;
        break;
      }
    }
    if (jsonPath == null) {
      throw SheetsApiException(
          'service_account.json not found. Reinstall the application.');
    }

    final credentials = ServiceAccountCredentials.fromJson(
        jsonDecode(await File(jsonPath).readAsString()));
    final client = await clientViaServiceAccount(credentials, _scopes);
    return SheetsApi(client);
  }

  /// Extracts the spreadsheet ID from a full Google Sheets URL.
  static String extractSheetId(String url) {
    final match =
        RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    if (match == null) throw SheetsApiException('Invalid Google Sheets URL.');
    return match.group(1)!;
  }

  Future<void> saveDraftToFinalSheet(String sheetIdOrUrl, CmtDraftDto draft) async {
    final sheetId = sheetIdOrUrl.contains('/')
        ? extractSheetId(sheetIdOrUrl)
        : sheetIdOrUrl;
    final api = await _buildApi();

    final meta = await api.spreadsheets.get(sheetId);
    final sheets = meta.sheets ?? [];
    if (sheets.isEmpty) {
      throw SheetsApiException('FINAL spreadsheet has no tabs.');
    }
    final tabName = sheets.first.properties?.title ?? 'FINAL';

    final row = _buildFinalRow(draft);
    final existing = await api.spreadsheets.values.get(sheetId, '$tabName!A:R');
    final rawRows = existing.values ?? [];

    if (rawRows.isEmpty) {
      await api.spreadsheets.values.update(
        ValueRange(values: [_finalHeaders, row]),
        sheetId,
        '$tabName!A1:R2',
        valueInputOption: 'USER_ENTERED',
      );
      return;
    }

    final headers = rawRows.first.map((h) => h.toString().trim()).toList();
    final colIndex = _buildColumnIndex(headers);
    if (!_hasFinalMatchColumns(colIndex)) {
      await api.spreadsheets.values.update(
        ValueRange(values: [_finalHeaders]),
        sheetId,
        '$tabName!A1:R1',
        valueInputOption: 'USER_ENTERED',
      );
    }

    final rowNumber = _findFinalRowNumber(rawRows, colIndex, draft);
    if (rowNumber == null) {
      await api.spreadsheets.values.append(
        ValueRange(values: [row]),
        sheetId,
        '$tabName!A:R',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );
    } else {
      await api.spreadsheets.values.update(
        ValueRange(values: [row]),
        sheetId,
        '$tabName!A$rowNumber:R$rowNumber',
        valueInputOption: 'USER_ENTERED',
      );
    }
  }

  List<Object?> _buildFinalRow(CmtDraftDto draft) {
    return [
      DateTime.now().toIso8601String(),
      draft.semester,
      draft.subjectCode,
      draft.classCode,
      draft.teacherLogin,
      draft.titleVN,
      draft.titleEN,
      draft.content,
      draft.formComment,
      draft.attitude,
      draft.achievement,
      draft.limitation,
      draft.conclusion,
      draft.status.name,
      jsonEncode(draft.contributions.map((e) => e.toJson()).toList()),
      jsonEncode(draft.decisions.map((e) => e.toJson()).toList()),
      jsonEncode(draft.grades),
      jsonEncode(_effectiveGradingComponents(draft)),
    ];
  }

  List<String> _effectiveGradingComponents(CmtDraftDto draft) {
    final components = <String>[
      ...draft.gradingComponents,
      for (final row in draft.grades.values) ...row.keys,
    ]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    return components.isEmpty
        ? const ['Component 1', 'Component 2', 'Component 3']
        : components;
  }

  bool _hasFinalMatchColumns(Map<String, int> colIndex) {
    return colIndex.containsKey('semester') &&
        colIndex.containsKey('subjectCode') &&
        colIndex.containsKey('classCode') &&
        colIndex.containsKey('teacher');
  }

  int? _findFinalRowNumber(
    List<List<Object?>> rawRows,
    Map<String, int> colIndex,
    CmtDraftDto draft,
  ) {
    if (!_hasFinalMatchColumns(colIndex)) return null;

    String cell(List<Object?> row, String key) {
      final index = colIndex[key];
      return index != null && index < row.length ? row[index].toString().trim() : '';
    }

    for (var i = 1; i < rawRows.length; i++) {
      final row = rawRows[i];
      if (cell(row, 'semester') == draft.semester &&
          cell(row, 'subjectCode') == draft.subjectCode &&
          cell(row, 'classCode') == draft.classCode &&
          cell(row, 'teacher') == draft.teacherLogin) {
        return i + 1;
      }
    }

    return null;
  }

  Future<List<SheetRowDto>> fetchRows(String sheetIdOrUrl) async {
    final sheetId = sheetIdOrUrl.contains('/')
        ? extractSheetId(sheetIdOrUrl)
        : sheetIdOrUrl;

    final api = await _buildApi();

    // Discover the first (or form-response) tab name dynamically — the user's
    // sheet may use "Form Responses 1", "Form_Responses", "Sheet1", etc.
    final meta = await api.spreadsheets.get(sheetId);
    final sheets = meta.sheets ?? [];
    if (sheets.isEmpty) {
      throw SheetsApiException('Spreadsheet has no tabs.');
    }
    final tabName = sheets.first.properties?.title ?? 'Sheet1';
    AppLogger.info(
        'Reading sheet "$tabName" (${sheets.length} tab(s) available)',
        tag: 'Sheets');

    final response = await api.spreadsheets.values.get(sheetId, tabName);
    final rawRows = response.values;
    if (rawRows == null || rawRows.isEmpty) {
      AppLogger.warning('Sheet "$tabName" is empty', tag: 'Sheets');
      return [];
    }

    final headers = rawRows.first.map((h) => h.toString().trim()).toList();
    AppLogger.info('Headers: ${headers.join(" | ")}', tag: 'Sheets');
    final colIndex = _buildColumnIndex(headers);
    AppLogger.info('Mapped columns: ${colIndex.keys.join(", ")}', tag: 'Sheets');

    final rows = <SheetRowDto>[];
    int skipped = 0;
    for (final row in rawRows.skip(1)) {
      final cells = List<String>.generate(
        headers.length,
        (i) => i < row.length ? row[i].toString().trim() : '',
      );
      final dto = _parseRow(cells, colIndex);
      if (dto != null) {
        rows.add(dto);
      } else {
        skipped++;
      }
    }
    AppLogger.info(
        'Parsed ${rows.length} row(s); skipped $skipped row(s) with missing match keys',
        tag: 'Sheets');

    await _cacheRows(sheetId, rows);
    return rows;
  }

  Future<List<SheetRowDto>> fetchRowsCached(String sheetIdOrUrl) async {
    final sheetId = sheetIdOrUrl.contains('/')
        ? extractSheetId(sheetIdOrUrl)
        : sheetIdOrUrl;
    try {
      return await fetchRows(sheetIdOrUrl);
    } catch (_) {
      return await _loadCache(sheetId) ?? [];
    }
  }

  Map<String, int> _buildColumnIndex(List<String> headers) {
    final index = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase().trim();
      for (final entry in _colAliases.entries) {
        if (entry.value.contains(h)) {
          index[entry.key] = i;
          break;
        }
      }
      // Contribution columns: member1roll, member1percent, ...
      final contribMatch = RegExp(r'^member(\d)roll$').firstMatch(h);
      if (contribMatch != null) {
        index['member${contribMatch.group(1)}roll'] = i;
      }
      final percentMatch = RegExp(r'^member(\d)percent$').firstMatch(h);
      if (percentMatch != null) {
        index['member${percentMatch.group(1)}percent'] = i;
      }
    }
    return index;
  }

  SheetRowDto? _parseRow(List<String> cells, Map<String, int> idx) {
    String get(String key) {
      final i = idx[key];
      return (i != null && i < cells.length) ? cells[i] : '';
    }

    final semester = get('semester');
    final subjectCode = get('subjectCode');
    final classCode = get('classCode');
    final teacher = get('teacher');
    if (semester.isEmpty || subjectCode.isEmpty ||
        classCode.isEmpty || teacher.isEmpty) {
      return null;
    }

    final contributions = _parseContributions(get('contributionsJson'));
    if (contributions.isEmpty) {
      for (int n = 1; n <= 6; n++) {
        final roll = get('member${n}roll');
        final pct = double.tryParse(get('member${n}percent')) ?? 0;
        if (roll.isNotEmpty) {
          contributions.add(MemberContributionDto(roll: roll, percentage: pct));
        }
      }
    }

    final gradingComponents = _parseStringList(get('gradingComponentsJson'));
    final grades = _parseGrades(get('gradesJson'));
    final effectiveComponents = gradingComponents.isNotEmpty
        ? gradingComponents
        : grades.values.expand((row) => row.keys).toSet().toList();

    return SheetRowDto(
      semester: semester,
      subjectCode: subjectCode,
      classCode: classCode,
      teacher: teacher,
      titleVN: get('titleVN'),
      titleEN: get('titleEN'),
      content: get('content'),
      form: get('form'),
      attitude: get('attitude'),
      achievement: get('achievement'),
      limitation: get('limitation'),
      conclusion: get('conclusion'),
      contributions: contributions,
      status: _parseDraftStatus(get('status')),
      decisions: _parseDecisions(get('decisionsJson')),
      grades: grades,
      gradingComponents: effectiveComponents,
      timestamp: get('timestamp').isEmpty ? null : get('timestamp'),
    );
  }

  List<MemberContributionDto> _parseContributions(String raw) {
    if (raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(MemberContributionDto.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<StudentDecisionDto> _parseDecisions(String raw) {
    if (raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(StudentDecisionDto.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, Map<String, double>> _parseGrades(String raw) {
    if (raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((studentId, scores) {
        if (scores is! Map) return MapEntry(studentId.toString(), <String, double>{});
        return MapEntry(
          studentId.toString(),
          scores.map((component, score) {
            final parsed = score is num ? score.toDouble() : double.tryParse(score.toString());
            return MapEntry(component.toString(), parsed ?? 0);
          }),
        );
      });
    } catch (_) {
      return {};
    }
  }

  List<String> _parseStringList(String raw) {
    if (raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }

  DraftStatus? _parseDraftStatus(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    for (final status in DraftStatus.values) {
      if (status.name == normalized) return status;
    }
    if (normalized.toLowerCase() == 'completed') return DraftStatus.complete;
    if (normalized.toLowerCase() == 'not completed') return DraftStatus.draft;
    return null;
  }

  Future<void> _cacheRows(String sheetId, List<SheetRowDto> rows) async {
    try {
      final appData = Directory(Platform.environment['APPDATA'] ?? Directory.systemTemp.path);
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final file = File(p.join(appData.path, 'fugrade_automation',
          'sheets_cache', '${sheetId}_$date.json'));
      await file.parent.create(recursive: true);
      await file.writeAsString(
          jsonEncode(rows.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }

  Future<List<SheetRowDto>?> _loadCache(String sheetId) async {
    try {
      final appData = Directory(Platform.environment['APPDATA'] ?? Directory.systemTemp.path);
      final cacheDir = Directory(p.join(
          appData.path, 'fugrade_automation', 'sheets_cache'));
      if (!await cacheDir.exists()) return null;

      final files = await cacheDir
          .list()
          .where((e) => e.path.contains(sheetId) && e.path.endsWith('.json'))
          .cast<File>()
          .toList();
      if (files.isEmpty) return null;

      files.sort((a, b) => b.path.compareTo(a.path));
      final json = jsonDecode(await files.first.readAsString()) as List;
      return json
          .map((e) => SheetRowDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
