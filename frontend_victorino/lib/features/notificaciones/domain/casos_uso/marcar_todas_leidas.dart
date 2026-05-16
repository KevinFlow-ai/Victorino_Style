// Caso de uso: marcar todas las notificaciones del usuario como leídas.
// Lo invoca el botón del bottom sheet del Home y de la pantalla de Bandeja.

import '../repositorios/notificacion_repositorio.dart';

class MarcarTodasLeidas {
  MarcarTodasLeidas(this._repositorio);
  final NotificacionesRepositorio _repositorio;

  Future<void> ejecutar() => _repositorio.marcarTodasLeidas();
}
