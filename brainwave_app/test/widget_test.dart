import 'package:brainwave_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders NeuroMotion dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuroMotionApp());

    expect(find.text('NeuroMotion'), findsOneWidget);
    expect(find.text('Latest Classification'), findsOneWidget);
    expect(find.text('Left Hand'), findsOneWidget);
    expect(find.text('AI Model'), findsOneWidget);
  });
}
