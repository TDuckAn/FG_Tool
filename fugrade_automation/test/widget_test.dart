import 'package:flutter_test/flutter_test.dart';

import 'package:fugrade_automation/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const FuGradeApp());
    expect(find.text('FuGrade Automation'), findsOneWidget);
  });
}
