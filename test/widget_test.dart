import 'package:flutter_test/flutter_test.dart';
import 'package:pitch_perfect/main.dart';

void main() {
  testWidgets('Pitch Perfect app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PitchPerfectApp());
    expect(find.text('Pitch Perfect'), findsWidgets);
  });
}
