using System;
using System.Collections.Generic;
using Newtonsoft.Json;

namespace FuGradeHelper.Dtos
{
    public class ThesisCommentInputDto
    {
        [JsonProperty("teacherLogin")]
        public string TeacherLogin { get; set; }

        [JsonProperty("semester")]
        public string Semester { get; set; }

        [JsonProperty("subjectCode")]
        public string SubjectCode { get; set; }

        [JsonProperty("classCode")]
        public string ClassCode { get; set; }

        [JsonProperty("titleVN")]
        public string TitleVN { get; set; }

        [JsonProperty("titleEN")]
        public string TitleEN { get; set; }

        [JsonProperty("content")]
        public string Content { get; set; }

        [JsonProperty("formComment")]
        public string FormComment { get; set; }

        [JsonProperty("attitude")]
        public string Attitude { get; set; }

        [JsonProperty("achievement")]
        public string Achievement { get; set; }

        [JsonProperty("limitation")]
        public string Limitation { get; set; }

        [JsonProperty("conclusion")]
        public string Conclusion { get; set; }

        [JsonProperty("students")]
        public List<ThesisStudentInputDto> Students { get; set; } = new List<ThesisStudentInputDto>();
    }

    public class ThesisStudentInputDto
    {
        [JsonProperty("roll")]
        public string Roll { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }

        /// <summary>Values: "agree" | "revised" | "disagree"</summary>
        [JsonProperty("outcome")]
        public string Outcome { get; set; }

        [JsonProperty("note")]
        public string Note { get; set; }
    }
}
