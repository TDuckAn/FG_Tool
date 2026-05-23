using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using FuGradeHelper.Dtos;
using FuGradeHelper.Surrogates;
using Newtonsoft.Json;

namespace FuGradeHelper.Commands
{
    internal static class ParseFgCommand
    {
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

            // Quick format validation before full parse
            var validationResult = ValidateFileHeader(filePath);
            if (validationResult != 0) return validationResult;

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
            using (var fs = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                var formatter = new BinaryFormatter
                {
                    Binder = new FgSerializationBinder()
                };

                var root = formatter.Deserialize(fs) as TeacherGradeSurrogate;
                if (root == null)
                    throw new InvalidDataException("Deserialized root object is not TeacherGrade.");

                return MapToDto(root);
            }
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

                dto.Groups.Add(grpDto);
            }

            return dto;
        }
    }
}
