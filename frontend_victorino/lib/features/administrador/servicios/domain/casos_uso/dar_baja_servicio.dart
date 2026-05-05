import '../repositorios/servicio_admin_repositorio.dart';

class DarBajaServicio {
  DarBajaServicio(this._repositorio);
  final ServicioAdminRepositorio _repositorio;
  Future<void> ejecutar(int id) => _repositorio.darBaja(id);
}
