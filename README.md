<div align="center">

# 🎓 FG Tool — FuGrade Automation Suite

**English** | [Tiếng Việt](#tiếng-việt)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![.NET](https://img.shields.io/badge/.NET-4.8-512BD4?logo=dotnet)](https://dotnet.microsoft.com)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D4?logo=windows)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

*Automate `.cmt` file creation for FPT University's FuGrade grading system.*

</div>

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Components](#components)
  - [fugrade\_automation (Flutter GUI)](#fugrade_automation-flutter-gui)
  - [FuGradeHelper (.NET CLI)](#fugradehelper-net-cli)
  - [FuGradeTypes (.NET Library)](#fugradtypes-net-library)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Contributing](#contributing)

---

## Overview

**FG Tool** is a two-component desktop suite built for FPT University instructors to streamline the grading workflow of capstone / thesis subjects inside **FuGrade Editor**.

| Pain Point | Solution |
|---|---|
| Manually filling `.cmt` binary files for every student group | Flutter GUI auto-generates `.cmt` files in bulk |
| Reading/inspecting opaque `.fg` and `.cmt` binary formats | .NET CLI parses and dumps them as JSON |
| Pulling student contribution data from spreadsheets | Google Sheets API integration syncs data automatically |
| Matching `.fg` grade records to sheet rows | Smart fuzzy-matching service handles name/roll variations |

---

## Architecture

```
FG_Tool/
├── fugrade_automation/        # Flutter Windows desktop application (GUI)
│   └── lib/
│       ├── core/              # Theme, constants, utilities
│       ├── data/              # Data sources + JSON models
│       ├── domain/            # Business logic services
│       └── presentation/      # BLoC state management + screens
│
├── FuGradeHelper/             # .NET 4.8 CLI helper (binary format bridge)
│   ├── Commands/              # parse-fg, write-cmt, read-cmt, inspect-cmt
│   ├── Dtos/                  # Input/output data transfer objects
│   └── Surrogates/            # BinaryFormatter serialization helpers
│
└── FuGradeTypes/              # .NET 4.8 shared library
    └── ThesisTypes.cs         # ThesisComment & ThesisStudent types
```

The Flutter app spawns **FuGradeHelper.exe** as a subprocess to bridge between the Dart world and the proprietary `.fg`/`.cmt` binary formats that FuGrade Editor uses internally.

---

## Components

### fugrade\_automation (Flutter GUI)

A Flutter **Windows desktop** application that provides the full end-to-end grading workflow:

#### Key Features

- **Load `.fg` files** — parse FuGrade binary grade exports via the CLI bridge
- **Sync Google Sheets** — pull student contribution percentages from a shared spreadsheet using a service-account credential
- **Smart Matching** — fuzzy-match sheet rows against `.fg` student records (handles name/roll inconsistencies)
- **CMT Editor** — review and manually adjust auto-filled thesis comment fields per group
- **Bulk Export** — generate `.cmt` binary files for all groups in one click
- **Scholarly Modernism UI** — warm paper-toned Material 3 theme with Windows system fonts (Cambria, Bahnschrift, Cascadia Mono)

#### Screen Flow

```
HomeScreen
  ├── FgLoaderBloc   → loads & parses .fg file
  ├── SheetSyncBloc  → syncs Google Sheets data
  └── GroupListScreen
        └── CmtEditorScreen  (per group)
              └── ExportScreen → writes .cmt files
```

#### State Management (BLoC)

| BLoC | Responsibility |
|---|---|
| `FgLoaderBloc` | File picking, `.fg` parsing, version detection |
| `SheetSyncBloc` | Google Sheets API fetch, row matching |
| `CmtEditorBloc` | Per-group editor state, field validation |
| `ExportBloc` | CMT file generation, output path management |

---

### FuGradeHelper (.NET CLI)

A **.NET Framework 4.8** console application that acts as the binary format bridge. The Flutter app communicates with it via `stdin`/`stdout` using JSON.

#### Commands

```
FuGradeHelper.exe <command> [options]

Commands:
  parse-fg <path.fg>
      Parse a FuGrade .fg binary file and output grade data as JSON to stdout.

  write-cmt --data <json> --output <path.cmt>
      Serialize a JSON thesis comment payload into a .cmt binary file.
      Accepts --data-file <path> as an alternative to inline --data.

  read-cmt <path.cmt>
      Deserialize a .cmt binary file and print its content as JSON.

  inspect-cmt <path.cmt>
      Dump raw type metadata from a .cmt binary (useful for debugging
      unknown/corrupted files without full deserialization).
```

#### Design Notes

- Uses `BinaryFormatter` with custom `SerializationBinder` surrogates so the assembly identity (`FuGrade`) matches exactly what FuGrade.exe expects
- `FgSerializationBinder` redirects `.fg` types to local surrogate classes for safe deserialization
- `InspectCmtCommand` uses a `DumpBinder` that intercepts type resolution and captures metadata without needing the original assemblies

---

### FuGradeTypes (.NET Library)

A minimal **.NET Framework 4.8** class library whose sole purpose is to define the serializable types with the **exact assembly identity** (`AssemblyName=FuGrade`) that FuGrade.exe embeds in `.cmt` files.

```csharp
[Serializable]
public class ThesisComment   // top-level .cmt object
[Serializable]
public class ThesisStudent   // per-student verdict record
```

> **Why a separate project?** `BinaryFormatter` encodes the assembly name in every type reference. By naming the output assembly `FuGrade` (via `<AssemblyName>FuGrade</AssemblyName>`) the generated `.cmt` files are accepted by the original FuGrade Editor without modification.

---

## Prerequisites

### Flutter App

| Requirement | Version |
|---|---|
| Flutter SDK | `^3.11.5` (Dart `^3.11.5`) |
| Target Platform | Windows 10/11 (64-bit) |
| Google Service Account JSON | Required for Sheets integration |

### .NET Helper

| Requirement | Version |
|---|---|
| .NET Framework | 4.8 |
| Build Toolchain | `dotnet` CLI or Visual Studio 2022+ |

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/TDuckAn/FG_Tool.git
cd FG_Tool
```

### 2. Build FuGradeHelper

```bash
cd FuGradeHelper
dotnet build -c Release
```

The output `FuGradeHelper.exe` will be in `FuGradeHelper/bin/Release/net48/`.  
Place (or configure the path to) this executable inside `fugrade_automation/assets/helper/`.

### 3. Set Up the Flutter App

```bash
cd fugrade_automation
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configure Google Sheets Credentials

Place your Google service-account JSON key file in the assets folder and configure the sheet ID in the app settings on first run.

### 5. Run the App

```bash
flutter run -d windows
```

Or build a release executable:

```bash
flutter build windows --release
```

---

## Project Structure

```
fugrade_automation/lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_strings.dart          # UI string constants
│   │   ├── capstone_subjects.dart    # Known capstone subject codes
│   │   └── cmt_password.dart        # Default CMT password config
│   ├── theme/
│   │   └── app_theme.dart           # Scholarly Modernism theme + widgets
│   └── utils/
│       ├── app_logger.dart
│       ├── file_utils.dart
│       ├── roll_utils.dart           # Student roll number normalization
│       ├── semester_utils.dart       # Semester code parsing
│       └── version_utils.dart
├── data/
│   ├── datasources/
│   │   ├── cmt_writer_datasource.dart    # Calls FuGradeHelper write-cmt
│   │   ├── fg_parser_datasource.dart     # Calls FuGradeHelper parse-fg
│   │   ├── local_storage_datasource.dart # App preferences persistence
│   │   └── sheets_api_datasource.dart    # Google Sheets API v4
│   └── models/                           # JSON-serializable DTOs (json_serializable)
│       ├── cmt_draft_dto.dart
│       ├── member_contribution_dto.dart
│       ├── sheet_row_dto.dart
│       ├── student_decision_dto.dart
│       ├── student_dto.dart
│       ├── subject_class_grade_dto.dart
│       └── teacher_grade_dto.dart
├── domain/
│   └── services/
│       ├── contribution_merge_service.dart   # Merge sheet percentages into grade data
│       └── matching_service.dart             # Fuzzy name/roll matching
└── presentation/
    ├── blocs/
    │   ├── cmt_editor/cmt_editor_bloc.dart
    │   ├── export/export_bloc.dart
    │   ├── fg_loader/fg_loader_bloc.dart
    │   └── sheet_sync/sheet_sync_bloc.dart
    └── screens/
        ├── cmt_editor_screen.dart
        ├── export_screen.dart
        ├── group_list_screen.dart
        └── home_screen.dart
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| GUI Framework | Flutter 3.x (Windows desktop) |
| State Management | flutter\_bloc 9.x + equatable |
| API Integration | googleapis 14.x + googleapis\_auth 1.x |
| Code Generation | json\_serializable + build\_runner |
| File Picker | file\_picker 5.x |
| Binary Bridge | .NET Framework 4.8 (BinaryFormatter) |
| Serialization | Newtonsoft.Json 13.x |
| Theme | Material 3 — "Scholarly Modernism" |

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

---

<div align="center">

# Tiếng Việt

[English](#-fg-tool--fugrade-automation-suite) | **Tiếng Việt**

</div>

---

## Mục Lục

- [Tổng Quan](#tổng-quan)
- [Kiến Trúc](#kiến-trúc)
- [Các Thành Phần](#các-thành-phần)
  - [fugrade\_automation (Giao Diện Flutter)](#fugrade_automation-giao-diện-flutter)
  - [FuGradeHelper (CLI .NET)](#fugradehelper-cli-net)
  - [FuGradeTypes (Thư Viện .NET)](#fugradtypes-thư-viện-net)
- [Yêu Cầu Hệ Thống](#yêu-cầu-hệ-thống)
- [Hướng Dẫn Cài Đặt](#hướng-dẫn-cài-đặt)
- [Cấu Trúc Dự Án](#cấu-trúc-dự-án)
- [Công Nghệ Sử Dụng](#công-nghệ-sử-dụng)

---

## Tổng Quan

**FG Tool** là bộ ứng dụng desktop gồm hai thành phần, được xây dựng dành cho giảng viên Trường Đại học FPT nhằm tự động hóa quy trình chấm điểm các môn đồ án / khóa luận trong **FuGrade Editor**.

| Vấn Đề | Giải Pháp |
|---|---|
| Phải điền thủ công file `.cmt` nhị phân cho từng nhóm sinh viên | Giao diện Flutter tự động tạo hàng loạt file `.cmt` |
| Định dạng nhị phân `.fg` và `.cmt` khó đọc, khó kiểm tra | CLI .NET phân tích và xuất ra JSON dễ đọc |
| Lấy dữ liệu đóng góp sinh viên từ bảng tính | Tích hợp Google Sheets API đồng bộ dữ liệu tự động |
| Khớp bản ghi điểm `.fg` với dữ liệu bảng tính | Dịch vụ so khớp thông minh xử lý sai lệch tên/mã số |

---

## Kiến Trúc

```
FG_Tool/
├── fugrade_automation/        # Ứng dụng Flutter Windows (giao diện đồ họa)
│   └── lib/
│       ├── core/              # Giao diện, hằng số, tiện ích
│       ├── data/              # Nguồn dữ liệu + mô hình JSON
│       ├── domain/            # Dịch vụ nghiệp vụ
│       └── presentation/      # Quản lý trạng thái BLoC + màn hình
│
├── FuGradeHelper/             # CLI .NET 4.8 (cầu nối định dạng nhị phân)
│   ├── Commands/              # parse-fg, write-cmt, read-cmt, inspect-cmt
│   ├── Dtos/                  # Đối tượng truyền dữ liệu vào/ra
│   └── Surrogates/            # Trình hỗ trợ tuần tự hóa BinaryFormatter
│
└── FuGradeTypes/              # Thư viện .NET 4.8 dùng chung
    └── ThesisTypes.cs         # Kiểu ThesisComment & ThesisStudent
```

Ứng dụng Flutter khởi chạy **FuGradeHelper.exe** như một tiến trình con để kết nối giữa thế giới Dart và các định dạng nhị phân độc quyền `.fg`/`.cmt` mà FuGrade Editor sử dụng nội bộ.

---

## Các Thành Phần

### fugrade\_automation (Giao Diện Flutter)

Ứng dụng **Windows desktop** Flutter cung cấp toàn bộ quy trình chấm điểm từ đầu đến cuối:

#### Tính Năng Chính

- **Tải file `.fg`** — phân tích file xuất điểm nhị phân FuGrade thông qua cầu nối CLI
- **Đồng bộ Google Sheets** — lấy tỷ lệ đóng góp của sinh viên từ bảng tính chia sẻ bằng tài khoản dịch vụ
- **So Khớp Thông Minh** — so khớp mờ hàng bảng tính với bản ghi sinh viên trong file `.fg` (xử lý sai lệch tên/mã số)
- **Trình Chỉnh Sửa CMT** — xem xét và điều chỉnh thủ công các trường nhận xét đề tài đã điền tự động cho từng nhóm
- **Xuất Hàng Loạt** — tạo file `.cmt` nhị phân cho tất cả nhóm chỉ với một cú nhấp chuột
- **Giao Diện Scholarly Modernism** — chủ đề Material 3 tông màu giấy ấm với font hệ thống Windows (Cambria, Bahnschrift, Cascadia Mono)

#### Luồng Màn Hình

```
HomeScreen (Màn hình chính)
  ├── FgLoaderBloc   → tải và phân tích file .fg
  ├── SheetSyncBloc  → đồng bộ dữ liệu Google Sheets
  └── GroupListScreen (Danh sách nhóm)
        └── CmtEditorScreen (Chỉnh sửa CMT - từng nhóm)
              └── ExportScreen → ghi file .cmt
```

#### Quản Lý Trạng Thái (BLoC)

| BLoC | Trách Nhiệm |
|---|---|
| `FgLoaderBloc` | Chọn file, phân tích `.fg`, phát hiện phiên bản |
| `SheetSyncBloc` | Lấy dữ liệu Google Sheets API, so khớp hàng |
| `CmtEditorBloc` | Trạng thái trình chỉnh sửa từng nhóm, kiểm tra trường dữ liệu |
| `ExportBloc` | Tạo file CMT, quản lý đường dẫn đầu ra |

---

### FuGradeHelper (CLI .NET)

Ứng dụng console **.NET Framework 4.8** đóng vai trò cầu nối định dạng nhị phân. Ứng dụng Flutter giao tiếp với nó qua `stdin`/`stdout` bằng JSON.

#### Các Lệnh

```
FuGradeHelper.exe <lệnh> [tùy chọn]

Lệnh:
  parse-fg <đường-dẫn.fg>
      Phân tích file nhị phân FuGrade .fg và xuất dữ liệu điểm dưới dạng JSON ra stdout.

  write-cmt --data <json> --output <đường-dẫn.cmt>
      Tuần tự hóa payload nhận xét đề tài JSON thành file nhị phân .cmt.
      Chấp nhận --data-file <đường-dẫn> thay thế cho --data nội tuyến.

  read-cmt <đường-dẫn.cmt>
      Giải tuần tự hóa file nhị phân .cmt và in nội dung dưới dạng JSON.

  inspect-cmt <đường-dẫn.cmt>
      Xuất metadata kiểu thô từ file .cmt nhị phân (hữu ích để gỡ lỗi
      các file không rõ/bị hỏng mà không cần giải tuần tự hóa đầy đủ).
```

#### Ghi Chú Thiết Kế

- Sử dụng `BinaryFormatter` với các surrogate `SerializationBinder` tùy chỉnh để danh tính assembly (`FuGrade`) khớp chính xác với những gì FuGrade.exe mong đợi
- `FgSerializationBinder` chuyển hướng các kiểu `.fg` sang các lớp surrogate cục bộ để giải tuần tự hóa an toàn
- `InspectCmtCommand` dùng `DumpBinder` chặn quá trình phân giải kiểu và thu thập metadata mà không cần các assembly gốc

---

### FuGradeTypes (Thư Viện .NET)

Thư viện lớp **.NET Framework 4.8** tối giản với mục đích duy nhất là định nghĩa các kiểu có thể tuần tự hóa với **danh tính assembly chính xác** (`AssemblyName=FuGrade`) mà FuGrade.exe nhúng trong các file `.cmt`.

```csharp
[Serializable]
public class ThesisComment   // đối tượng .cmt cấp cao nhất
[Serializable]
public class ThesisStudent   // bản ghi kết quả từng sinh viên
```

> **Tại sao cần project riêng?** `BinaryFormatter` mã hóa tên assembly trong mỗi tham chiếu kiểu. Bằng cách đặt tên assembly đầu ra là `FuGrade` (qua `<AssemblyName>FuGrade</AssemblyName>`), các file `.cmt` được tạo ra sẽ được FuGrade Editor gốc chấp nhận mà không cần sửa đổi.

---

## Yêu Cầu Hệ Thống

### Ứng Dụng Flutter

| Yêu Cầu | Phiên Bản |
|---|---|
| Flutter SDK | `^3.11.5` (Dart `^3.11.5`) |
| Nền Tảng Mục Tiêu | Windows 10/11 (64-bit) |
| JSON Tài Khoản Dịch Vụ Google | Bắt buộc để tích hợp Sheets |

### .NET Helper

| Yêu Cầu | Phiên Bản |
|---|---|
| .NET Framework | 4.8 |
| Công Cụ Build | CLI `dotnet` hoặc Visual Studio 2022+ |

---

## Hướng Dẫn Cài Đặt

### 1. Clone Repository

```bash
git clone https://github.com/TDuckAn/FG_Tool.git
cd FG_Tool
```

### 2. Build FuGradeHelper

```bash
cd FuGradeHelper
dotnet build -c Release
```

File `FuGradeHelper.exe` đầu ra sẽ nằm trong `FuGradeHelper/bin/Release/net48/`.  
Đặt (hoặc cấu hình đường dẫn đến) file thực thi này vào `fugrade_automation/assets/helper/`.

### 3. Thiết Lập Ứng Dụng Flutter

```bash
cd fugrade_automation
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Cấu Hình Thông Tin Xác Thực Google Sheets

Đặt file JSON khóa tài khoản dịch vụ Google vào thư mục assets và cấu hình sheet ID trong cài đặt ứng dụng lần đầu chạy.

### 5. Chạy Ứng Dụng

```bash
flutter run -d windows
```

Hoặc build file thực thi release:

```bash
flutter build windows --release
```

---

## Cấu Trúc Dự Án

```
fugrade_automation/lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_strings.dart          # Hằng số chuỗi giao diện
│   │   ├── capstone_subjects.dart    # Mã môn đồ án đã biết
│   │   └── cmt_password.dart        # Cấu hình mật khẩu CMT mặc định
│   ├── theme/
│   │   └── app_theme.dart           # Chủ đề Scholarly Modernism + widget
│   └── utils/
│       ├── app_logger.dart
│       ├── file_utils.dart
│       ├── roll_utils.dart           # Chuẩn hóa mã số sinh viên
│       ├── semester_utils.dart       # Phân tích mã học kỳ
│       └── version_utils.dart
├── data/
│   ├── datasources/
│   │   ├── cmt_writer_datasource.dart    # Gọi FuGradeHelper write-cmt
│   │   ├── fg_parser_datasource.dart     # Gọi FuGradeHelper parse-fg
│   │   ├── local_storage_datasource.dart # Lưu trữ tùy chỉnh ứng dụng
│   │   └── sheets_api_datasource.dart    # Google Sheets API v4
│   └── models/                           # DTO có thể tuần tự hóa JSON
│       ├── cmt_draft_dto.dart
│       ├── member_contribution_dto.dart
│       ├── sheet_row_dto.dart
│       ├── student_decision_dto.dart
│       ├── student_dto.dart
│       ├── subject_class_grade_dto.dart
│       └── teacher_grade_dto.dart
├── domain/
│   └── services/
│       ├── contribution_merge_service.dart   # Gộp tỷ lệ đóng góp vào dữ liệu điểm
│       └── matching_service.dart             # So khớp mờ tên/mã số
└── presentation/
    ├── blocs/
    │   ├── cmt_editor/cmt_editor_bloc.dart
    │   ├── export/export_bloc.dart
    │   ├── fg_loader/fg_loader_bloc.dart
    │   └── sheet_sync/sheet_sync_bloc.dart
    └── screens/
        ├── cmt_editor_screen.dart
        ├── export_screen.dart
        ├── group_list_screen.dart
        └── home_screen.dart
```

---

## Công Nghệ Sử Dụng

| Tầng | Công Nghệ |
|---|---|
| Framework Giao Diện | Flutter 3.x (Windows desktop) |
| Quản Lý Trạng Thái | flutter\_bloc 9.x + equatable |
| Tích Hợp API | googleapis 14.x + googleapis\_auth 1.x |
| Sinh Mã | json\_serializable + build\_runner |
| Chọn File | file\_picker 5.x |
| Cầu Nối Nhị Phân | .NET Framework 4.8 (BinaryFormatter) |
| Tuần Tự Hóa | Newtonsoft.Json 13.x |
| Giao Diện | Material 3 — "Scholarly Modernism" |

---

<div align="center">

Made with ❤️ for FPT University instructors

</div>