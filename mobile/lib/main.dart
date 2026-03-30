import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO Phase 7: Firebase.initializeApp()

  runApp(
    const ProviderScope(
      child: RideSyncApp(),
    ),
  );
}
