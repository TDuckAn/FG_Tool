using System.Collections.Generic;
using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    [System.Serializable]
    internal class SubjectClassGradeSurrogate : ISerializable
    {
        public string Subject { get; private set; }
        public string ClassCode { get; private set; }
        public List<StudentSurrogate> Students { get; private set; }
        public List<GradeComponentPlaceholder> GradeComponents { get; private set; }

        public SubjectClassGradeSurrogate() { }

        protected SubjectClassGradeSurrogate(SerializationInfo info, StreamingContext context)
        {
            Subject = SerializationHelper.GetField<string>(info,
                "<Subject>k__BackingField", "Subject", "subject",
                "<SubjectCode>k__BackingField", "SubjectCode");

            // The .fg field might be named "Class", "ClassName", or "ClassCode"
            ClassCode = SerializationHelper.GetField<string>(info,
                "<Class>k__BackingField", "Class", "class",
                "<ClassName>k__BackingField", "ClassName",
                "<ClassCode>k__BackingField", "ClassCode");

            var studentsObj = SerializationHelper.GetField<object>(info,
                "<Students>k__BackingField", "Students", "students");
            Students = SerializationHelper.AsList<StudentSurrogate>(studentsObj);

            var componentsObj = SerializationHelper.GetField<object>(info,
                "<GradeComponents>k__BackingField", "GradeComponents", "gradeComponents",
                "<Components>k__BackingField", "Components", "components",
                "<GradeItems>k__BackingField", "GradeItems", "gradeItems",
                "<GradeDetails>k__BackingField", "GradeDetails", "gradeDetails");
            GradeComponents = SerializationHelper.AsList<GradeComponentPlaceholder>(componentsObj);
        }

        public void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            info.AddValue("Subject", Subject);
            info.AddValue("ClassCode", ClassCode);
            info.AddValue("Students", Students);
            info.AddValue("GradeComponents", GradeComponents);
        }
    }
}
