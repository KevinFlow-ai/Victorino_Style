// Entidades de dominio del submódulo "empleados". Inmutables, no se serializan
// nunca tal cual: la capa data tiene su propio DTO espejo del backend.

// Empleado tal y como lo entiende la UI: lo justo para listas y detalles.
class Empleado {
  const Empleado({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.correo,
    required this.fotoUrl,
    required this.activo,
    required this.esAdministrador,
    this.telefono,
    this.horaDescanso,
    this.duracionDescansoMinutos,
  });

  final int id;
  final String nombre;
  final String apellidos;
  final String correo;
  final String? telefono;
  final String fotoUrl;
  final bool activo;
  final bool esAdministrador;
  // Hora de inicio del descanso fijo ("HH:mm"). Null si aún no se ha configurado.
  final String? horaDescanso;
  // Duración del descanso en minutos. Null si aún no se ha configurado.
  final int? duracionDescansoMinutos;

  // Helper para mostrar el nombre completo en la UI.
  String get nombreCompleto => nombre;
//   String get nombreCompleto => '$nombre $apellidos'.trim(); Aqui para el nombre y apellidos
}

// Datos de entrada para crear o editar un empleado. La foto va aparte (multipart).
class DatosEmpleado {
  const DatosEmpleado({
    required this.nombre,
    required this.apellidos,
    required this.correo,
    this.telefono,
    this.passwordProvisional,
  });

  final String nombre;
  final String apellidos;
  final String correo;
  final String? telefono;
  // Solo obligatoria al CREAR. En edición puede ser null para no cambiarla.
  final String? passwordProvisional;
}

// Resumen devuelto por la cancelación masiva de citas futuras de un empleado.
class ResumenCancelacionMasiva {
  const ResumenCancelacionMasiva({
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.citasCanceladas,
    required this.clientesNotificados,
    required this.citasOmitidas,
  });

  final int idEmpleado;
  final String nombreEmpleado;
  final int citasCanceladas;
  final int clientesNotificados;
  final int citasOmitidas;
}
