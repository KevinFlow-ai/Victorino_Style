// Punto de entrada de la app. Solo se encarga de:
// 1. Inicializar Flutter.
// 2. Inicializar Firebase (debe ser antes de runApp).
// 3. Registrar el handler de mensajes FCM en background.
// 4. Inicializar datos de localización (intl) para español de España.
// 5. Envolver la app en ProviderScope para Riverpod y lanzar VictorinoApp.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';


// *********  FIREBASE
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/notifications/fcm_service.dart';
import 'core/notifications/local_notifications.dart';

import 'app.dart';
import 'core/api/api_url_provider.dart';

/// Firebase y FCM solo están soportados en Android e iOS.
/// En Windows/Linux/macOS/Web se omiten para evitar UnsupportedError al arrancar.
bool get _soportaFirebase =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES');

  // Lee la URL guardada en disco ANTES de runApp para inyectarla
  // sincrónicamente en ProviderScope. Así dioProvider arranca con la URL
  // correcta desde el primer frame, sin flashes ni estados de carga.
  const storage = FlutterSecureStorage();
  final urlGuardada = await storage.read(key: kClaveApiUrl);

  // Si hay URL guardada en disco, la inyectamos antes de crear el ProviderScope.
  // ApiUrlNotifier.build() leerá _urlInicial, que ya tendrá el valor correcto.
  if (urlGuardada != null) setUrlInicial(urlGuardada);

  if (_soportaFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await LocalNotificationsService.inicializar();
    await FcmService.inicializar();
  }

  runApp(const ProviderScope(child: VictorinoApp()));

  // ProviderScope es el contenedor raíz de Riverpod.
  // Sin él, ningún provider funcionaría.
  //
  // VictorinoApp es el widget raíz que configura:
  // - MaterialApp.router
  // - Tema global
  // - Router (GoRouter)



}

//  maradona@victorinostyle.com          Empleado1234!
//  jerson@victorinostyle.com            Empleado1234!

//  andres.lozano@gmail.com              Cliente1234!
//  carlos.rodriguez@gmail.com           Cliente1234!
//  miguel.perez@gmail.com               Cliente1234!









/*
RESUMEN DEL ARCHIVO
Este archivo (main.dart) cumple tres responsabilidades esenciales:

 1. Inicializar Flutter
WidgetsFlutterBinding.ensureInitialized() garantiza que Flutter esté
completamente listo antes de ejecutar cualquier código que necesite binding
(por ejemplo, inicializar plugins).

 2. Envolver la app en un ProviderScope
Esto es obligatorio para que Riverpod funcione.
ProviderScope es el contenedor raíz donde viven todos los providers.

Sin esto, ningún provider funcionaría.

 3. Lanzar el widget raíz VictorinoApp
Ese widget (definido en app.dart) configura:

• El router global
• El tema
• El MaterialApp.router

En otras palabras:
 main.dart solo arranca la app; toda la configuración vive en VictorinoApp.

 */