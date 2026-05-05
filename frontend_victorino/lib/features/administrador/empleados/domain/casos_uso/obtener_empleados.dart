import '../entidades/empleado.dart';
import '../repositorios/empleado_admin_repositorio.dart';

// Caso de uso: lista de empleados (con o sin inactivos).
class ObtenerEmpleados {
  ObtenerEmpleados(this._repositorio);

  final EmpleadoAdminRepositorio _repositorio;

  Future<List<Empleado>> ejecutar({bool incluirInactivos = false}) {
    return _repositorio.listar(incluirInactivos: incluirInactivos);
  }
}
