using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using FuGrade;
using Newtonsoft.Json;

namespace FuGradeHelper.Commands
{
    internal static class ReadCmtCommand
    {
        /// <summary>
        /// Exit codes: 0=success, 1=file not found, 2=parse error.
        /// Deserializes a .cmt binary and writes JSON to stdout.
        /// </summary>
        public static int Run(string path)
        {
            if (!File.Exists(path))
            {
                Console.Error.WriteLine($"File not found: {path}");
                return 1;
            }

            try
            {
                ThesisComment comment;
                using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read))
                {
                    var formatter = new BinaryFormatter { Binder = new CmtReadBinder() };
#pragma warning disable SYSLIB0011
                    comment = (ThesisComment)formatter.Deserialize(fs);
#pragma warning restore SYSLIB0011
                }

                var output = new
                {
                    teacher = comment.Teacher,
                    subjectCode = comment.SubjectCode,
                    className = comment.ClassName,
                    semester = comment.Semester,
                    titleVN = comment.TitleVN,
                    titleEN = comment.TitleEN,
                    content = comment.Content,
                    form = comment.Form,
                    attitude = comment.Attitude,
                    achievement = comment.Achievement,
                    limitation = comment.Limitation,
                    students = MapStudents(comment.Conclusion),
                };

                Console.WriteLine(JsonConvert.SerializeObject(output, Formatting.Indented));
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Parse error: {ex.Message}");
                return 2;
            }
        }

        private static List<object> MapStudents(List<ThesisStudent> students)
        {
            var result = new List<object>();
            if (students == null) return result;
            foreach (var s in students)
            {
                string outcome = "agree";
                if (s.Revised_for_the_second_defense == "x") outcome = "revised";
                else if (s.Disagree_to_defense == "x") outcome = "disagree";
                result.Add(new
                {
                    roll = s.Roll,
                    name = s.Name,
                    outcome,
                    note = s.Note,
                });
            }
            return result;
        }

        // Redirects "FuGrade" assembly → our FuGrade.dll (FuGradeTypes project)
        private class CmtReadBinder : System.Runtime.Serialization.SerializationBinder
        {
            public override Type BindToType(string assemblyName, string typeName)
            {
                if (typeName == "FuGrade.ThesisComment") return typeof(ThesisComment);
                if (typeName == "FuGrade.ThesisStudent") return typeof(ThesisStudent);
                if (typeName == "FuGrade.ThesisStudent[]") return typeof(ThesisStudent[]);
                if (typeName.Contains("List") && typeName.Contains("FuGrade.ThesisStudent"))
                    return typeof(List<ThesisStudent>);
                return Type.GetType($"{typeName}, {assemblyName}");
            }
        }
    }
}
