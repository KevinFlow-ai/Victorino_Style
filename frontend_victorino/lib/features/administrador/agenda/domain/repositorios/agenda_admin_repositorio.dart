// Contrato del repositorio del submódulo agenda.
// -------------------------------------------------------------
// Este archivo define una INTERFAZ (abstract class) que especifica
// qué operaciones debe ofrecer el repositorio de agenda del admin.
//
// En Clean Architecture:
// - La UI llama a los casos de uso.
// - Los casos de uso llaman al REPOSITORIO (esta interfaz).
// - La implementación concreta (HTTP, local, mock, etc.) se hace en otro archivo.
//
// Esto permite cambiar la implementación sin afectar al resto del sistema.

import '../entidades/cita.dart';


// -----------------------------------------------------------------------------
// INTERFAZ DEL REPOSITORIO AgendaAdminRepositorio
// -----------------------------------------------------------------------------
// Cualquier clase que implemente esta interfaz debe proveer estos métodos.
// La implementación real está en AgendaAdminRepositorioImpl (HTTP con Dio).
abstract class AgendaAdminRepositorio {

  // ---------------------------------------------------------------------------
  // Obtener agenda global
  // ---------------------------------------------------------------------------
  // Devuelve una lista de citas entre dos fechas (YYYY-MM-DD).
  // Puede filtrar por empleado y por estado de la cita.
  Future<List<CitaAdmin>> agendaGlobal({
    required String desde,   // Formato: YYYY-MM-DD
    required String hasta,
    int? idEmpleado,         // Opcional
    EstadoCita? estado,      // Opcional
  });


  // ---------------------------------------------------------------------------
  // Obtener historial de un cliente
  // ---------------------------------------------------------------------------
  // Devuelve todas las citas pasadas de un cliente específico.
  Future<HistorialCliente> historialCliente(int idCliente);


  // ---------------------------------------------------------------------------
  // Crear una cita Walk-In
  // ---------------------------------------------------------------------------
  // Crea una cita rápida sin reserva previa.
  // Puede ser para un cliente registrado o un invitado.
  Future<CitaAdmin> crearWalkIn(DatosWalkIn datos);


  // ---------------------------------------------------------------------------
  // Obtener avisos de cancelaciones frecuentes
  // ---------------------------------------------------------------------------
  // Devuelve una lista de clientes que han cancelado demasiadas veces.
  Future<List<AvisoCliente>> avisosCancelacionesFrecuentes();

  // ---------------------------------------------------------------------------
  // Marcar cita como No Presentado
  // ---------------------------------------------------------------------------
  // Cambia el estado de una cita a NO_PRESENTADO.
  Future<void> marcarNoPresentado(int idCita);
}
