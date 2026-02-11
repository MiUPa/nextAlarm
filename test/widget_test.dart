import 'package:flutter_test/flutter_test.dart';
import 'package:next_alarm/main.dart';

void main() {
  testWidgets('NextAlarmApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const NextAlarmApp());
    expect(find.byType(NextAlarmApp), findsOneWidget);
  });
}
