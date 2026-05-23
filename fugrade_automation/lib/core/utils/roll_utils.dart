final RegExp _rollPattern = RegExp(r'^[A-Z]{2}\d{5,7}$');

bool isValidRoll(String roll) => _rollPattern.hasMatch(roll.trim().toUpperCase());

bool rollsMatch(String a, String b) =>
    a.trim().toUpperCase() == b.trim().toUpperCase();
