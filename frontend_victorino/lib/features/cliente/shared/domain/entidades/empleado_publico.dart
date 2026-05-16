// ============================================================================
// EmpleadoPublico — entidad de dominio
// ----------------------------------------------------------------------------
// Espejo del DTO `EmpleadoPublicoResponse` del backend. Es la vista del empleado
// que ve el cliente al elegir peluquero en el Paso 2 del wizard.
// Solo nombre, apellidos y foto; no se expone correo, teléfono ni configuración.
// ============================================================================

class EmpleadoPublico {
  const EmpleadoPublico({
    required this.idEmpleado,
    required this.nombre,
    required this.apellidos,
    required this.fotoUrl,
  });

  final int idEmpleado;
  final String nombre;
  final String apellidos;
  final String fotoUrl;

  String get nombreCompleto => '$nombre $apellidos'.trim();
}
