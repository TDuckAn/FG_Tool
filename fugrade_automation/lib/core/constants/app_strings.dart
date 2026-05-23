class AppStrings {
  // Section labels matching FuGrade UI
  static const String section31 = '3.1  Thesis Content';
  static const String section32 = '3.2  Thesis Form';
  static const String section33 = '3.3  Students\' Attitude';
  static const String section41 = '4.1  Achievement Level';
  static const String section42 = '4.2  Limitation';
  static const String conclusion = 'Conclusion';
  static const String section43 = '4.3  Defense Decisions';

  // Contribution block header (Vietnamese)
  static const String contributionHeader = 'Mức đóng góp của các thành viên:';

  // Match status labels
  static const String matchExact = 'Matched';
  static const String matchPartial = 'Partial Match';
  static const String matchNone = 'No Match';

  // Draft status labels
  static const String statusNotStarted = 'Not Started';
  static const String statusDraft = 'Draft';
  static const String statusComplete = 'Complete';

  // Error messages
  static const String errFgFileLocked =
      'File is open in FU Grading Editor. Close it and retry.';
  static const String errFgInvalidFile =
      'This does not appear to be a valid .fg file.';
  static const String errFgCorrupted =
      'The file could not be read. Try re-downloading it from FAP.';
  static const String errSheetInvalidUrl =
      'Invalid Google Sheets URL. Paste the full URL from your browser.';
  static const String errSheetNotShared =
      'Cannot access sheet. Share it (View) with the service account and retry.';
}
