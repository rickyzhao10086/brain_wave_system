import 'package:brainwave_app/app/neuro_motion_app.dart';
import 'package:brainwave_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the account deletion path required by App Store Guideline 5.1.1(v)
/// and Google Play's account deletion policy.
///
/// Firebase is not initialized under `flutter test`, so AuthService runs its
/// local fallback: the flow, the confirmation gate, and the return to the login
/// screen are exercised here; the Firestore erase is not.
void main() {
  setUp(() async => AuthService.instance.signOut());

  Future<void> openSetupTab(WidgetTester tester) async {
    await AuthService.instance.signUp(
      name: 'Test User',
      email: 'test@example.com',
      password: 'test-password',
    );
    await tester.pumpWidget(const CerebroSyncApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Delete my account'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('deleting the account returns to the login screen', (
    tester,
  ) async {
    await openSetupTab(tester);

    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm your password'),
      'test-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();

    // The auth gate swaps back to login once the user is gone.
    expect(AuthService.instance.isSignedIn, isFalse);
    expect(find.text('Delete account?'), findsNothing);
    expect(find.text('Clinician & caregiver access'), findsOneWidget);
  });

  testWidgets('confirming without a password does not delete', (tester) async {
    await openSetupTab(tester);

    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your password to confirm.'), findsOneWidget);
    expect(AuthService.instance.isSignedIn, isTrue);
  });

  testWidgets('cancelling leaves the account signed in', (tester) async {
    await openSetupTab(tester);

    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account?'), findsNothing);
    expect(AuthService.instance.isSignedIn, isTrue);
  });
}
