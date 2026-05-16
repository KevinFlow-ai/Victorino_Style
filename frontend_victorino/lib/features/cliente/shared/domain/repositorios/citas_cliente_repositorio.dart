// ============================================================================
// CitasClienteRepositorio — contrato compartido por reservar/ e historial/
// ----------------------------------------------------------------------------
// Agrupa TODAS las operaciones REST sobre citas del cliente final.
// Lo implementa una sola clase HTTP en la capa data, y lo consumen los casos
// de uso de los submódulos Home, Reservar e Historial.
// ============================================================================

import '../entidades/cita_cliente.dart';
import '../entidades/datos_reserva.dart';
import '../entidades/estado_cita.dart';
import '../entidades/hueco.dart';

abstract class CitasClienteRepositorio {
  // Lista historial completo (o filtrado por estado).
  Future<List<CitaCliente>> listarMisCitas({EstadoCita? estado});

  // Detalle de una cita concreta del cliente.
  Future<CitaCliente> obtenerCita(int idCita);

  // Cita activa (CONFIRMADA o EN_PROCESO) más próxima. Null si no hay.
  Future<CitaCliente?> obtenerCitaActiva();

  // Calcula los huecos disponibles para el wizard (Paso 3).
  // idEmpleado puede ser null → modo "Cualquiera disponible".
  // idCitaExcluir solo se usa en modo edición.
  Future<List<Hueco>> obtenerDisponibilidad({
    required int idServicio,
    required DateTime fecha,
    int? idEmpleado,
    int? idCitaExcluir,
  });

  // Reservar nueva cita. Devuelve la cita creada (con id asignado por el backend).
  Future<CitaCliente> reservar(DatosReserva datos);

  // Modificar una cita existente. Devuelve la cita actualizada.
  Future<CitaCliente> modificar(int idCita, DatosReserva datos);

  // Cancelar (cambia estado a CANCELADA_CLIENTE en el backend).
  Future<void> cancelar(int idCita);
}
