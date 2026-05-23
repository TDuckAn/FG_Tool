import 'dart:io';

/// Builds the .cmt filename per spec §2.3 and §12.2.
/// v >= 1.1:  {login}.{Semester}_{classCode}.cmt
/// older:     {login}{Semester}_{classCode}.cmt
String buildCmtFilename({
  required String login,
  required String semester,
  required String classCode,
  required String fgVersion,
}) {
  final usesDot = _versionAtLeast11(fgVersion);
  return usesDot
      ? '$login.${semester}_$classCode.cmt'
      : '$login${semester}_$classCode.cmt';
}

bool _versionAtLeast11(String v) {
  final parts = v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  if (parts.isEmpty) return true;
  if (parts[0] > 1) return true;
  if (parts[0] == 1 && (parts.length < 2 || parts[1] >= 1)) return true;
  return false;
}

/// Returns the app data directory for draft/config storage.
/// Resolves to %APPDATA%\fugrade_automation on Windows.
Future<Directory> getAppDataDir() async {
  // Caller should inject path_provider; this is the leaf helper.
  throw UnimplementedError('Use DraftStorageService instead.');
}
