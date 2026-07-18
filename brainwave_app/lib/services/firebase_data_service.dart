import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'muse_live_service.dart';

enum FirebaseSyncStatus { unavailable, ready, syncing, error }

class CerebroProfile {
  const CerebroProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.consentActive,
    required this.careMode,
    required this.sessionWindowSeconds,
    required this.sessionNote,
    this.preferredDeviceName,
  });

  final String uid;
  final String displayName;
  final String email;
  final bool consentActive;
  final String careMode;
  final int sessionWindowSeconds;
  final String sessionNote;
  final String? preferredDeviceName;

  factory CerebroProfile.fallback(AuthUser? user) {
    return CerebroProfile(
      uid: user?.uid ?? '',
      displayName: user?.displayLabel ?? 'CerebroSync user',
      email: user?.email ?? '',
      consentActive: true,
      careMode: 'Care',
      sessionWindowSeconds: 30,
      sessionNote: '',
      preferredDeviceName: null,
    );
  }

  factory CerebroProfile.fromMap(String uid, Map<String, dynamic> data) {
    return CerebroProfile(
      uid: uid,
      displayName: _string(data['displayName'], fallback: 'CerebroSync user'),
      email: _string(data['email']),
      consentActive: data['consentActive'] != false,
      careMode: _string(data['careMode'], fallback: 'Care'),
      sessionWindowSeconds: _integer(
        data['sessionWindowSeconds'],
        fallback: 30,
      ),
      sessionNote: _string(data['sessionNote']),
      preferredDeviceName: _nullableString(data['preferredDeviceName']),
    );
  }
}

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.startedAt,
    required this.status,
    required this.state,
    required this.sampleCount,
  });

  final String id;
  final DateTime? startedAt;
  final String status;
  final String state;
  final int sampleCount;

  factory SessionSummary.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return SessionSummary(
      id: document.id,
      startedAt: _dateTime(data['startedAt']),
      status: _string(data['status'], fallback: 'unknown'),
      state: _string(data['latestState'], fallback: 'Waiting'),
      sampleCount: _integer(data['sampleCount'], fallback: 0),
    );
  }
}

class SessionTrendPoint {
  const SessionTrendPoint({
    required this.capturedAt,
    required this.calmIndex,
    required this.state,
  });

  final DateTime capturedAt;
  final double calmIndex;
  final String state;
}

class FirebaseDataService extends ChangeNotifier {
  FirebaseDataService._();

  static final FirebaseDataService instance = FirebaseDataService._();

  static const checkpointInterval = Duration(minutes: 1);

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _sessionsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _trendSubscription;
  Timer? _checkpointTimer;

  CerebroProfile _profile = CerebroProfile.fallback(null);
  List<SessionSummary> _recentSessions = const [];
  List<SessionTrendPoint> _trendPoints = const [];
  FirebaseSyncStatus _status = FirebaseSyncStatus.unavailable;
  String? _lastError;
  String? _boundUid;
  String? _activeSessionId;
  String? _trendSessionId;
  bool _wasMuseLive = false;
  bool _startingSession = false;
  bool _checkpointInFlight = false;
  Future<void>? _checkpointFuture;
  int _bindingGeneration = 0;
  MuseSnapshot? _lastLiveSnapshot;

  CerebroProfile get profile => _profile;
  List<SessionSummary> get recentSessions => _recentSessions;
  List<SessionTrendPoint> get trendPoints => _trendPoints;
  FirebaseSyncStatus get status => _status;
  String? get lastError => _lastError;
  bool get isRecording => _activeSessionId != null;
  int get sessionCount => _recentSessions.length;
  DateTime? get lastSessionAt =>
      _recentSessions.isEmpty ? null : _recentSessions.first.startedAt;

  Future<void> initialize() async {
    if (_firestore != null) return;
    final firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(persistenceEnabled: true);
    _firestore = firestore;
    _auth = FirebaseAuth.instance;
    _status = FirebaseSyncStatus.ready;

    MuseLiveService.instance.addListener(_handleMuseChange);
    AuthService.instance.registerBeforeSignOut(endActiveSession);
    _auth!.userChanges().listen((user) {
      unawaited(_bindUser(user));
    });
    await _bindUser(_auth!.currentUser);
  }

  Future<void> saveProfile({
    required String displayName,
    required bool consentActive,
    required String careMode,
    required int sessionWindowSeconds,
    required String sessionNote,
  }) async {
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) return;

    _setSyncing();
    try {
      await firestore.collection('users').doc(uid).set({
        'displayName': displayName.trim(),
        'consentActive': consentActive,
        'careMode': careMode,
        'sessionWindowSeconds': sessionWindowSeconds,
        'sessionNote': sessionNote.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!consentActive) {
        await endActiveSession();
      } else if (MuseLiveService.instance.isLive) {
        await _startSession();
      }
      _setReady();
    } on FirebaseException catch (error) {
      _setError(error.message ?? 'Profile sync failed.');
      rethrow;
    }
  }

  Future<void> endActiveSession() async {
    _checkpointTimer?.cancel();
    _checkpointTimer = null;
    final sessionId = _activeSessionId;
    if (sessionId == null) return;

    await _writeCheckpoint(complete: true);
    if (_activeSessionId == sessionId) {
      _activeSessionId = null;
      notifyListeners();
    }
  }

  Future<void> _bindUser(User? user) async {
    final generation = ++_bindingGeneration;
    await _profileSubscription?.cancel();
    await _sessionsSubscription?.cancel();
    await _trendSubscription?.cancel();
    _profileSubscription = null;
    _sessionsSubscription = null;
    _trendSubscription = null;
    _checkpointTimer?.cancel();
    _checkpointTimer = null;
    _activeSessionId = null;
    _trendSessionId = null;
    _boundUid = user?.uid;
    _recentSessions = const [];
    _trendPoints = const [];
    _profile = CerebroProfile.fallback(AuthService.instance.currentUser);

    if (user == null || user.isAnonymous || _firestore == null) {
      notifyListeners();
      return;
    }

    _setSyncing();
    final userReference = _firestore!.collection('users').doc(user.uid);
    try {
      final existing = await userReference.get();
      if (generation != _bindingGeneration) return;
      if (!existing.exists) {
        await userReference.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : _emailLabel(user.email),
          'isAnonymous': false,
          'consentActive': true,
          'careMode': 'Care',
          'sessionWindowSeconds': 30,
          'sessionNote': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userReference.set({
          'email': user.email ?? '',
          if (user.displayName?.trim().isNotEmpty == true)
            'displayName': user.displayName!.trim(),
          'isAnonymous': user.isAnonymous,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      if (generation != _bindingGeneration) return;

      _profileSubscription = userReference.snapshots().listen((document) {
        final data = document.data();
        if (data == null) return;
        _profile = CerebroProfile.fromMap(document.id, data);
        _setReady();
        if (!_profile.consentActive) {
          unawaited(endActiveSession());
        } else if (MuseLiveService.instance.isLive) {
          unawaited(_startSession());
        }
      }, onError: (Object error) => _setError(error.toString()));
      _sessionsSubscription = userReference
          .collection('sessions')
          .orderBy('startedAt', descending: true)
          .limit(20)
          .snapshots()
          .listen(
            _handleSessions,
            onError: (Object error) => _setError(error.toString()),
          );
      _setReady();
    } on FirebaseException catch (error) {
      _setError(error.message ?? 'Firebase data setup failed.');
    }
  }

  void _handleSessions(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _recentSessions = snapshot.docs
        .map(SessionSummary.fromDocument)
        .toList(growable: false);
    final sessionId =
        _activeSessionId ??
        (_recentSessions.isEmpty ? null : _recentSessions.first.id);
    _bindTrend(sessionId);
    notifyListeners();
  }

  void _bindTrend(String? sessionId) {
    if (_trendSessionId == sessionId) return;
    _trendSessionId = sessionId;
    unawaited(_trendSubscription?.cancel());
    _trendSubscription = null;
    if (sessionId == null || _boundUid == null || _firestore == null) {
      _trendPoints = const [];
      return;
    }

    _trendSubscription = _firestore!
        .collection('users')
        .doc(_boundUid)
        .collection('sessions')
        .doc(sessionId)
        .collection('samples')
        .orderBy('capturedAt', descending: true)
        .limit(60)
        .snapshots()
        .listen((snapshot) {
          final points = <SessionTrendPoint>[];
          for (final document in snapshot.docs.reversed) {
            final data = document.data();
            final capturedAt = _dateTime(data['capturedAt']);
            if (capturedAt == null) continue;
            final bands = _map(data['bands']);
            points.add(
              SessionTrendPoint(
                capturedAt: capturedAt,
                calmIndex: _number(bands['alpha']).clamp(0, 1),
                state: _string(data['state'], fallback: 'Waiting'),
              ),
            );
          }
          _trendPoints = points;
          notifyListeners();
        }, onError: (Object error) => _setError(error.toString()));
  }

  void _handleMuseChange() {
    final muse = MuseLiveService.instance;
    final isLive = muse.isLive;
    if (isLive) _lastLiveSnapshot = muse.snapshot;

    if (isLive && !_wasMuseLive) {
      unawaited(_startSession());
    } else if (!isLive && _wasMuseLive) {
      unawaited(endActiveSession());
    }
    _wasMuseLive = isLive;
  }

  Future<void> _startSession() async {
    if (_startingSession ||
        _activeSessionId != null ||
        !_profile.consentActive ||
        !MuseLiveService.instance.isLive) {
      return;
    }
    final user = _auth?.currentUser;
    final firestore = _firestore;
    if (user == null || user.isAnonymous || firestore == null) return;

    _startingSession = true;
    _setSyncing();
    final sessionReference = firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc();
    final muse = MuseLiveService.instance;
    final snapshot = muse.snapshot;
    try {
      await sessionReference.set({
        'ownerId': user.uid,
        'status': 'active',
        'source': muse.source.name,
        'deviceName': muse.deviceName ?? 'Muse 2',
        'sampleRate': snapshot.sampleRate ?? 256,
        'batteryPercent': snapshot.batteryPercent,
        'latestState': snapshot.state.label,
        'latestConfidence': snapshot.state.confidence,
        'latestArtifact': snapshot.state.artifact,
        'sampleCount': 0,
        'sessionNote': _profile.sessionNote,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await firestore.collection('users').doc(user.uid).set({
        'preferredDeviceName': muse.deviceName ?? 'Muse 2',
        'lastDeviceAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (_auth?.currentUser?.uid != user.uid) {
        await sessionReference.set({
          'status': 'complete',
          'endedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }
      _activeSessionId = sessionReference.id;
      _lastLiveSnapshot = snapshot;
      _bindTrend(sessionReference.id);
      await _writeCheckpoint();
      if (MuseLiveService.instance.isLive) {
        _checkpointTimer = Timer.periodic(checkpointInterval, (_) {
          unawaited(_writeCheckpoint());
        });
      } else {
        await endActiveSession();
      }
      _setReady();
      notifyListeners();
    } on FirebaseException catch (error) {
      _setError(error.message ?? 'Could not start session sync.');
    } finally {
      _startingSession = false;
    }
  }

  Future<void> _writeCheckpoint({bool complete = false}) async {
    if (_checkpointInFlight) {
      await _checkpointFuture;
      if (complete && _activeSessionId != null) {
        await _writeCheckpoint(complete: true);
      }
      return;
    }
    final firestore = _firestore;
    final uid = _auth?.currentUser?.uid;
    final sessionId = _activeSessionId;
    final snapshot = MuseLiveService.instance.isLive
        ? MuseLiveService.instance.snapshot
        : _lastLiveSnapshot;
    if (firestore == null ||
        uid == null ||
        sessionId == null ||
        snapshot == null) {
      return;
    }

    final checkpoint = Completer<void>();
    _checkpointInFlight = true;
    _checkpointFuture = checkpoint.future;
    final sessionReference = firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId);
    final sampleReference = sessionReference.collection('samples').doc();
    final batch = firestore.batch();
    final capturedAt = FieldValue.serverTimestamp();
    batch.set(sampleReference, {
      'capturedAt': capturedAt,
      'state': snapshot.state.label,
      'confidence': snapshot.state.confidence,
      'artifact': snapshot.state.artifact,
      'contact': snapshot.contact,
      'bands': _bandsMap(snapshot.bands),
      'body': _bodyMap(snapshot.body),
      'sampleRate': snapshot.sampleRate ?? 256,
      'batteryPercent': snapshot.batteryPercent,
    });
    batch.set(sessionReference, {
      'status': complete ? 'complete' : 'active',
      'latestState': snapshot.state.label,
      'latestConfidence': snapshot.state.confidence,
      'latestArtifact': snapshot.state.artifact,
      'batteryPercent': snapshot.batteryPercent,
      'sampleCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
      if (complete) 'endedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
      _lastError = null;
      _status = FirebaseSyncStatus.ready;
      notifyListeners();
    } on FirebaseException catch (error) {
      _setError(error.message ?? 'Session checkpoint failed.');
    } finally {
      _checkpointInFlight = false;
      _checkpointFuture = null;
      checkpoint.complete();
    }
  }

  void _setSyncing() {
    _status = FirebaseSyncStatus.syncing;
    _lastError = null;
    notifyListeners();
  }

  void _setReady() {
    _status = FirebaseSyncStatus.ready;
    _lastError = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = FirebaseSyncStatus.error;
    _lastError = message.replaceFirst('Exception: ', '');
    notifyListeners();
  }

  static Map<String, double> _bandsMap(MuseBands bands) => {
    'delta': bands.delta,
    'theta': bands.theta,
    'alpha': bands.alpha,
    'beta': bands.beta,
    'gamma': bands.gamma,
  };

  static Map<String, Object> _bodyMap(MuseBodySignals body) => {
    'ppg': body.ppg,
    if (body.heartRate != null) 'heartRate': body.heartRate!,
    if (body.breathRate != null) 'breathRate': body.breathRate!,
    'motionG': body.motionG,
    'gyroDps': body.gyroDps,
  };

  static String _emailLabel(String? email) {
    final handle = email?.split('@').first ?? '';
    if (handle.isEmpty) return 'CerebroSync user';
    return handle[0].toUpperCase() + handle.substring(1);
  }
}

Map<String, dynamic> _map(Object? value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

String _string(Object? value, {String fallback = ''}) {
  return value is String && value.isNotEmpty ? value : fallback;
}

String? _nullableString(Object? value) {
  return value is String && value.isNotEmpty ? value : null;
}

int _integer(Object? value, {required int fallback}) {
  return value is num ? value.round() : fallback;
}

double _number(Object? value) {
  return value is num ? value.toDouble() : 0;
}

DateTime? _dateTime(Object? value) {
  return value is Timestamp ? value.toDate() : null;
}
