import '../repositorios/empleado_admin_repositorio.dart';

// Caso de uso: baja lógica de un empleado.
class DarBajaEmpleado {
  DarBajaEmpleado(this._repositorio);

  final EmpleadoAdminRepositorio _repositorio;

  Future<void> ejecutar(int id) => _repositorio.darBaja(id);
}
