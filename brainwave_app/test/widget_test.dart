import 'package:brainwave_app/app/neuro_motion_app.dart';
import 'package:brainwave_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Start every test signed out so the auth gate runs from a clean state.
  setUp(() async => AuthService.instance.signOut());

  testWidgets('shows the login screen on launch', (tester) async {
    await tester.pumpWidget(const NeuroMotionApp());

    expect(find.text('NeuroMotion'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
    // The dashboard is gated until the user authenticates.
    expect(find.text('Patient Status'), findsNothing);
  });

  testWidgets('renders the dashboard once signed in', (tester) async {
    await AuthService.instance.continueAsGuest();
    await tester.pumpWidget(const NeuroMotionApp());
    await tester.pumpAndSettle();

    // Header greets the signed-in user (guest here) rather than the app name.
    expect(find.text('Good Morning'), findsOneWidget);
    // The guest name is shown dynamically (home header + profile card).
    expect(find.text('Guest'), findsWidgets);
    expect(find.text('Patient Status'), findsOneWidget);
    expect(find.text('Recent EEG Readings'), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
  });
}
