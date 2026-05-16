// ============================================================================
// DatosReserva — entidad inmutable
// ----------------------------------------------------------------------------
// Estado acumulado del wizard de reserva del cliente. Cada paso del wizard
// rellena uno de los campos. Cuando el cliente pulsa "Confirmar reserva" en el
// Paso 4, esta entidad se convierte en un body JSON al POST /cliente/citas.
// ============================================================================

class DatosReserva {
  const DatosReserva({
    this.idServicio,
    this.idEmpleado,
    this.fecha,
    this.horaInicio,
    this.nota,
    this.cualquieraDisponible = false,
  });

  // Paso 1: servicio elegido.
  final int? idServicio;

  // Paso 2: empleado elegido. null cuando el cliente quiso "Cualquiera disponible".
  final int? idEmpleado;

  // Paso 3: día y hora elegidos.
  final DateTime? fecha;
  // "HH:mm:ss" tal y como vino del Hueco seleccionado.
  final String? horaInicio;

  // Paso 4: nota opcional.
  final String? nota;

  // Si true, el cliente eligió "Cualquiera" en el Paso 2 y el backend hará
  // fallback si el empleado mostrado en el chip queda ocupado al confirmar.
  final bool cualquieraDisponible;

  // Crea una copia inmutable cambiando solo los campos indicados.
  // Cada paso del wizard lo usa para rellenar su porción.
  DatosReserva copyWith({
    int? idServicio,
    int? idEmpleado,
    bool limpiarEmpleado = false,
    DateTime? fecha,
    String? horaInicio,
    String? nota,
    bool? cualquieraDisponible,
  }) {
    return DatosReserva(
      idServicio: idServicio ?? this.idServicio,
      idEmpleado: limpiarEmpleado ? null : (idEmpleado ?? this.idEmpleado),
      fecha: fecha ?? this.fecha,
      horaInicio: horaInicio ?? this.horaInicio,
      nota: nota ?? this.nota,
      cualquieraDisponible: cualquieraDisponible ?? this.cualquieraDisponible,
    );
  }

  // Helpers de validación para habilitar/deshabilitar el botón "Siguiente".
  bool get tieneServicio => idServicio != null;
  bool get tieneEmpleadoOComodin => idEmpleado != null || cualquieraDisponible;
  bool get tieneFechaYHora => fecha != null && horaInicio != null;
  bool get esCompleto =>
      tieneServicio && tieneEmpleadoOComodin && tieneFechaYHora;
}
