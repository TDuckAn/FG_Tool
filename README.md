# FG Tool — FuGrade Automation Suite

Bộ công cụ tự động hóa quy trình chấm điểm FuGrade dành cho giảng viên FPT University.
Automates FuGrade grading workflows for FPT University instructors.

![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078d4?logo=windows)
![Flutter](https://img.shields.io/badge/Flutter-Windows%20Desktop-02569B?logo=flutter)
![.NET](https://img.shields.io/badge/.NET%20Framework-4.8-512BD4?logo=dotnet)

---

## Giới thiệu · Overview

**VI** — FG Tool gồm hai thành phần: ứng dụng desktop Flutter (Windows) và CLI helper .NET. Ứng dụng đọc file `.fg`, điền nhận xét khóa luận, đồng bộ dữ liệu đóng góp từ Google Sheets và xuất file `.cmt` cho FuGrade Editor.

**EN** — FG Tool is a Flutter Windows desktop app paired with a .NET CLI helper. It parses `.fg` exports, fills thesis comment drafts, syncs contribution data with Google Sheets, and writes `.cmt` files for FuGrade Editor.

---

## Tính năng · Features

| Tính năng · Feature | Mô tả · Description |
| --- | --- |
| 📂 Đọc file `.fg` | Phân tích export FuGrade — hỗ trợ binary, base64 và AES/JSON |
| 📋 Thành phần chấm điểm | Nạp từ `FinalThesisGradingItems.master` khi file `.fg` thiếu dữ liệu |
| ✏️ Soạn nhận xét `.cmt` | Giao diện Flutter cho nhận xét và quyết định bảo vệ từng nhóm |
| 📄 Xuất file `.cmt` | Ghi file nhị phân tương thích FuGrade Editor |
| 🔗 Đồng bộ Google Sheets | Đọc dữ liệu đóng góp, ghép nhóm/sinh viên từ response sheet |
| 📊 Ghi FINAL sheet | Lưu dữ liệu theo cột header (không theo vị trí cố định), ghi đóng góp dạng đoạn văn lẫn JSON |
| 💯 Ghi điểm về `.fg` | Ghi điểm thành phần vào file `.fg` định dạng JSON/AES |

---

## Cấu trúc dự án · Repository Layout

```text
FG_Tool/
├── fugrade_automation/          Flutter Windows desktop app
│   ├── assets/helper/           FuGradeHelper.exe, DLL, master files
│   └── lib/
│       ├── core/                Theme, utils, constants
│       ├── data/                Models, datasources (Sheets, CMT, storage)
│       ├── domain/              Matching & contribution merge services
│       └── presentation/        BLoC, screens (Home, GroupList, CmtEditor)
├── FuGradeHelper/               .NET 4.8 CLI bridge
│   ├── Commands/                parse-fg, write-fg, read-cmt, write-cmt, inspect-cmt
│   ├── Dtos/                    JSON DTOs
│   └── Surrogates/              BinaryFormatter surrogate + binder
├── FuGradeTypes/                Assembly "FuGrade" — CMT-compatible types
└── README.md
```

Flutter gọi `FuGradeHelper.exe` như một subprocess. Helper xử lý định dạng FuGrade và trả về JSON cho ứng dụng Dart.

The Flutter app runs `FuGradeHelper.exe` as a subprocess. The helper handles FuGrade-specific formats and returns JSON to Dart.

---

## Yêu cầu · Requirements

- **OS:** Windows 10 / 11
- **Flutter SDK** — phiên bản tương thích với `fugrade_automation/pubspec.yaml`
- **.NET Framework 4.8** — qua Visual Studio hoặc `dotnet` CLI
- **Google service account** — cho tích hợp Google Sheets
- **Helper assets** — xem mục [Helper Assets](#helper-assets) bên dưới

---

## Helper Assets

Ứng dụng Flutter cần các file sau trong `fugrade_automation/assets/helper/`:

```text
FuGradeHelper.exe
FuGrade.dll
Newtonsoft.Json.dll
MasterFile/
└── FinalThesisGradingItems.master
```

`FuGradeHelper.exe` và `FuGrade.dll` được build từ các project .NET. `FinalThesisGradingItems.master` cung cấp danh sách thành phần chấm điểm khi file `.fg` không có dữ liệu này.

---

## Build & Chạy · Build & Run

**Bước 1 — Build helper .NET:**

```powershell
dotnet build FuGradeHelper\FuGradeHelper.csproj -c Release
```

Copy kết quả Release vào `fugrade_automation/assets/helper/` nếu chưa có.

**Bước 2 — Chạy Flutter app:**

```powershell
cd fugrade_automation
flutter pub get
flutter analyze
flutter run -d windows
```

**Build debug Windows:**

```powershell
flutter build windows --debug
```

---

## CLI Reference — FuGradeHelper.exe

```text
FuGradeHelper.exe parse-fg    <path.fg>
FuGradeHelper.exe write-fg    --input <path.fg> --grades-file <scores.json> --output <path.fg>
FuGradeHelper.exe write-cmt   --data <json>               --output <path.cmt>
FuGradeHelper.exe write-cmt   --data-file <payload.json>  --output <path.cmt>
FuGradeHelper.exe read-cmt    <path.cmt>
FuGradeHelper.exe inspect-cmt <path.cmt>
```

### parse-fg — Đọc file .fg

Phân tích file `.fg` và in JSON ra stdout. Hỗ trợ ba định dạng:

- Raw BinaryFormatter stream
- Base64-encoded binary stream
- AES-CBC/PKCS7 encrypted JSON payload

Khi nhóm khóa luận không có thành phần chấm điểm trong file `.fg`, parser tự động nạp bổ sung từ `FinalThesisGradingItems.master`.

### write-fg — Ghi điểm vào .fg

Ghi điểm thành phần vào file `.fg` định dạng JSON/AES. Định dạng file điểm (`--grades-file`):

```json
{
  "SP24SE081_GSP43": {
    "SE151222": {
      "Final Project Presentation": 8.5,
      "Final Report": 9.0
    }
  }
}
```

> **Lưu ý:** Hiện chỉ hỗ trợ `.fg` dạng JSON/AES. File BinaryFormatter được nhận dạng nhưng chưa hỗ trợ ghi điểm.

### write-cmt — Xuất file .cmt

Serialize payload JSON nhận xét khóa luận thành file `.cmt` nhị phân tương thích FuGrade Editor. Dùng `--data-file` cho payload lớn để tránh giới hạn độ dài lệnh Windows.

### read-cmt / inspect-cmt

- `read-cmt` — Deserialize file `.cmt` và in JSON có thể đọc được.
- `inspect-cmt` — Dump metadata kiểu dữ liệu từ file `.cmt` để debug.

---

## Quy trình làm việc · Workflow

```text
1. Mở file .fg  ──►  2. Xem nhóm / sinh viên / thành phần chấm điểm
                              │
                              ▼
                    3. Đồng bộ Google Sheets (nếu có)
                              │
                              ▼
                    4. Soạn nhận xét & quyết định bảo vệ từng nhóm
                              │
                         ┌────┴────┐
                         ▼         ▼
              5. Nhập % đóng góp   6. Nhập điểm thành phần
                 (sheet / thủ công)    (lưu về file .fg)
                         │
                         ▼
              7. Xuất file .cmt  ──►  FuGrade Editor
                         │
                         ▼
              8. Ghi FINAL sheet  ──►  Google Sheets
```

---

## Google Sheets

### Cột đóng góp · Contribution column

Ứng dụng nhận dạng cột đóng góp qua các tên header phổ biến (không phân biệt hoa thường):

```text
Student roll number - % Contribution, e.g. SE160015 - 50
contributions / member contributions / đóng góp thành viên
```

Dữ liệu mỗi dòng một sinh viên:

```text
SE160015 - 50
SE160016 - 30
SE160017 - 20
```

### Ghi FINAL sheet

- Tìm cột theo **tên header**, không theo vị trí cố định A:R.
- Tự thêm cột còn thiếu vào cuối — không ghi đè cột của Google Form.
- Ghi đóng góp dưới **hai dạng**: đoạn văn (human-readable) + JSON (để đọc lại cấu trúc).

---

## Lưu ý phát triển · Dev Notes

Kiểm tra sau khi sửa code:

```powershell
# Sau khi sửa C#
dotnet build FuGradeHelper\FuGradeHelper.csproj -c Release

# Sau khi sửa Dart model
cd fugrade_automation
dart run build_runner build --delete-conflicting-outputs

# Kiểm tra Flutter
flutter analyze
flutter build windows --debug
```

Build Windows có thể in cảnh báo CMake từ plugin `file_picker` — không ảnh hưởng đến chức năng.

### Những điều cần chú ý · Important constraints

- `FuGradeTypes` **phải** build thành assembly tên `FuGrade` — FuGrade Editor nhận dạng assembly identity này trong file `.cmt`.
- Không đổi tên thuộc tính serialized trong `ThesisComment` / `ThesisStudent` khi chưa kiểm tra với FuGrade binary.
- Dùng `--data-file` thay vì `--data` cho payload CMT lớn (giới hạn độ dài lệnh Windows).
- Không commit build output từ `bin/`, `obj/`, `.dart_tool/`, `build/`.
