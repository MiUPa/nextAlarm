import 'package:flutter_test/flutter_test.dart';
import 'package:next_alarm/main.dart';

void main() {
  testWidgets('App boots and renders root widget', (WidgetTester tester) async {
    await tester.pumpWidget(const NextAlarmApp());
    await tester.pump();
    expect(find.byType(NextAlarmApp), findsOneWidget);
  });
}
