using System;
using System.Collections;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Formatters.Binary;

namespace FuGradeHelper.Commands
{
    internal static class InspectCmtCommand
    {
        public static int Run(string path)
        {
            if (!File.Exists(path))
            {
                Console.Error.WriteLine($"File not found: {path}");
                return 1;
            }

            try
            {
                using var fs = new FileStream(path, FileMode.Open, FileAccess.Read);
                var formatter = new BinaryFormatter { Binder = new DumpBinder() };
#pragma warning disable SYSLIB0011
                formatter.Deserialize(fs);
#pragma warning restore SYSLIB0011
            }
            catch (CmtDumpException)
            {
                // Expected — DumpBinder throws after capturing type info.
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Error: {ex.Message}");
                return 2;
            }
            return 0;
        }

        private class CmtDumpException : Exception { }

        private class DumpBinder : SerializationBinder
        {
            public override Type BindToType(string assemblyName, string typeName)
            {
                return typeof(FieldDumper);
            }
        }

        [Serializable]
        private class FieldDumper : ISerializable
        {
            public FieldDumper(SerializationInfo info, StreamingContext ctx)
            {
                Console.WriteLine($"=== Type: {info.ObjectType?.FullName ?? "unknown"} ===");
                foreach (SerializationEntry entry in info)
                {
                    var val = entry.Value;
                    string display;
                    if (val == null)
                        display = "(null)";
                    else if (val is string s)
                        display = s.Length > 60 ? $"\"{s.Substring(0, 60)}...\" (len={s.Length})" : $"\"{s}\"";
                    else if (val is ICollection col)
                        display = $"[{val.GetType().Name}, Count={col.Count}]";
                    else
                        display = val.ToString();

                    Console.WriteLine($"  [{entry.ObjectType?.Name ?? "?"}] {entry.Name} = {display}");
                }
                Console.WriteLine();
            }

            public void GetObjectData(SerializationInfo info, StreamingContext context)
                => throw new NotImplementedException();
        }
    }
}
