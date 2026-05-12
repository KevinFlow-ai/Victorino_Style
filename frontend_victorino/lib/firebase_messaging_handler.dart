import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

// Handler de mensajes FCM en background/terminated.
// Corre en un isolate separado, por eso necesita inicializar Firebase de nuevo.
// @pragma('vm:entry-point') evita que el tree-shaker elimine esta función.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
