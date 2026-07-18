import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/neuro_motion_app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firebase_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService.instance.initialize();
  await FirebaseDataService.instance.initialize();
  runApp(const CerebroSyncApp());
}
