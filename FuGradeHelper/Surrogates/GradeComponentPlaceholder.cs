using System.Collections.Generic;
using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    [System.Serializable]
    internal class GradeComponentPlaceholder : ISerializable
    {
        private readonly Dictionary<string, object> _raw = new Dictionary<string, object>();

        public string Name { get; private set; }

        public GradeComponentPlaceholder() { }

        protected GradeComponentPlaceholder(SerializationInfo info, StreamingContext context)
        {
            Name = SerializationHelper.GetField<string>(info,
                "<Name>k__BackingField", "Name", "name",
                "<ComponentName>k__BackingField", "ComponentName", "componentName",
                "<Title>k__BackingField", "Title", "title",
                "<Description>k__BackingField", "Description", "description");

            SerializationHelper.CaptureRawFields(info, _raw);
        }

        public void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            var knownKeys = new HashSet<string>
            {
                "<Name>k__BackingField", "Name", "name",
                "<ComponentName>k__BackingField", "ComponentName", "componentName",
                "<Title>k__BackingField", "Title", "title",
                "<Description>k__BackingField", "Description", "description"
            };

            SerializationHelper.AddRawValues(info, _raw, knownKeys);
            info.AddValue("<Name>k__BackingField", Name);
        }
    }
}
