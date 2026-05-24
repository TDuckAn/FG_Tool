using System.Collections.Generic;
using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    [System.Serializable]
    internal class TeacherGradeSurrogate : ISerializable
    {
        private readonly Dictionary<string, object> _raw = new Dictionary<string, object>();

        public string Version { get; private set; }
        public string Semester { get; private set; }
        public string Login { get; private set; }
        public List<SubjectClassGradeSurrogate> SubjectClassGrades { get; private set; }

        public TeacherGradeSurrogate() { }

        protected TeacherGradeSurrogate(SerializationInfo info, StreamingContext context)
        {
            Version = SerializationHelper.GetField<string>(info,
                "<Version>k__BackingField", "Version", "version",
                "<AppVersion>k__BackingField", "AppVersion");

            Semester = SerializationHelper.GetField<string>(info,
                "<Semester>k__BackingField", "Semester", "semester");

            Login = SerializationHelper.GetField<string>(info,
                "<Login>k__BackingField", "Login", "login",
                "<TeacherLogin>k__BackingField", "TeacherLogin",
                "<Username>k__BackingField", "Username");

            var groupsObj = SerializationHelper.GetField<object>(info,
                "<SubjectClassGrades>k__BackingField", "SubjectClassGrades", "subjectClassGrades",
                "<Groups>k__BackingField", "Groups");
            SubjectClassGrades = SerializationHelper.AsList<SubjectClassGradeSurrogate>(groupsObj);

            SerializationHelper.CaptureRawFields(info, _raw);
        }

        public void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            var knownKeys = new HashSet<string>
            {
                "<Version>k__BackingField", "Version", "version",
                "<AppVersion>k__BackingField", "AppVersion",
                "<Semester>k__BackingField", "Semester", "semester",
                "<Login>k__BackingField", "Login", "login",
                "<TeacherLogin>k__BackingField", "TeacherLogin",
                "<Username>k__BackingField", "Username",
                "<SubjectClassGrades>k__BackingField", "SubjectClassGrades", "subjectClassGrades",
                "<Groups>k__BackingField", "Groups"
            };

            SerializationHelper.AddRawValues(info, _raw, knownKeys);
            info.AddValue("<Version>k__BackingField", Version);
            info.AddValue("<Semester>k__BackingField", Semester);
            info.AddValue("<Login>k__BackingField", Login);
            info.AddValue("<SubjectClassGrades>k__BackingField", SubjectClassGrades);
        }
    }
}
