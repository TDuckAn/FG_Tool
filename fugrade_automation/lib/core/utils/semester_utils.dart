String normalizeSemester(String s) =>
    s.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');

bool semestersMatch(String a, String b) =>
    normalizeSemester(a) == normalizeSemester(b);
