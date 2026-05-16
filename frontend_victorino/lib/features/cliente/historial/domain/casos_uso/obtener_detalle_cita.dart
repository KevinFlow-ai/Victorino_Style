// Caso de uso: cargar el detalle de UNA cita propia.
// Pantalla "DetalleCita" del Historial.

import '../../../shared/domain/entidades/cita_cliente.dart';
import '../../../shared/domain/repositorios/citas_cliente_repositorio.dart';

class ObtenerDetalleCita {
  ObtenerDetalleCita(this._repositorio);
  final CitasClienteRepositorio _repositorio;

  Future<CitaCliente> ejecutar(int idCita) => _repositorio.obtenerCita(idCita);
}
