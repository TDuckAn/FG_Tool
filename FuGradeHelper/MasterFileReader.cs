using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
using FuGrade;

namespace FuGradeHelper
{
    internal static class MasterFileReader
    {
        public static List<FinalThesisGradingItem> Load(string path)
        {
            using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                var formatter = new BinaryFormatter();
                return (List<FinalThesisGradingItem>)formatter.Deserialize(fs);
            }
        }

        public static List<string> GetComponentNames(
            List<FinalThesisGradingItem> master,
            string subjectCode)
        {
            if (master == null || string.IsNullOrWhiteSpace(subjectCode))
                return new List<string>();

            var exact = master
                .Where(i => string.Equals(i.SubjectCode, subjectCode, StringComparison.OrdinalIgnoreCase)
                            && !string.IsNullOrWhiteSpace(i.GradingItem))
                .Select(i => i.GradingItem.Trim())
                .ToList();
            if (exact.Count > 0)
                return exact;

            return master
                .Where(i => !string.IsNullOrWhiteSpace(i.SubjectCode)
                            && i.SubjectCode.StartsWith(subjectCode, StringComparison.OrdinalIgnoreCase)
                            && !string.IsNullOrWhiteSpace(i.GradingItem))
                .Select(i => i.GradingItem.Trim())
                .ToList();
        }
    }
}
