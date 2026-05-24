using System.Collections.Generic;
using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    [System.Serializable]
    internal class StudentSurrogate : ISerializable
    {
        private readonly Dictionary<string, object> _raw = new Dictionary<string, object>();

        public string Roll { get; private set; }
        public string Name { get; private set; }

        public StudentSurrogate() { }

        protected StudentSurrogate(SerializationInfo info, StreamingContext context)
        {
            Roll = SerializationHelper.GetField<string>(info,
                "<Roll>k__BackingField", "Roll", "roll",
                "<StudentRoll>k__BackingField", "StudentRoll");

            Name = SerializationHelper.GetField<string>(info,
                "<Name>k__BackingField", "Name", "name",
                "<StudentName>k__BackingField", "StudentName",
                "<FullName>k__BackingField", "FullName");

            SerializationHelper.CaptureRawFields(info, _raw);
        }

        public void SetGradeField(string fieldName, object value) => _raw[fieldName] = value;

        public object GetRawField(string key) => _raw.TryGetValue(key, out var value) ? value : null;

        public void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            var knownKeys = new HashSet<string>
            {
                "<Roll>k__BackingField", "Roll", "roll",
                "<StudentRoll>k__BackingField", "StudentRoll",
                "<Name>k__BackingField", "Name", "name",
                "<StudentName>k__BackingField", "StudentName",
                "<FullName>k__BackingField", "FullName"
            };

            SerializationHelper.AddRawValues(info, _raw, knownKeys);
            info.AddValue("<Roll>k__BackingField", Roll);
            info.AddValue("<Name>k__BackingField", Name);
        }
    }
}
