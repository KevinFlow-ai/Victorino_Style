// ============================================================================
// EstadoCita — enum
// ----------------------------------------------------------------------------
// Espejo del enum Java `EstadoCita` del backend. Se usa en la entidad
// `CitaCliente` y en los filtros de la pantalla de historial.
//
// El backend envía el valor como String (ej. "CONFIRMADA"). Lo parseamos con
// `EstadoCitaX.deString()` y lo serializamos con `name`.
// ============================================================================

enum EstadoCita {
  // La cita está reservada y aún no ha empezado.
  confirmada,
  // El empleado ya ha marcado al cliente como "atendiéndole".
  enProceso,
  // La cita terminó correctamente.
  completada,
  // El cliente la canceló desde la app.
  canceladaCliente,
  // La peluquería la canceló (baja del empleado, eliminación de cuenta, etc.).
  canceladaPeluqueria,
  // El cliente no acudió en el margen de tolerancia.
  noPresentado,
}

extension EstadoCitaX on EstadoCita {
  // Devuelve true si la cita aún está activa (CONFIRMADA o EN_PROCESO).
  // El Home y la pestaña Reservar usan esto para decidir si bloquear nuevas reservas.
  bool get esActiva =>
      this == EstadoCita.confirmada || this == EstadoCita.enProceso;

  // Devuelve true si la cita terminó en cualquier estado terminal (no se puede modificar).
  bool get esTerminal => !esActiva;

  // Texto legible para mostrar en la UI.
  String get etiqueta => switch (this) {
        EstadoCita.confirmada          => 'Confirmada',
        EstadoCita.enProceso           => 'En proceso',
        EstadoCita.completada          => 'Completada',
        EstadoCita.canceladaCliente    => 'Cancelada por ti',
        EstadoCita.canceladaPeluqueria => 'Cancelada por la peluquería',
        EstadoCita.noPresentado        => 'No presentado',
      };

  // Valor que viaja en el JSON al backend o que se recibe de él.
  String get backendValue => switch (this) {
        EstadoCita.confirmada          => 'CONFIRMADA',
        EstadoCita.enProceso           => 'EN_PROCESO',
        EstadoCita.completada          => 'COMPLETADA',
        EstadoCita.canceladaCliente    => 'CANCELADA_CLIENTE',
        EstadoCita.canceladaPeluqueria => 'CANCELADA_PELUQUERIA',
        EstadoCita.noPresentado        => 'NO_PRESENTADO',
      };

  // Conversión String → enum. Acepta cualquier formato del backend; si llega
  // un valor desconocido devuelve `confirmada` como fallback defensivo.
  static EstadoCita deString(String valor) => switch (valor.toUpperCase()) {
        'CONFIRMADA'           => EstadoCita.confirmada,
        'EN_PROCESO'           => EstadoCita.enProceso,
        'COMPLETADA'           => EstadoCita.completada,
        'CANCELADA_CLIENTE'    => EstadoCita.canceladaCliente,
        'CANCELADA_PELUQUERIA' => EstadoCita.canceladaPeluqueria,
        'NO_PRESENTADO'        => EstadoCita.noPresentado,
        _                      => EstadoCita.confirmada,
      };
}
