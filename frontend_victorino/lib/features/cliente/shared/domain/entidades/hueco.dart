// ============================================================================
// Hueco — entidad de dominio
// ----------------------------------------------------------------------------
// Espejo del DTO HuecoDisponibleResponse del backend.
// Cada Hueco representa una franja horaria libre para reservar en el Paso 3
// del wizard, con la información del empleado que la atendería.
// ============================================================================

class Hueco {
  const Hueco({
    required this.horaInicio,
    required this.horaFin,
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.fotoEmpleado,
  });

  // Hora de inicio del hueco en formato "HH:mm:ss" tal y como llega del backend.
  final String horaInicio;
  final String horaFin;

  // Empleado asignado a ese hueco.
  //  - En modo "empleado concreto": coincide con el seleccionado en el Paso 2.
  //  - En modo "Cualquiera": el de menor carga ese día.
  final int idEmpleado;
  final String nombreEmpleado;
  final String fotoEmpleado;

  // Helpers cosméticos para el chip de hora.
  String get horaInicioCorta =>
      horaInicio.length >= 5 ? horaInicio.substring(0, 5) : horaInicio;

  String get horaFinCorta =>
      horaFin.length >= 5 ? horaFin.substring(0, 5) : horaFin;
}
