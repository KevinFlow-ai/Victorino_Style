// Punto de entrada de la app. Solo se encarga de:
// 1. Inicializar Flutter.
// 2. Inicializar Firebase (debe ser antes de runApp).
// 3. Registrar el handler de mensajes FCM en background.
// 4. Inicializar datos de localización (intl) para español de España.
// 5. Envolver la app en ProviderScope para Riverpod y lanzar VictorinoApp.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';


// *********  FIREBASE
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/notifications/fcm_service.dart';
import 'core/notifications/local_notifications.dart';

import 'app.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Asegura que Flutter está completamente inicializado.
  // Necesario si usas plugins o inicializaciones antes de runApp().

  // Carga los datos de DateFormat para los locales que usamos. Sin esto,
  // DateFormat.yMMMd('es') lanza LocaleDataException en runtime.
  await initializeDateFormatting('es_ES');

  // Inicializaciones de Firebase/FCM envueltas en try-catch para que,
  // aunque fallen (sin Google Play Services, sin red, token timeout…),
  // runApp() se llame siempre y la app no se quede en pantalla en blanco.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Handler para mensajes FCM cuando la app está cerrada o en background.
    // Debe registrarse antes de runApp y en el top-level (no dentro de un widget).
    // Inicializa las notificaciones locales (para foreground).
    await LocalNotificationsService.inicializar();

    // Inicializa FCM: registra el handler de background y escucha mensajes.
    await FcmService.inicializar();
  } catch (e, stack) {
    // Si Firebase/FCM falla (dispositivo sin Google Play Services, sin red,
    // google-services.json incorrecto…), la app sigue funcionando sin push.
    debugPrint('[main] Advertencia: error al inicializar Firebase/FCM: $e\n$stack');
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