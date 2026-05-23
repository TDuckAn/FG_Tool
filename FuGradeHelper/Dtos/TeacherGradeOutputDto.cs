using System.Collections.Generic;
using Newtonsoft.Json;

namespace FuGradeHelper.Dtos
{
    public class TeacherGradeOutputDto
    {
        [JsonProperty("version")]
        public string Version { get; set; }

        [JsonProperty("semester")]
        public string Semester { get; set; }

        [JsonProperty("login")]
        public string Login { get; set; }

        [JsonProperty("groups")]
        public List<SubjectClassGradeOutputDto> Groups { get; set; } = new List<SubjectClassGradeOutputDto>();
    }

    public class SubjectClassGradeOutputDto
    {
        [JsonProperty("subject")]
        public string Subject { get; set; }

        [JsonProperty("classCode")]
        public string ClassCode { get; set; }

        [JsonProperty("students")]
        public List<StudentOutputDto> Students { get; set; } = new List<StudentOutputDto>();

        [JsonProperty("gradingComponents")]
        public List<string> GradingComponents { get; set; } = new List<string>();

        [JsonProperty("isCapstone")]
        public bool IsCapstone => System.Text.RegularExpressions.Regex.IsMatch(Subject ?? "", @"(490|491|493)$");
    }

    public class StudentOutputDto
    {
        [JsonProperty("roll")]
        public string Roll { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }
    }
}
