# FG Tool - AI Dev Context

## Goal
Windows desktop suite for FPT University instructors. Automates FuGrade `.fg` parsing and `.cmt` comment file generation.

## Repo Shape
- `fugrade_automation/` Flutter Windows GUI.
- `FuGradeHelper/` .NET Framework 4.8 CLI bridge for FuGrade binary formats.
- `FuGradeTypes/` .NET Framework 4.8 library named assembly `FuGrade` for `.cmt` compatibility.
- `Tool FUGE/` bundled original FuGrade binaries/manuals. Treat as vendor/binary assets.

## Main Workflow
Flutter app:
1. User selects `.fg`.
2. App calls `FuGradeHelper.exe parse-fg <path.fg>`.
3. Helper emits JSON:
   - `version`
   - `semester`
   - `login`
   - `groups[]`
     - `subject`
     - `classCode`
     - `students[] { roll, name }`
     - `gradingComponents[]`
     - computed `isCapstone` in C# DTO and Dart model.
4. Flutter syncs Google Sheets contribution data.
5. App fuzzy-matches sheet rows to `.fg` groups/students.
6. User edits per-group thesis comment draft.
7. App calls `FuGradeHelper.exe write-cmt --data-file <json> --output <path.cmt>`.
8. Generated `.cmt` opens in FuGrade Editor.

## Commands
```cmd
dotnet build FuGradeHelper\FuGradeHelper.csproj -c Release
cd fugrade_automation && flutter pub get
cd fugrade_automation && dart run build_runner build --delete-conflicting-outputs
cd fugrade_automation && flutter run -d windows
```

Helper CLI:
```cmd
FuGradeHelper.exe parse-fg <path.fg>
FuGradeHelper.exe write-cmt --data <json> --output <path.cmt>
FuGradeHelper.exe write-cmt --data-file <path.json> --output <path.cmt>
FuGradeHelper.exe read-cmt <path.cmt>
FuGradeHelper.exe inspect-cmt <path.cmt>
```

## C# Projects
### `FuGradeHelper/FuGradeHelper.csproj`
- `net48`, executable, C# 9.
- Package: `Newtonsoft.Json 13.0.3`.
- References `..\FuGradeTypes\FuGradeTypes.csproj`.

### `FuGradeTypes/FuGradeTypes.csproj`
- `net48`, library.
- Critical: `<AssemblyName>FuGrade</AssemblyName>`.
- Do not rename. BinaryFormatter writes assembly identity into `.cmt`.

### `FuGradeTypes/ThesisTypes.cs`
Namespace `FuGrade`.
Serializable classes:
- `ThesisComment`
  - `Teacher`, `DT`, `SubjectCode`, `ClassName`, `Semester`, `Password`
  - `TitleVN`, `TitleEN`, `Content`, `Form`, `Attitude`, `Achievement`, `Limitation`
  - `List<ThesisStudent> Conclusion`
- `ThesisStudent`
  - `Roll`, `Name`
  - `Agree_to_defense`
  - `Revised_for_the_second_defense`
  - `Disagree_to_defense`
  - `Note`

Auto-properties required: BinaryFormatter serializes backing fields as `<Prop>k__BackingField`.

### `FuGradeHelper/Program.cs`
Top-level dispatch:
- `parse-fg` -> `ParseFgCommand.Run(args[1])`
- `write-cmt` -> `WriteCmtCommand.Run(jsonData, outputPath)`
- `read-cmt` -> `ReadCmtCommand.Run(args[1])`
- `inspect-cmt` -> `InspectCmtCommand.Run(args[1])`
UTF-8 stdin/stdout.

### `ParseFgCommand`
- Reads raw BinaryFormatter `.fg` stream if first byte is `0x00`.
- Also accepts base64 text wrapping binary stream.
- Uses `BinaryFormatter` with `FgSerializationBinder`.
- Maps `TeacherGradeSurrogate` to `TeacherGradeOutputDto`.
- Keeps non-capstone groups; Flutter filters.
- Extracts distinct non-empty grade component names.

### Surrogates
Used to deserialize proprietary `FuGradeLib` types without original source.
Important files:
- `FgSerializationBinder.cs`
- `TeacherGradeSurrogate.cs`
- `SubjectClassGradeSurrogate.cs`
- `StudentSurrogate.cs`
- `GradeComponentPlaceholder.cs`
- `SerializationHelper.cs`
- `ThesisCommentTypes.cs`

`SubjectClassGradeSurrogate` extracts subject/class from multiple possible field names. `GradeComponentPlaceholder` extracts display name from `Name`, `ComponentName`, `Title`, or `Description`.

## Flutter Project
### `fugrade_automation/pubspec.yaml`
Dart SDK `^3.11.5`.
Deps:
- `flutter_bloc ^9.1.1`
- `equatable ^2.0.7`
- `googleapis ^14.0.0`
- `googleapis_auth ^1.6.0`
- `file_picker ^5.5.0`
- `window_manager ^0.4.3`
- `path ^1.9.1`
- `json_annotation ^4.9.0`
Dev:
- `flutter_lints ^6.0.0`
- `build_runner ^2.4.15`
- `json_serializable ^6.9.5`
- `bloc_test ^10.0.0`
Assets:
- `assets/helper/`

### Actual `lib/` Structure
```text
main.dart
core/constants/app_strings.dart
core/constants/capstone_subjects.dart
core/constants/cmt_password.dart
core/theme/app_theme.dart
core/utils/app_logger.dart
core/utils/file_utils.dart
core/utils/roll_utils.dart
core/utils/semester_utils.dart
core/utils/version_utils.dart
data/datasources/cmt_writer_datasource.dart
data/datasources/fg_parser_datasource.dart
data/datasources/local_storage_datasource.dart
data/datasources/sheets_api_datasource.dart
data/models/cmt_draft_dto.dart
data/models/group_match_result.dart
data/models/member_contribution_dto.dart
data/models/sheet_row_dto.dart
data/models/student_decision_dto.dart
data/models/student_dto.dart
data/models/subject_class_grade_dto.dart
data/models/teacher_grade_dto.dart
domain/services/contribution_merge_service.dart
domain/services/matching_service.dart
presentation/blocs/cmt_editor/cmt_editor_bloc.dart
presentation/blocs/export/export_bloc.dart
presentation/blocs/fg_loader/fg_loader_bloc.dart
presentation/blocs/sheet_sync/sheet_sync_bloc.dart
presentation/screens/cmt_editor_screen.dart
presentation/screens/export_screen.dart
presentation/screens/group_list_screen.dart
presentation/screens/home_screen.dart
```

### Flutter Architecture
- Data layer calls helper CLI and Google Sheets.
- Domain layer handles matching and contribution merge.
- Presentation uses BLoC.
- UI theme: Material 3, “Scholarly Modernism”, paper tones, Windows-friendly fonts.

### Key Screens
`HomeScreen`:
- Shows `PaperBackground`.
- `BlocListener<FgLoaderBloc, FgLoaderState>`.
- On `FgLoaderLoaded`, navigates to `GroupListScreen(grade: state.grade)`.
- On `FgLoaderError`, shows rust snackbar.
- `_DropZone`: FilePicker picks `.fg`, dispatches `FgFileSelected(path)`.
- `_OpenCmtButton`: FilePicker picks `.cmt`, calls `FgParserDatasource.readCmtFile(path)`, maps JSON to `CmtDraftDto`, navigates to `CmtEditorScreen`.

### DTO Notes
`SubjectClassGradeDto`:
```dart
@JsonSerializable()
class SubjectClassGradeDto {
  final String subject;
  final String classCode;
  final List<StudentDto> students;
  final List<String> gradingComponents;
  bool get isCapstone => isCapstoneSubject(subject);
}
```
Generated files (`*.g.dart`) are output of `json_serializable`; do not hand-edit.

## Coding Rules
- Keep C# compatible with .NET Framework 4.8 and C# 9.
- Do not enable nullable unless updating whole project intentionally.
- Do not rename `FuGradeTypes` output assembly from `FuGrade`.
- Do not alter serialized property names in `ThesisComment` / `ThesisStudent` without FuGrade binary validation.
- Treat BinaryFormatter use as compatibility requirement, not modern serialization choice.
- For Dart, follow Flutter lints and existing BLoC/data/domain/presentation split.
- Add new DTO fields with matching `json_serializable` regeneration.
- Prefer `--data-file` for large CMT JSON payloads to avoid command-line length issues on Windows.
- Keep helper stdout machine-readable JSON on success; diagnostics go stderr.
- Avoid committing build outputs from `bin/`, `obj/`, `.dart_tool/`, `build/`.

## Verification
After C# changes:
```cmd
dotnet build FuGradeHelper\FuGradeHelper.csproj -c Release
```
After Dart model changes:
```cmd
cd fugrade_automation && dart run build_runner build --delete-conflicting-outputs
```
After Flutter changes:
```cmd
cd fugrade_automation && flutter analyze
```

## Planning Rules

- **Always run `git diff HEAD` before planning** to see what has already been implemented. Codex handles implementation; Codex plans. Without checking the diff, you will re-plan work that is already done and give Codex redundant or conflicting instructions.

## Common Pitfalls

- `.fg` may be raw binary, base64-wrapped binary, or AES-encrypted base64.
- `.cmt` compatibility depends on exact assembly name `FuGrade`.
- BinaryFormatter serializes field/property metadata; renames break files.
- Windows command line length can break inline `--data`.
- Generated Dart `*.g.dart` files must match model source.
- README may describe intended architecture; inspect actual files before broad refactors.
- Grading component names are NOT stored in the `.fg` binary for all classes. The school tool reads them from `FinalThesisGradingItems.master` by subject code. Non-thesis courses (e.g. PRC392c, SYB302c) may have no components in either source.
