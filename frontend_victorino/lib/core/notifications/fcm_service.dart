import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'local_notifications.dart';

/// Handler de background para mensajes FCM.
/// Sistema Híbrido (notification + data + HIGH priority):
/// Cuando la app está en BACKGROUND o CERRADA: Android/Firebase ya mostró
/// la notificación nativammente desde el payload "notification" sin WorkManager.
/// Este handler lo puede llamar Firebase igualmente; no mostramos la notificación local
/// para evitar duplicados (la nativa ya se mostró).
/// Cuando la app está en FOREGROUND: onMessage.listen() no llama a este handler;
/// LocalNotificationsService.mostrar() en el listener de foreground lo gestiona.
/// Corre en un isolate separado, por eso re-inicializa Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Con el payload "notification" presente, Android muestra la notificación
  // automáticamente en el sistema (sin retraso de WorkManager).
  // No mostramos local notification para evitar duplicados.
  debugPrint('Mensaje recibido (Android ya lo mostró) | titulo=${message.data["titulo"]} | tipo=${message.data["tipo"]}');
}

class FcmService {
  FcmService._();

  // Callback opcional que la capa de presentación puede registrar para
  // recargar la bandeja in-app cuando llega un mensaje push en foreground
  // o cuando el usuario pulsa una notificación desde background/app cerrada.
  // Se setea desde VictorinoApp tras el primer frame.
  static VoidCallback? onMensajeEntrante;

  // Callback opcional para registrar en el backend el nuevo token FCM
  // cuando Firebase lo rota (reinstalación, ciclo anual, revocación).
  // Recibe el nuevo token. Se setea desde VictorinoApp tras el primer frame.
  // Sin este callback, el backend conserva el token viejo y los pushes fallan.
  static Future<void> Function(String token)? onTokenRefrescado;

  /// Inicializa FCM: permisos, handler background, listener foreground,
  /// listener de token refresh y manejo de tap en notificación.
  static Future<void> inicializar() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        debugPrint('[FCM] Permiso concedido (authorized)');
      case AuthorizationStatus.provisional:
        debugPrint('[FCM] Permiso provisional (solo notificaciones silenciosas en iOS)');
      case AuthorizationStatus.denied:
        debugPrint('[FCM] Permiso DENEGADO — el usuario rechazó las notificaciones. '
            'Ve a Ajustes → Aplicaciones → frontend_victorino → Notificaciones y actívalas.');
      case AuthorizationStatus.notDetermined:
        debugPrint('[FCM] ⏳ Permiso aún no determinado');
    }

    // Listener de foreground: muestra notificación local y recarga la bandeja.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] titulo=${message.data["titulo"]} | tipo=${message.data["tipo"]}');
      LocalNotificationsService.mostrar(message);
      onMensajeEntrante?.call();
    });

    // Tap en notificación mientras la app estaba en BACKGROUND (pero abierta).
    // Recarga la bandeja para que el usuario vea la nueva notificación marcada.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] App abierta desde tap en background | tipo=${message.data["tipo"]}');
      onMensajeEntrante?.call();
    });

    // Tap en notificación con la app CERRADA: getInitialMessage() devuelve
    // el mensaje que causó la apertura. Recargamos la bandeja in-app.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App lanzada desde notificación | tipo=${initialMessage.data["tipo"]}');
      // La bandeja se recargará cuando el callback se configure en VictorinoApp.
      // Guardamos la señal para ejecutarla en cuanto el callback esté listo.
      _pendingInitialMessage = true;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      debugPrint('[FCM] Token FCM NULL — posibles causas:\n'
          '  · Emulador sin Google Play Services (usa imagen "Google APIs")\n'
          '  · Sin conexión a internet\n'
          '  · google-services.json incorrecto o desactualizado');
    } else {
      debugPrint('[FCM] Token obtenido (${token.length} chars): ${token.substring(0, 20)}...\n'
          '  Si acabas de REINSTALAR la app, este token es NUEVO.\n'
          '  Debes hacer LOGIN para que el backend registre el nuevo token\n'
          '  y pueda enviarte notificaciones push.');
    }

    // Listener de rotación de token: registra el nuevo token en el backend.
    // Sin esto, si FCM rota el token (reinstalación, ciclo ~anual, revocación),
    // el backend conserva el token viejo y los pushes fallan silenciosamente.
    FirebaseMessaging.instance.onTokenRefresh.listen((nuevoToken) {
      debugPrint('[FCM] Token renovado: ${nuevoToken.substring(0, 20)}...');
      onTokenRefrescado?.call(nuevoToken).catchError((e) {
        debugPrint('[FCM] Error al registrar token renovado en backend: $e');
      });
    });
  }

  // true si la app fue lanzada desde una notificación push (app estaba cerrada).
  // VictorinoApp lo consume una sola vez en initState para recargar la bandeja.
  static bool _pendingInitialMessage = false;

  /// Consume (y limpia) la señal de "lanzado desde notificación push".
  /// Devuelve true la primera vez, false en las siguientes.
  static bool consumirMensajeInicial() {
    if (_pendingInitialMessage) {
      _pendingInitialMessage = false;
      return true;
    }
    return false;
  }

  /// Devuelve el token FCM del dispositivo actual.
  static Future<String?> obtenerToken() async {
    return FirebaseMessaging.instance.getToken();
  }
}