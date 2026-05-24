using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
using System.Security.Cryptography;
using System.Text;
using FuGrade;
using FuGradeHelper.Dtos;
using FuGradeHelper.Surrogates;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FuGradeHelper.Commands
{
    internal static class ParseFgCommand
    {
        private const string FgAesKey = "l10ca968o8e4133tyne2ea2315g19377";

        /// <summary>
        /// Exit codes: 0=success, 1=file not found, 2=parse error, 3=invalid format.
        /// On success writes JSON to stdout (UTF-8). On error writes message to stderr.
        /// </summary>
        public static int Run(string filePath)
        {
            if (!File.Exists(filePath))
            {
                Console.Error.WriteLine($"File not found: {filePath}");
                return 1;
            }

            try
            {
                var dto = Deserialize(filePath);
                var json = JsonConvert.SerializeObject(dto, Formatting.None);
                Console.OutputEncoding = Encoding.UTF8;
                Console.WriteLine(json);
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Parse error: {ex.Message}");
                if (ex.InnerException != null)
                    Console.Error.WriteLine($"  Inner: {ex.InnerException.Message}");
                return 2;
            }
        }

        private static int ValidateFileHeader(string filePath)
        {
            try
            {
                var header = new byte[40];
                using (var fs = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read))
                {
                    var read = fs.Read(header, 0, header.Length);
                    if (read < 2) return 3;

                    // BinaryFormatter magic: first byte is 0x00 (SerializedStreamHeader),
                    // second is 0x01 (version). Not all .NET versions write identical headers,
                    // so we check for the FuGradeLib marker string in the header region.
                    var headerStr = Encoding.ASCII.GetString(header, 0, read);
                    if (!headerStr.Contains("FuGradeLib") && header[0] != 0x00)
                    {
                        Console.Error.WriteLine("File does not appear to be a valid .fg file (missing FuGradeLib marker).");
                        return 3;
                    }
                }
                return 0;
            }
            catch (IOException ex)
            {
                Console.Error.WriteLine($"Cannot read file: {ex.Message}");
                return 2;
            }
        }

        private static TeacherGradeOutputDto Deserialize(string filePath)
        {
            var payload = OpenFgPayload(filePath);
            if (!string.IsNullOrWhiteSpace(payload.JsonText))
                return PopulateGradingComponentsFromMaster(MapJsonToDto(payload.JsonText));

            using (var stream = new MemoryStream(payload.BinaryBytes, writable: false))
            {
                var formatter = new BinaryFormatter
                {
                    Binder = new FgSerializationBinder()
                };

                var root = formatter.Deserialize(stream) as TeacherGradeSurrogate;
                if (root == null)
                    throw new InvalidDataException("Deserialized root object is not TeacherGrade.");

                return PopulateGradingComponentsFromMaster(MapToDto(root));
            }
        }

        private static TeacherGradeOutputDto PopulateGradingComponentsFromMaster(TeacherGradeOutputDto dto)
        {
            var master = TryLoadMasterFile();
            if (master == null)
                return dto;

            foreach (var grpDto in dto.Groups)
            {
                if (grpDto.GradingComponents.Count > 0)
                    continue;

                grpDto.GradingComponents.AddRange(
                    MasterFileReader.GetComponentNames(master, grpDto.Subject));
            }

            return dto;
        }

        private static List<FinalThesisGradingItem> TryLoadMasterFile()
        {
            var exeDir = AppDomain.CurrentDomain.BaseDirectory;
            var masterPath = Path.Combine(exeDir, "MasterFile", "FinalThesisGradingItems.master");
            if (!File.Exists(masterPath))
                return null;

            try
            {
                return MasterFileReader.Load(masterPath);
            }
            catch (Exception)
            {
                return null;
            }
        }

        private sealed class FgPayload
        {
            public byte[] BinaryBytes { get; set; }

            public string JsonText { get; set; }
        }

        private static FgPayload OpenFgPayload(string filePath)
        {
            var bytes = File.ReadAllBytes(filePath);
            if (bytes.Length == 0)
                throw new InvalidDataException("The .fg file is empty.");

            // Normal FuGrade files are BinaryFormatter streams and start with 0x00.
            if (bytes[0] == 0x00)
                return new FgPayload { BinaryBytes = bytes };

            // Some FuGrade files are text wrappers around the real payload.
            // Supported forms observed in FuGrade.exe:
            //   1) Base64(BinaryFormatter bytes)
            //   2) Base64(AES-CBC/PKCS7(UTF8(Base64(BinaryFormatter bytes))))
            //   3) Base64(AES-CBC/PKCS7(UTF8(JSON teacher grade data)))
            var text = Encoding.ASCII.GetString(bytes).Trim();
            if (TryDecodeBinaryPayload(text, out var decoded))
                return new FgPayload { BinaryBytes = decoded };

            if (TryDecryptFuGradeString(text, out var decryptedText))
            {
                var trimmed = decryptedText.Trim();
                if (LooksLikeJson(trimmed))
                    return new FgPayload { JsonText = trimmed };

                if (TryDecodeBinaryPayload(trimmed, out decoded))
                    return new FgPayload { BinaryBytes = decoded };
            }

            throw new InvalidDataException("File does not appear to be a valid .fg file. Expected a FuGrade binary stream, base64-encoded FuGrade stream, encrypted FuGrade stream, or encrypted FuGrade JSON.");
        }

        private static bool TryDecodeBinaryPayload(string text, out byte[] decoded)
        {
            decoded = null;
            try
            {
                var bytes = Convert.FromBase64String(text);
                if (bytes.Length > 0 && bytes[0] == 0x00)
                {
                    decoded = bytes;
                    return true;
                }
            }
            catch (FormatException)
            {
            }

            return false;
        }

        private static bool LooksLikeJson(string text)
        {
            return !string.IsNullOrWhiteSpace(text) && (text[0] == '{' || text[0] == '[');
        }

        private static bool TryDecryptFuGradeString(string encryptedBase64, out string decryptedText)
        {
            decryptedText = null;
            try
            {
                var cipherBytes = Convert.FromBase64String(encryptedBase64);
                using (var aes = Aes.Create())
                {
                    aes.Key = Encoding.UTF8.GetBytes(FgAesKey);
                    aes.IV = new byte[16];

                    using (var decryptor = aes.CreateDecryptor(aes.Key, aes.IV))
                    using (var input = new MemoryStream(cipherBytes))
                    using (var crypto = new CryptoStream(input, decryptor, CryptoStreamMode.Read))
                    using (var reader = new StreamReader(crypto))
                    {
                        decryptedText = reader.ReadToEnd();
                        return true;
                    }
                }
            }
            catch (FormatException)
            {
                return false;
            }
            catch (CryptographicException)
            {
                return false;
            }
            catch (IOException)
            {
                return false;
            }
        }

        private static TeacherGradeOutputDto MapJsonToDto(string json)
        {
            var root = JObject.Parse(json);
            var dto = new TeacherGradeOutputDto
            {
                Version = (string)root["Version"] ?? "",
                Semester = (string)root["Semester"] ?? "",
                Login = (string)root["Login"] ?? "",
            };

            foreach (var grp in root["SubjectClassGrades"]?.Children<JObject>() ?? Enumerable.Empty<JObject>())
            {
                var grpDto = new SubjectClassGradeOutputDto
                {
                    Subject = (string)grp["Subject"] ?? "",
                    ClassCode = (string)grp["Class"] ?? "",
                };

                var componentNames = new HashSet<string>();

                foreach (var s in grp["Students"]?.Children<JObject>() ?? Enumerable.Empty<JObject>())
                {
                    grpDto.Students.Add(new StudentOutputDto
                    {
                        Roll = (string)s["Roll"] ?? "",
                        Name = (string)s["Name"] ?? "",
                    });

                    foreach (var grade in s["Grades"]?.Children<JObject>() ?? Enumerable.Empty<JObject>())
                    {
                        var component = ((string)grade["Component"] ?? "").Trim();
                        if (!string.IsNullOrWhiteSpace(component))
                            componentNames.Add(component);
                    }
                }

                grpDto.GradingComponents.AddRange(componentNames);
                dto.Groups.Add(grpDto);
            }

            return dto;
        }

        private static TeacherGradeOutputDto MapToDto(TeacherGradeSurrogate root)
        {
            var dto = new TeacherGradeOutputDto
            {
                Version = root.Version ?? "",
                Semester = root.Semester ?? "",
                Login = root.Login ?? "",
            };

            foreach (var grp in root.SubjectClassGrades ?? new List<SubjectClassGradeSurrogate>())
            {
                // Only include capstone groups (subject ends in 490/491/493)
                // Non-capstone groups are still included so Flutter can decide; Flutter filters.
                var grpDto = new SubjectClassGradeOutputDto
                {
                    Subject = grp.Subject ?? "",
                    ClassCode = grp.ClassCode ?? "",
                };

                foreach (var s in grp.Students ?? new List<StudentSurrogate>())
                {
                    grpDto.Students.Add(new StudentOutputDto
                    {
                        Roll = s.Roll ?? "",
                        Name = s.Name ?? "",
                    });
                }

                foreach (var componentName in (grp.GradeComponents ?? new List<GradeComponentPlaceholder>())
                    .Select(c => (c?.Name ?? "").Trim())
                    .Where(name => !string.IsNullOrWhiteSpace(name))
                    .Distinct())
                {
                    grpDto.GradingComponents.Add(componentName);
                }

                dto.Groups.Add(grpDto);
            }

            return dto;
        }
    }
}
