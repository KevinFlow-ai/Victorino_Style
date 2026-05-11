import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {
  LocalNotificationsService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── Es es el canal principal de notificaciones push: lo usa Firebase cuando la app está en background/cerrada.
  static const _androidChannel = AndroidNotificationChannel(
    'canal_victorino_principal',
    'Notificaciones Victorino Style',
    description: 'Canal principal de notificaciones push de la app oficial de Victorino Style',
    importance: Importance.max,
  );

  // ── Est es el canal in-app: se usa cuando la app está en FOREGROUND.
  // La notificación dentro de la app suena con una campana suave generada en res/raw/campana_interna.wav.
  static const _inappChannel = AndroidNotificationChannel(
    'canal_victorino_inapp',
    'Notificaciones internas Victorino Style',
    description: 'Sonido de campana suave para notificaciones recibidas mientras se usa la app',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('campana_interna'),
  );

  // Detalles reutilizables para el canal principal (background).
  static AndroidNotificationDetails get _androidDetails => AndroidNotificationDetails(
    _androidChannel.id,
    _androidChannel.name,
    channelDescription: _androidChannel.description,
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  // Estos son los detalles reutilizables para el canal dentro de la app (foreground) con el sonido de una campana suave.
  static AndroidNotificationDetails get _inappDetails => AndroidNotificationDetails(
    _inappChannel.id,
    _inappChannel.name,
    channelDescription: _inappChannel.description,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    sound: const RawResourceAndroidNotificationSound('campana_interna'),
    playSound: true,
  );

  /// Aquí se inicializa el plugin y se crean AMBOS canales de Android.
  /// Se llama una única vez desde main().
  static Future<void> inicializar() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // El Android 13+ (API 33) necesita permiso POST_NOTIFICATIONS explícito ──
    // flutter_local_notifications v21 requiere pedirlo aquí además de en el sistema de notificaciones push.
    // Sin esto, después de una (re)instalación en Android 13+ las notificaciones
    // locales (foreground) no aparecen aunque el permiso del sistema de notificaciones push esté concedido.
    final bool? granted = await androidPlugin?.requestNotificationsPermission();
    if (granted == false) {
      debugPrint('[LocalNotifications] Permiso POST_NOTIFICATIONS denegado en Android 13+. '
          'Las notificaciones dentro de la app (foreground) no se mostrarán '
          'hasta que el usuario conceda el permiso en Ajustes → Aplicaciones.');
    }

    // Aquí se crean ambos canales en Android 8+ (sin esto las notificaciones no suenan).
    await androidPlugin?.createNotificationChannel(_androidChannel);
    await androidPlugin?.createNotificationChannel(_inappChannel);
  }

  /// Aquí mostramos un banner local cuando la app está en FOREGROUND.
  /// Se usa el canal dentro de la app con un sonido de notificación de una campana suave (campana_interna.wav).
  /// El título y cuerpo vienen en message.data como claves "titulo" y "cuerpo".
  static Future<void> mostrar(RemoteMessage message) async {
    final titulo = message.data['titulo']?.toString().isNotEmpty == true
        ? message.data['titulo']
        : message.notification?.title;
    final cuerpo = message.data['cuerpo']?.toString().isNotEmpty == true
        ? message.data['cuerpo']
        : message.notification?.body;

    if (titulo == null && cuerpo == null) return;

    await _plugin.show(
      id: message.hashCode,
      title: titulo,
      body: cuerpo,
      notificationDetails: NotificationDetails(
        android: _inappDetails,   // Este es el canal in app con sonido de campana suave.
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Mostramos una notificación local directamente sin necesitar un RemoteMessage.
  /// Se usa en el flujo de login explícito para evitar el roundtrip FCM y el
  /// throttling de prioridad alta de Android en logins rápidos consecutivos.
  static Future<void> mostrarLocal(String titulo, String cuerpo) async {
    final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _plugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: NotificationDetails(
        android: _inappDetails,   // Canal in-app con campana_interna.wav
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Esto recibe directamente el mapa de datos (útil desde el isolate
  /// de background donde solo se tiene RemoteMessage.data).
  static Future<void> mostrarDesdeData(Map<String, dynamic> data, {int id = 0}) async {
    final titulo = data['titulo']?.toString();
    final cuerpo  = data['cuerpo']?.toString();
    if ((titulo == null || titulo.isEmpty) && (cuerpo == null || cuerpo.isEmpty)) return;

    await _plugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: NotificationDetails(
        android: _androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}