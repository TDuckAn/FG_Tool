using System.Collections.Generic;
using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    [System.Serializable]
    internal class StudentSurrogate : ISerializable
    {
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

            // Grades and Comment intentionally discarded — out of scope.
        }

        public void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            info.AddValue("Roll", Roll);
            info.AddValue("Name", Name);
        }
    }
}
