using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    /// <summary>
    /// Surrogate for FuGradeLib.GradeComponent-like objects. The app only needs the
    /// component display name so teachers can select which grading component/column
    /// they are working with.
    /// </summary>
    [System.Serializable]
    internal class GradeComponentPlaceholder : ISerializable
    {
        public string Name { get; private set; }

        public GradeComponentPlaceholder() { }

        protected GradeComponentPlaceholder(SerializationInfo info, StreamingContext context)
        {
            Name = SerializationHelper.GetField<string>(info,
                "<Name>k__BackingField", "Name", "name",
                "<ComponentName>k__BackingField", "ComponentName", "componentName",
                "<Title>k__BackingField", "Title", "title",
                "<Description>k__BackingField", "Description", "description");
        }

        public void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            info.AddValue("Name", Name);
        }
    }
}
