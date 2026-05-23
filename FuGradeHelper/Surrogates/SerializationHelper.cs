using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization;

namespace FuGradeHelper.Surrogates
{
    internal static class SerializationHelper
    {
        /// <summary>
        /// Tries multiple candidate field names in order; returns the first that resolves,
        /// or default(T) if none match. Handles both plain fields and auto-property backing fields.
        /// </summary>
        public static T GetField<T>(SerializationInfo info, params string[] candidates)
        {
            foreach (var name in candidates)
            {
                try
                {
                    var value = info.GetValue(name, typeof(T));
                    if (value != null) return (T)value;
                }
                catch (SerializationException) { }
                catch (InvalidCastException) { }
            }
            return default;
        }

        /// <summary>
        /// Converts a deserialized list object (which may be List&lt;T&gt;, ArrayList, or null)
        /// into a typed List&lt;T&gt;.
        /// </summary>
        public static List<T> AsList<T>(object obj) where T : class
        {
            if (obj == null) return new List<T>();

            if (obj is List<T> typed) return typed;

            // May arrive as IList containing T instances (e.g. if binder mapped element types)
            if (obj is IList untyped)
            {
                var result = new List<T>(untyped.Count);
                foreach (var item in untyped)
                    if (item is T t) result.Add(t);
                return result;
            }

            return new List<T>();
        }
    }
}
