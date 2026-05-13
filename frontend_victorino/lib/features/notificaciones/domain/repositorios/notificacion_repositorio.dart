import '../entidades/notificacion.dart';

// Interfaz que define cómo se obtiene y manipula la bandeja de notificaciones.
// Las capas superiores (casos de uso, notifiers) dependen de esta abstracción,
// nunca de la implementación concreta HTTP.
abstract class NotificacionesRepositorio {
  /// Devuelve todas las notificaciones del usuario autenticado (el JWT es suficiente).
  Future<List<Notificacion>> obtenerBandeja();

  /// Marca la notificación idNotificacion como leída en el backend.
  Future<void> marcarLeida(int idNotificacion);

  /// Registra el token FCM del dispositivo en el backend para recibir push.
  /// [esLoginExplicito] = true  → login con credenciales (salta notificación bienvenida).
  /// [esLoginExplicito] = false → restauración de sesión (sin notificación).
  Future<void> registrarDeviceToken(int idUsuario, String tokenFcm, {bool esLoginExplicito = false});
}

