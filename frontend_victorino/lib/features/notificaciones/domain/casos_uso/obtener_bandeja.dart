import '../entidades/notificacion.dart';
import '../repositorios/notificacion_repositorio.dart';

/// Esta clase es para llevar a cabo el siguiente caso de uso: obtener la bandeja de notificaciones del usuario autenticado.
class ObtenerBandeja {
  const ObtenerBandeja(this._repo);
  final NotificacionesRepositorio _repo;

  Future<List<Notificacion>> ejecutar() => _repo.obtenerBandeja();
}


