// Casos de uso del submódulo agenda. Agrupados en un único archivo por brevedad.
// -----------------------------------------------------------------------------
// Los casos de uso representan acciones específicas del dominio.
// Cada caso de uso recibe un repositorio y expone un método ejecutar().
// La UI nunca llama directamente al repositorio: siempre pasa por un caso de uso.

import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/failure.dart';
import '../entidades/cita.dart';
import '../repositorios/agenda_admin_repositorio.dart';


// -----------------------------------------------------------------------------
// CASO DE USO: Obtener agenda global
// -----------------------------------------------------------------------------
// Este caso de uso simplemente delega en el repositorio.
// Se usa para cargar la agenda del día (o rango de días).
class ObtenerAgendaGlobal {
  ObtenerAgendaGlobal(this._r);
  final AgendaAdminRepositorio _r;

  // Ejecuta la llamada al repositorio.
  Future<List<CitaAdmin>> ejecutar({
    required String desde,
    required String hasta,
    int? idEmpleado,
    EstadoCita? estado,
  }) =>
      _r.agendaGlobal(
        desde: desde,
        hasta: hasta,
        idEmpleado: idEmpleado,
        estado: estado,
      );
}


// -----------------------------------------------------------------------------
// CASO DE USO: Obtener historial de un cliente
// -----------------------------------------------------------------------------
// Devuelve todas las citas pasadas de un cliente.
class ObtenerHistorialCliente {
  ObtenerHistorialCliente(this._r);
  final AgendaAdminRepositorio _r;

  Future<HistorialCliente> ejecutar(int idCliente) =>
      _r.historialCliente(idCliente);
}


// -----------------------------------------------------------------------------
// CASO DE USO: Crear una cita Walk-In
// -----------------------------------------------------------------------------
// Este caso de uso contiene lógica de validación antes de llamar al repositorio.
// Un Walk-In puede ser:
// - un cliente registrado (idCliente != null)
// - un invitado (nombreInvitado + apellidosInvitado)
//
// Pero NO pueden ser ambos a la vez y NO puede ser ninguno.
// Por eso se hace una validación tipo XOR.
class CrearWalkIn {
  CrearWalkIn(this._r);
  final AgendaAdminRepositorio _r;

  Future<CitaAdmin> ejecutar(DatosWalkIn datos) {
    // ¿El usuario seleccionó un cliente registrado?
    final esCliente = datos.idCliente != null;

    // ¿El usuario introdujo datos de invitado?
    final esInvitado =
        (datos.nombreInvitado ?? '').isNotEmpty &&
            (datos.apellidosInvitado ?? '').isNotEmpty;

    // Validación XOR:
    // - No puede ser cliente y a la vez invitado.
    // - No puede ser ninguno de los dos.
    if (esCliente == esInvitado) {
      throw ApiException(
        const FailureValidacion(
          'Debes elegir un cliente registrado o introducir los datos de un invitado',
          {},
        ),
      );
    }

    // Si pasa la validación, se crea la cita.
    return _r.crearWalkIn(datos);
  }
}


// -----------------------------------------------------------------------------
// CASO DE USO: Obtener avisos de cancelaciones frecuentes
// -----------------------------------------------------------------------------
// Devuelve una lista de clientes que han cancelado demasiadas veces.
class ObtenerAvisosCancelaciones {
  ObtenerAvisosCancelaciones(this._r);
  final AgendaAdminRepositorio _r;

  Future<List<AvisoCliente>> ejecutar() =>
      _r.avisosCancelacionesFrecuentes();
}

// -----------------------------------------------------------------------------
// CASO DE USO: Marcar cita como No Presentado
// -----------------------------------------------------------------------------
class MarcarNoPresentado {
  MarcarNoPresentado(this._r);
  final AgendaAdminRepositorio _r;

  Future<void> ejecutar(int idCita) =>
      _r.marcarNoPresentado(idCita);
}
