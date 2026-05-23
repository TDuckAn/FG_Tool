using System.Collections.Generic;
using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    [System.Serializable]
    internal class TeacherGradeSurrogate : ISerializable
    {
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
        }

        public void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            info.AddValue("Version", Version);
            info.AddValue("Semester", Semester);
            info.AddValue("Login", Login);
            info.AddValue("SubjectClassGrades", SubjectClassGrades);
        }
    }
}
