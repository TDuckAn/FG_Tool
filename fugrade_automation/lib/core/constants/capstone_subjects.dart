final RegExp capstonePattern = RegExp(r'(490|491|493)$');

bool isCapstoneSubject(String subjectCode) =>
    capstonePattern.hasMatch(subjectCode);
