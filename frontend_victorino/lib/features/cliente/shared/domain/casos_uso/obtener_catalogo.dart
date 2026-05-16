// Casos de uso del catálogo público: simples wrappers que delegan en el repositorio.

import '../entidades/empleado_publico.dart';
import '../entidades/servicio_publico.dart';
import '../repositorios/catalogo_repositorio.dart';

class ObtenerServicios {
  ObtenerServicios(this._repositorio);
  final CatalogoRepositorio _repositorio;

  Future<List<ServicioPublico>> ejecutar() => _repositorio.obtenerServicios();
}

class ObtenerEmpleadosPublicos {
  ObtenerEmpleadosPublicos(this._repositorio);
  final CatalogoRepositorio _repositorio;

  Future<List<EmpleadoPublico>> ejecutar() => _repositorio.obtenerEmpleados();
}
