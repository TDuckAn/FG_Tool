using System;
using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    // Controls the assembly/type name written into the .cmt stream so FuGrade.exe
    // can find "FuGrade.ThesisComment" in its own assembly when reading.
    // Since ThesisComment/ThesisStudent are defined in FuGradeTypes.dll (AssemblyName=FuGrade),
    // CLR metadata already writes "FuGrade" everywhere — this binder is a no-op safety net
    // that ensures the version string matches what FuGrade.exe was compiled against.
    internal class CmtWriteBinderAttribute : SerializationBinder
    {
        public override void BindToName(Type serializedType, out string assemblyName, out string typeName)
        {
            assemblyName = null;
            typeName = null;
        }

        public override Type BindToType(string assemblyName, string typeName) => null;
    }
}
