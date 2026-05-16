// Caso de uso: cancelar una cita propia desde el Historial o desde el Home.
// El backend se encarga de notificar al empleado afectado (CANCELACION_CLIENTE).

import '../../../shared/domain/repositorios/citas_cliente_repositorio.dart';

class CancelarCita {
  CancelarCita(this._repositorio);
  final CitasClienteRepositorio _repositorio;

  Future<void> ejecutar(int idCita) => _repositorio.cancelar(idCita);
}
