using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FuGradeHelper.Commands
{
    internal static class WriteFgCommand
    {
        private const string FgAesKey = "l10ca968o8e4133tyne2ea2315g19377";

        public static int Run(string inputPath, string gradesFilePath, string outputPath)
        {
            if (string.IsNullOrWhiteSpace(inputPath) ||
                string.IsNullOrWhiteSpace(gradesFilePath) ||
                string.IsNullOrWhiteSpace(outputPath))
            {
                Console.Error.WriteLine("Usage: FuGradeHelper.exe write-fg --input <path.fg> --grades-file <scores.json> --output <path.fg>");
                return 1;
            }

            if (!File.Exists(inputPath))
            {
                Console.Error.WriteLine($"Input .fg file not found: {inputPath}");
                return 1;
            }

            if (!File.Exists(gradesFilePath))
            {
                Console.Error.WriteLine($"Grades file not found: {gradesFilePath}");
                return 1;
            }

            try
            {
                var payload = OpenPayload(inputPath);
                if (string.IsNullOrWhiteSpace(payload.JsonText))
                    throw new InvalidDataException("write-fg currently supports FuGrade JSON payloads. This file is a BinaryFormatter payload.");

                var root = JObject.Parse(payload.JsonText);
                var grades = LoadGrades(gradesFilePath);
                var updatedCount = ApplyGrades(root, grades);
                if (updatedCount == 0)
                    Console.Error.WriteLine("Warning: no matching grade rows were updated.");

                var json = root.ToString(Formatting.None);
                var bytes = payload.WasEncrypted
                    ? EncryptText(json)
                    : Encoding.UTF8.GetBytes(json);

                WriteAllBytesAtomic(outputPath, bytes);
                Console.Error.WriteLine($"Updated {updatedCount} grade value(s).");
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"write-fg error: {ex.Message}");
                if (ex.InnerException != null)
                    Console.Error.WriteLine($"  Inner: {ex.InnerException.Message}");
                return 2;
            }
        }

        private static Dictionary<string, Dictionary<string, Dictionary<string, double>>> LoadGrades(string path)
        {
            var json = File.ReadAllText(path, Encoding.UTF8);
            return JsonConvert.DeserializeObject<Dictionary<string, Dictionary<string, Dictionary<string, double>>>>(json)
                   ?? new Dictionary<string, Dictionary<string, Dictionary<string, double>>>();
        }

        private static int ApplyGrades(
            JObject root,
            Dictionary<string, Dictionary<string, Dictionary<string, double>>> grades)
        {
            var updated = 0;
            foreach (var group in root["SubjectClassGrades"]?.Children<JObject>() ?? Enumerable.Empty<JObject>())
            {
                var classCode = ((string)group["Class"] ?? (string)group["ClassCode"] ?? "").Trim();
                if (string.IsNullOrWhiteSpace(classCode) ||
                    !grades.TryGetValue(classCode, out var classGrades))
                    continue;

                foreach (var student in group["Students"]?.Children<JObject>() ?? Enumerable.Empty<JObject>())
                {
                    var roll = ((string)student["Roll"] ?? "").Trim();
                    if (string.IsNullOrWhiteSpace(roll) ||
                        !classGrades.TryGetValue(roll, out var studentGrades))
                        continue;

                    var gradeArray = student["Grades"] as JArray;
                    if (gradeArray == null)
                    {
                        gradeArray = new JArray();
                        student["Grades"] = gradeArray;
                    }

                    foreach (var componentScore in studentGrades)
                    {
                        var component = componentScore.Key.Trim();
                        if (string.IsNullOrWhiteSpace(component))
                            continue;

                        var grade = FindGradeObject(gradeArray, component);
                        if (grade == null)
                        {
                            grade = new JObject
                            {
                                ["Component"] = component,
                                ["Grade"] = null
                            };
                            gradeArray.Add(grade);
                        }

                        grade["Grade"] = JToken.FromObject(componentScore.Value);
                        updated++;
                    }
                }
            }

            return updated;
        }

        private static JObject FindGradeObject(JArray grades, string component)
        {
            foreach (var grade in grades.Children<JObject>())
            {
                var existing = ((string)grade["Component"] ?? "").Trim();
                if (string.Equals(existing, component, StringComparison.OrdinalIgnoreCase))
                    return grade;
            }

            return null;
        }

        private static FgPayload OpenPayload(string path)
        {
            var bytes = File.ReadAllBytes(path);
            if (bytes.Length == 0)
                throw new InvalidDataException("The .fg file is empty.");

            if (bytes[0] == 0x00)
                return new FgPayload { BinaryBytes = bytes };

            var text = Encoding.UTF8.GetString(bytes).Trim();
            if (LooksLikeJson(text))
                return new FgPayload { JsonText = text };

            if (TryDecryptFuGradeString(text, out var decrypted))
                return new FgPayload { JsonText = decrypted.Trim(), WasEncrypted = true };

            throw new InvalidDataException("File does not appear to be a supported FuGrade JSON .fg file.");
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
                    using (var reader = new StreamReader(crypto, Encoding.UTF8))
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

        private static byte[] EncryptText(string text)
        {
            using (var aes = Aes.Create())
            {
                aes.Key = Encoding.UTF8.GetBytes(FgAesKey);
                aes.IV = new byte[16];

                using (var output = new MemoryStream())
                {
                    using (var encryptor = aes.CreateEncryptor(aes.Key, aes.IV))
                    using (var crypto = new CryptoStream(output, encryptor, CryptoStreamMode.Write))
                    using (var writer = new StreamWriter(crypto, Encoding.UTF8))
                    {
                        writer.Write(text);
                    }

                    return Encoding.ASCII.GetBytes(Convert.ToBase64String(output.ToArray()));
                }
            }
        }

        private static void WriteAllBytesAtomic(string outputPath, byte[] bytes)
        {
            var fullPath = Path.GetFullPath(outputPath);
            var directory = Path.GetDirectoryName(fullPath);
            if (!string.IsNullOrWhiteSpace(directory))
                Directory.CreateDirectory(directory);

            var tempPath = fullPath + ".tmp";
            File.WriteAllBytes(tempPath, bytes);
            if (File.Exists(fullPath))
                File.Delete(fullPath);
            File.Move(tempPath, fullPath);
        }

        private sealed class FgPayload
        {
            public byte[] BinaryBytes { get; set; }
            public string JsonText { get; set; }
            public bool WasEncrypted { get; set; }
        }
    }
}
