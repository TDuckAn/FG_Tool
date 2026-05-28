# Critical Code Review Findings

## 1. Unsafe BinaryFormatter deserialization

The most serious issue is the use of `BinaryFormatter` on `.fg` and `.cmt` data in the helper. This appears in `FuGradeHelper/Commands/ParseFgCommand.cs` and `FuGradeHelper/Commands/ReadCmtCommand.cs`.

Why this is critical:
- `BinaryFormatter` is a high-risk deserialization mechanism with a long history of code execution vulnerabilities.
- The app accepts files from users, so malformed or malicious input is a realistic threat.
- A binder reduces the attack surface, but it does not remove the inherent risk of `BinaryFormatter`.

What to fix:
- Reject unexpected serialized types explicitly instead of returning `null` from the binder.
- Keep deserialization isolated in the helper process, but run that process with the minimum possible privileges.
- Add strict file-size limits and timeouts for helper execution.
- Prefer JSON parsing paths whenever compatible data is available.

## 2. Hard-coded crypto key and compatibility password values

The helper contains a hard-coded AES key in `FuGradeHelper/Commands/ParseFgCommand.cs` and `FuGradeHelper/Commands/WriteFgCommand.cs`, plus a hard-coded password hash in `FuGradeHelper/Commands/WriteCmtCommand.cs`.

Why this is critical:
- Secrets and security-related constants embedded in source are hard to rotate and easy to expose.
- Even if these values are required for compatibility with FuGrade, they should be treated as sensitive implementation details.

What to fix:
- Move compatibility constants to a configuration source or at least document them clearly as protocol constants.
- Keep them out of general-purpose code paths where possible.
- Ensure they are not reused for unrelated security decisions.

## 3. Large payloads are passed on the command line

`fugrade_automation/lib/data/datasources/cmt_writer_datasource.dart` currently passes JSON into the helper via `--data`.

Why this is critical:
- Windows command-line length limits can cause failures when the payload grows.
- This creates brittle behavior that will show up only for larger drafts or more student rows.

What to fix:
- Switch to `--data-file` and write the JSON to a temp file first.
- Reuse the same pattern already used by `writeFgGrades()`.

## 4. Tracked build artifacts and generated outputs

The repository had generated output under `FuGradeHelper/obj` and `FuGradeTypes/obj` tracked in Git.

Why this matters:
- These files change per machine and per build.
- They create noisy diffs and make collaboration harder.
- They can hide real source changes in reviews.

What to fix:
- Keep `**/bin/`, `**/obj/`, `**/build/`, `**/.dart_tool/`, and `**/.vs/` in `.gitignore`.
- Remove any already tracked generated files from the Git index.

## 5. Missing operational safeguards around helper execution

The Flutter app launches the helper process directly from `Process.run()` in `fugrade_automation/lib/data/datasources/fg_parser_datasource.dart` and `cmt_writer_datasource.dart`.

Why this is critical:
- A hung or slow helper will block the UX.
- There are no visible timeouts in the current process calls.
- A malformed input file could stall the workflow.

What to fix:
- Add explicit timeouts and kill logic for helper invocations.
- Capture stderr/stdout separately and surface failures in a consistent way.
- Prefer streamed process handling for larger or long-running operations.

## Immediate priority order

1. Harden deserialization and reject unknown types.
2. Switch `write-cmt` payload handling to temp-file input.
3. Add process timeouts and kill behavior in Flutter.
4. Review hard-coded compatibility constants and document or externalize them.
5. Keep generated outputs untracked.

## Notes

This file intentionally lists the highest-risk problems first. A full production review would also cover architecture, UI quality, test coverage, and maintainability, but the issues above are the ones most likely to cause security, runtime, or collaboration problems first.
