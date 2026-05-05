// Entidades del submódulo "agenda" del admin.

// Estados posibles de una cita. Igual que el enum del backend.
enum EstadoCita {
  confirmada,
  enProceso,
  completada,
  canceladaCliente,
  canceladaPeluqueria,
  noPresentado,
}

// Cita tal y como la pinta el panel admin: incluye todos los datos para que la UI
// no tenga que cruzarlos con otras llamadas.
class CitaAdmin {
  const CitaAdmin({
    required this.idCita,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    required this.nombreCliente,
    required this.esInvitado,
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.fotoEmpleado,
    required this.idServicio,
    required this.nombreServicio,
    required this.duracionMinutos,
    required this.precioServicio,
    this.idCliente,
    this.nota,
  });

  final int idCita;
  final String fecha;       // YYYY-MM-DD
  final String horaInicio;  // HH:mm
  final String horaFin;     // HH:mm
  final EstadoCita estado;
  final String? nota;
  final int? idCliente;
  final String nombreCliente;
  final bool esInvitado;
  final int idEmpleado;
  final String nombreEmpleado;
  final String fotoEmpleado;
  final int idServicio;
  final String nombreServicio;
  final int duracionMinutos;
  final num precioServicio;
}

// Datos para crear un walk-in. XOR cliente registrado / invitado.
class DatosWalkIn {
  const DatosWalkIn({
    required this.idEmpleado,
    required this.idServicio,
    required this.fecha,
    required this.horaInicio,
    this.idCliente,
    this.nombreInvitado,
    this.apellidosInvitado,
    this.telefonoInvitado,
    this.nota,
  });

  final int idEmpleado;
  final int idServicio;
  final String fecha;       // YYYY-MM-DD
  final String horaInicio;  // HH:mm
  final int? idCliente;
  final String? nombreInvitado;
  final String? apellidosInvitado;
  final String? telefonoInvitado;
  final String? nota;
}

// Historial de un cliente concreto.
class HistorialCliente {
  const HistorialCliente({
    required this.idCliente,
    required this.nombreCompleto,
    required this.correo,
    required this.cuentaActiva,
    required this.totalCitas,
    required this.citas,
    this.telefono,
    this.fotoUrl,
  });

  final int idCliente;
  final String nombreCompleto;
  final String correo;
  final String? telefono;
  final String? fotoUrl;
  final bool cuentaActiva;
  final int totalCitas;
  final List<CitaAdmin> citas;
}

// Aviso informativo de un cliente con varias cancelaciones recientes.
class AvisoCliente {
  const AvisoCliente({
    required this.idCliente,
    required this.nombreCompleto,
    required this.correo,
    required this.cancelacionesUltimos30Dias,
  });

  final int idCliente;
  final String nombreCompleto;
  final String correo;
  final int cancelacionesUltimos30Dias;
}
