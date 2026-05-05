import '../entidades/servicio.dart';
import '../repositorios/servicio_admin_repositorio.dart';

class ObtenerServicios {
  ObtenerServicios(this._repositorio);

  final ServicioAdminRepositorio _repositorio;

  Future<List<Servicio>> ejecutar({bool incluirInactivos = false}) =>
      _repositorio.listar(incluirInactivos: incluirInactivos);
}
