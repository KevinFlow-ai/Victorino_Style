// Caso de uso: obtener huecos disponibles para una fecha + servicio.
// Lo invoca el Paso 3 del wizard cada vez que el cliente elige un día distinto.

import '../../../shared/domain/entidades/hueco.dart';
import '../../../shared/domain/repositorios/citas_cliente_repositorio.dart';

class ObtenerDisponibilidad {
  ObtenerDisponibilidad(this._repositorio);
  final CitasClienteRepositorio _repositorio;

  Future<List<Hueco>> ejecutar({
    required int idServicio,
    required DateTime fecha,
    int? idEmpleado,
    int? idCitaExcluir,
  }) {
    return _repositorio.obtenerDisponibilidad(
      idServicio: idServicio,
      fecha: fecha,
      idEmpleado: idEmpleado,
      idCitaExcluir: idCitaExcluir,
    );
  }
}
