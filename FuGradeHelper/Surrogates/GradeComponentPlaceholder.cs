using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    /// <summary>
    /// Throwaway placeholder so BinaryFormatter can deserialize FuGradeLib.GradeComponent
    /// objects without failing. Grade data is out of scope for this tool.
    /// </summary>
    [System.Serializable]
    internal class GradeComponentPlaceholder : ISerializable
    {
        public GradeComponentPlaceholder() { }

        protected GradeComponentPlaceholder(SerializationInfo info, StreamingContext context)
        {
            // Intentionally ignore all fields — grades are out of scope.
        }

        public void GetObjectData(SerializationInfo info, StreamingContext context) { }
    }
}
