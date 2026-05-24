# FG Tool

FuGrade Automation Suite for FPT University grading workflows.

FG Tool is a Windows desktop application plus a .NET helper that works with FuGrade `.fg` and `.cmt` files. It parses FuGrade grade exports, fills capstone/thesis comment drafts, syncs contribution data with Google Sheets, writes FINAL-sheet summaries, and can write grading component scores back into supported `.fg` files.

## What It Does

| Workflow | Support |
| --- | --- |
| Parse `.fg` files | Reads FuGrade grade exports through `FuGradeHelper.exe parse-fg`. |
| Load thesis grading components | Enriches parsed groups from `FinalThesisGradingItems.master` when FuGrade data has empty component lists. |
| Edit `.cmt` drafts | Provides a Flutter editor for per-group thesis comments and student verdicts. |
| Generate `.cmt` files | Writes binary `.cmt` files accepted by FuGrade Editor. |
| Sync Google Sheets | Reads group/member/contribution data and matches it to `.fg` students. |
| Update FINAL sheet | Writes key-based FINAL rows, contribution paragraph text, and contribution JSON without relying on fixed column positions. |
| Update `.fg` grades | Writes grading component scores back to supported JSON/AES FuGrade `.fg` payloads. |

## Repository Layout

```text
FG_Tool/
|-- fugrade_automation/       Flutter Windows desktop app
|   |-- assets/helper/        Bundled helper executable, DLLs, and master files
|   `-- lib/                  App source, BLoCs, screens, data sources, models
|-- FuGradeHelper/            .NET Framework 4.8 CLI bridge
|   |-- Commands/             parse-fg, write-fg, read-cmt, write-cmt, inspect-cmt
|   |-- Dtos/                 CLI JSON DTOs
|   `-- Surrogates/           BinaryFormatter surrogate and binder support
|-- FuGradeTypes/             Assembly named `FuGrade` for FuGrade-compatible types
`-- README.md
```

The Flutter app runs `FuGradeHelper.exe` as a subprocess. The helper handles FuGrade-specific file formats and returns JSON to the Dart application.

## Requirements

- Windows 10/11.
- Flutter SDK compatible with `fugrade_automation/pubspec.yaml`.
- .NET Framework 4.8 build toolchain, via Visual Studio or `dotnet`.
- Google service account credentials for Sheets integration.
- FuGrade helper assets bundled in `fugrade_automation/assets/helper/`.

## Helper Assets

The Flutter app expects these files under `fugrade_automation/assets/helper/`:

```text
FuGradeHelper.exe
FuGrade.dll
Newtonsoft.Json.dll
MasterFile/FinalThesisGradingItems.master
```

`FuGradeHelper.exe` and `FuGrade.dll` are produced by the .NET projects. `Newtonsoft.Json.dll` is required by the helper at runtime. `FinalThesisGradingItems.master` provides the final thesis grading component list used when a parsed `.fg` file does not include grading components.

## Build

From the repository root:

```powershell
dotnet build FuGradeHelper\FuGradeHelper.csproj -c Release
```

Copy the Release output into `fugrade_automation/assets/helper/` if it is not already there.

Then build or run the Flutter app:

```powershell
cd fugrade_automation
flutter pub get
flutter analyze
flutter run -d windows
```

For a Windows debug build:

```powershell
flutter build windows --debug
```

## FuGradeHelper Commands

```text
FuGradeHelper.exe parse-fg <path.fg>
FuGradeHelper.exe write-fg --input <path.fg> --grades-file <scores.json> --output <path.fg>
FuGradeHelper.exe write-cmt --data <json> --output <path.cmt>
FuGradeHelper.exe write-cmt --data-file <payload.json> --output <path.cmt>
FuGradeHelper.exe read-cmt <path.cmt>
FuGradeHelper.exe inspect-cmt <path.cmt>
```

### `parse-fg`

Parses a FuGrade `.fg` file and prints JSON to stdout. The parser supports raw JSON, AES/base64 FuGrade JSON payloads, and existing BinaryFormatter parsing paths.

When a final thesis group has no grading components in the `.fg` payload, the parser can enrich the output from:

```text
FuGradeHelper/MasterFile/FinalThesisGradingItems.master
```

### `write-fg`

Writes grading component scores into a supported FuGrade JSON/AES `.fg` file. The app uses this when saving scores from the CMT editor.

Grades file format:

```json
{
  "SE18D01": {
    "SE151222": {
      "Final Project Presentation": 8.5,
      "Final Report": 9.0
    },
    "SE151223": {
      "Final Project Presentation": 8.0
    }
  }
}
```

The top-level key is the class code. The second-level key is the student roll number. The innermost keys are FuGrade component names.

Current limitation: `write-fg` updates JSON/AES FuGrade payloads. BinaryFormatter `.fg` payloads are detected, but grade writing for that format is not implemented.

### `write-cmt`

Serializes a JSON thesis comment payload into a FuGrade-compatible `.cmt` binary file.

### `read-cmt`

Deserializes a `.cmt` file and prints readable JSON.

### `inspect-cmt`

Dumps type metadata from a `.cmt` file for debugging unknown or corrupted binary files.

## App Workflow

1. Open a FuGrade `.fg` file in the Flutter app.
2. Review parsed classes, groups, students, and grading components.
3. Sync Google Sheets if contribution data is maintained externally.
4. Edit CMT comments and student verdicts per group.
5. Enter contribution percentages manually or import them from the sheet.
6. Save grading component scores back to the original `.fg` file when needed.
7. Export `.cmt` files for FuGrade Editor.
8. Write FINAL-sheet data when sheet credentials and a target spreadsheet are configured.

## Google Sheets Notes

Contribution import accepts explicit contribution headers such as:

```text
Student roll number - % Contribution
```

Contribution paragraphs can use lines like:

```text
SE160015 - 50
SE160016 - 50
```

The FINAL-sheet writer discovers columns by header names, appends missing final headers when needed, and writes by row keys instead of fixed `A:R` offsets.

## Development Checks

Useful verification commands:

```powershell
dotnet build FuGradeHelper\FuGradeHelper.csproj -c Release
cd fugrade_automation
flutter analyze
flutter build windows --debug
```

The current Windows build may print non-fatal `file_picker` CMake metadata warnings depending on the local plugin cache.

## Notes

- The `.cmt` writer depends on `FuGradeTypes` building an assembly named `FuGrade`, because FuGrade Editor expects that assembly identity in serialized files.
- Keep helper binaries and master files in Flutter assets when packaging the app.
- Avoid renaming FuGrade grading components in app code. `write-fg` matches component names case-insensitively but relies on the original FuGrade component text.
