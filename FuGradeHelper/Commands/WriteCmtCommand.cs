using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using FuGrade;
using FuGradeHelper.Dtos;
using FuGradeHelper.Surrogates;
using Newtonsoft.Json;

namespace FuGradeHelper.Commands
{
    internal static class WriteCmtCommand
    {
        private const string PasswordHash = "c4ca4238a0b923820dcc509a6f75849b"; // MD5("1")

        /// <summary>
        /// Exit codes: 0=success, 1=bad args, 2=write error.
        /// Reads JSON from --data arg, writes binary .cmt to --output path.
        /// </summary>
        public static int Run(string jsonData, string outputPath)
        {
            if (string.IsNullOrWhiteSpace(jsonData))
            {
                Console.Error.WriteLine("--data argument is required.");
                return 1;
            }
            if (string.IsNullOrWhiteSpace(outputPath))
            {
                Console.Error.WriteLine("--output argument is required.");
                return 1;
            }

            // Support --data-file: treat the value as a file path and read JSON from it.
            if (jsonData != null && File.Exists(jsonData))
                jsonData = File.ReadAllText(jsonData, Encoding.UTF8);

            ThesisCommentInputDto dto;
            try
            {
                dto = JsonConvert.DeserializeObject<ThesisCommentInputDto>(jsonData);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"JSON parse error: {ex.Message}");
                return 2;
            }

            try
            {
                var comment = BuildThesisComment(dto);
                Serialize(comment, outputPath);
                Console.WriteLine($"Written: {outputPath}");
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Write error: {ex.Message}");
                return 2;
            }
        }

        private static ThesisComment BuildThesisComment(ThesisCommentInputDto dto)
        {
            var students = new List<ThesisStudent>();
            foreach (var s in dto.Students ?? new List<ThesisStudentInputDto>())
            {
                var outcome = (s.Outcome ?? "agree").ToLowerInvariant().Trim();
                students.Add(new ThesisStudent
                {
                    Roll = s.Roll,
                    Name = s.Name,
                    Agree_to_defense = outcome == "agree" ? "x" : null,
                    Revised_for_the_second_defense = outcome == "revised" ? "x" : null,
                    Disagree_to_defense = outcome == "disagree" ? "x" : null,
                    Note = string.IsNullOrEmpty(s.Note) ? null : s.Note,
                });
            }

            return new ThesisComment
            {
                Teacher = dto.TeacherLogin ?? "",
                DT = DateTime.UtcNow,
                SubjectCode = dto.SubjectCode ?? "",
                ClassName = dto.ClassCode ?? "",
                Semester = dto.Semester ?? "",
                Password = PasswordHash,
                TitleVN = dto.TitleVN ?? "",
                TitleEN = dto.TitleEN ?? "",
                Content = dto.Content ?? "",
                Form = dto.FormComment ?? "",
                Attitude = dto.Attitude ?? "",
                Achievement = dto.Achievement ?? "",
                Limitation = dto.Limitation ?? "",
                Conclusion = students,
            };
        }

        private static void Serialize(ThesisComment comment, string outputPath)
        {
            var dir = Path.GetDirectoryName(outputPath);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                Directory.CreateDirectory(dir);

            using (var fs = new FileStream(outputPath, FileMode.Create, FileAccess.Write))
            {
                var formatter = new BinaryFormatter
                {
                    Binder = new CmtWriteBinderAttribute()
                };
                formatter.Serialize(fs, comment);
            }
        }
    }
}
