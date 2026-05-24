using System;
using System.Collections.Generic;
using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    /// <summary>
    /// Redirects FuGradeLib type names to our local surrogate types so BinaryFormatter
    /// can deserialize .fg files without needing the original FuGradeLib.dll.
    /// </summary>
    internal class FgSerializationBinder : SerializationBinder
    {
        private static readonly Dictionary<string, Type> SimpleMap = new Dictionary<string, Type>
        {
            { "FuGradeLib.TeacherGrade",      typeof(TeacherGradeSurrogate) },
            { "FuGradeLib.SubjectClassGrade",  typeof(SubjectClassGradeSurrogate) },
            { "FuGradeLib.Student",            typeof(StudentSurrogate) },
            { "FuGradeLib.GradeComponent",     typeof(GradeComponentPlaceholder) },
            // Common variant names seen in older FuGradeLib versions
            { "FuGradeLib.GradeItem",          typeof(GradeComponentPlaceholder) },
            { "FuGradeLib.GradeDetail",        typeof(GradeComponentPlaceholder) },
        };

        private static readonly Dictionary<Type, Tuple<string, string>> ReverseMap =
            new Dictionary<Type, Tuple<string, string>>
            {
                { typeof(TeacherGradeSurrogate), Tuple.Create("FuGradeLib", "FuGradeLib.TeacherGrade") },
                { typeof(SubjectClassGradeSurrogate), Tuple.Create("FuGradeLib", "FuGradeLib.SubjectClassGrade") },
                { typeof(StudentSurrogate), Tuple.Create("FuGradeLib", "FuGradeLib.Student") },
                { typeof(GradeComponentPlaceholder), Tuple.Create("FuGradeLib", "FuGradeLib.GradeComponent") },
            };

        public override Type BindToType(string assemblyName, string typeName)
        {
            // Direct type mapping
            if (SimpleMap.TryGetValue(typeName, out var mapped))
                return mapped;

            // Generic collection types: List<FuGradeLib.X> → List<SurrogateX>
            if (typeName.StartsWith("System.Collections.Generic.List`1") &&
                typeName.IndexOf("FuGradeLib.", StringComparison.Ordinal) >= 0)
            {
                if (typeName.Contains("FuGradeLib.SubjectClassGrade"))
                    return typeof(List<SubjectClassGradeSurrogate>);
                if (typeName.Contains("FuGradeLib.Student"))
                    return typeof(List<StudentSurrogate>);
                if (typeName.Contains("FuGradeLib.GradeComponent") ||
                    typeName.Contains("FuGradeLib.GradeItem") ||
                    typeName.Contains("FuGradeLib.GradeDetail"))
                    return typeof(List<GradeComponentPlaceholder>);
            }

            // Fall through to default resolution for all other types (mscorlib, etc.)
            return null;
        }

        public override void BindToName(Type serializedType, out string assemblyName, out string typeName)
        {
            if (ReverseMap.TryGetValue(serializedType, out var entry))
            {
                assemblyName = entry.Item1;
                typeName = entry.Item2;
                return;
            }

            assemblyName = null;
            typeName = null;
        }
    }
}
