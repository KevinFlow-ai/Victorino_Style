// Generado a partir de google-services.json del proyecto victorino-style.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions no están configuradas para web. '
        'Ejecuta flutterfire configure para añadir soporte web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para iOS. '
          'Ejecuta flutterfire configure para añadir soporte iOS.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están soportadas en esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBpXaJTNraqfc28NrZ2kv3MwUdG6oA9JnI',
    appId: '1:18732368309:android:724a128b42f835d58659fc',
    messagingSenderId: '18732368309',
    projectId: 'victorino-style',
    storageBucket: 'victorino-style.firebasestorage.app',
  );
}
