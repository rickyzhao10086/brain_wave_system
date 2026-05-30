import 'package:brainwave_app/app/neuro_motion_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders NeuroMotion dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuroMotionApp());

    expect(find.text('NeuroMotion'), findsOneWidget);
    expect(find.text('Patient Status'), findsOneWidget);
    expect(find.text('Recent EEG Readings'), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
  });
}
