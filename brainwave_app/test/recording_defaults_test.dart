import 'package:brainwave_app/services/firebase_data_service.dart';
import 'package:brainwave_app/services/muse_live_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloud recording requires an explicit saved opt in', () {
    expect(CerebroProfile.fallback(null).consentActive, isFalse);
    expect(CerebroProfile.fromMap('user', const {}).consentActive, isFalse);
    expect(
      CerebroProfile.fromMap('user', const {
        'consentActive': true,
      }).consentActive,
      isTrue,
    );
  });

  test('offline snapshot has no previous live readings', () {
    final snapshot = MuseSnapshot.offline(source: 'bridge');

    expect(snapshot.connected, isFalse);
    expect(snapshot.state.label, 'Waiting');
    expect(snapshot.state.confidence, 0);
    expect(snapshot.bands.alpha, 0);
    expect(snapshot.body.heartRate, isNull);
    expect(snapshot.streams.eeg, isFalse);
  });
}
