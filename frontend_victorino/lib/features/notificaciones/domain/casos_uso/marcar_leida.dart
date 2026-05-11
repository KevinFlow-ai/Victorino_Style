import '../repositorios/notificacion_repositorio.dart';

/// Esta clase es para llevar a cabo el siguiente caso de uso: marcar una notificación como leída en el backend.
class MarcarLeida {
  const MarcarLeida(this._repo);
  final NotificacionesRepositorio _repo;

  Future<void> ejecutar(int idNotificacion) =>
      _repo.marcarLeida(idNotificacion);
}

