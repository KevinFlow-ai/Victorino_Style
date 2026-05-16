// Caso de uso: obtener la cita activa (CONFIRMADA o EN_PROCESO) más próxima del
// cliente. La pestaña Reservar lo usa para mostrar el "bloqueo preventivo" si ya
// tiene una activa, y el Home para pintar la card "Mi próxima cita".

import '../../../shared/domain/entidades/cita_cliente.dart';
import '../../../shared/domain/repositorios/citas_cliente_repositorio.dart';

class ObtenerCitaActiva {
  ObtenerCitaActiva(this._repositorio);
  final CitasClienteRepositorio _repositorio;

  // Devuelve null si el cliente no tiene ninguna cita activa.
  Future<CitaCliente?> ejecutar() => _repositorio.obtenerCitaActiva();
}
