import '../repositorios/notificacion_repositorio.dart';

// Esta clase es para llevar a cabo el siguiente caso de uso: registra el token FCM del dispositivo en el backend.
// esLoginExplicito = true  → el usuario acaba de escribir credenciales: el backend enviará
//                            la notificación de bienvenida (push + in-app).
// esLoginExplicito = false → restauración de sesión (splash): sin notificación de bienvenida.
class RegistrarDeviceToken {
  final NotificacionesRepositorio _repositorio;

  const RegistrarDeviceToken(this._repositorio);

  Future<void> ejecutar(int idUsuario, String tokenFcm, {bool esLoginExplicito = false}) =>
      _repositorio.registrarDeviceToken(idUsuario, tokenFcm, esLoginExplicito: esLoginExplicito);
}


