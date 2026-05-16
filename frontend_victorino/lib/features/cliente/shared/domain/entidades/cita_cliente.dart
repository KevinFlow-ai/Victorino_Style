// ============================================================================
// CitaCliente — entidad de dominio
// ----------------------------------------------------------------------------
// Espejo limpio del DTO `CitaClienteResponse` del backend. La UI del cliente
// (Home, Reservar, Historial, Detalle) solo trabaja con esta entidad.
//
// Se diferencia de la entidad del admin en que:
//   - No incluye datos de cliente (siempre es el usuario autenticado).
//   - Incluye la foto del servicio además de la del empleado.
// ============================================================================

import 'estado_cita.dart';

class CitaCliente {
  const CitaCliente({
    required this.idCita,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.apellidosEmpleado,
    required this.fotoEmpleado,
    required this.idServicio,
    required this.nombreServicio,
    required this.duracionMinutos,
    required this.precioServicio,
    required this.fotoServicio,
    this.nota,
  });

  // ID interno de la cita en el backend.
  final int idCita;

  // Día de la cita (sin componente de hora).
  final DateTime fecha;

  // Hora de inicio en formato "HH:mm:ss" (lo guardamos como String para no perder ceros).
  // El frontend solo muestra los 5 primeros caracteres (HH:mm).
  final String horaInicio;
  final String horaFin;

  // Estado actual de la cita (ver enum EstadoCita).
  final EstadoCita estado;

  // Nota libre dejada por el cliente al reservar. Puede ser null o cadena vacía.
  final String? nota;

  // Datos del empleado asignado.
  final int idEmpleado;
  final String nombreEmpleado;
  final String apellidosEmpleado;
  // Ruta RELATIVA de la foto (ej. "/uploads/empleados/abc.jpg").
  // Combinar con ApiEndpoints.urlImagen() para obtener URL absoluta.
  final String fotoEmpleado;

  // Datos del servicio reservado.
  final int idServicio;
  final String nombreServicio;
  final int duracionMinutos;
  final num precioServicio;
  final String fotoServicio;

  // Helpers cosméticos para la UI.
  String get nombreCompletoEmpleado =>
      '$nombreEmpleado $apellidosEmpleado'.trim();

  String get horaInicioCorta =>
      horaInicio.length >= 5 ? horaInicio.substring(0, 5) : horaInicio;

  String get horaFinCorta =>
      horaFin.length >= 5 ? horaFin.substring(0, 5) : horaFin;
}
