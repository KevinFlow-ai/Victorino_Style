// Aquí se general la entidad de dominio que representa una notificación in-app.
// Inmutable y sin dependencias con Flutter.
class Notificacion {
  const Notificacion({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.tipo,
    required this.enviadaPush,
    required this.fechaCreacion,
    this.idCita,
    this.fechaLectura,
  });

  final int id;
  final String titulo;
  final String cuerpo;

  // Aquí se pone el tipo del string tal como llega del backend: "RECORDATORIO_24H", "CONFIRMACION_RESERVA", etc.
  final String tipo;

  final bool enviadaPush;
  final DateTime fechaCreacion;

  // Aquí se pone null si la notificación no ha sido leída todavía.
  final DateTime? fechaLectura;

  // Aquí también se pone null si la notificación no está asociada a una cita concreta.
  final int? idCita;

  bool get esLeida => fechaLectura != null;

  Notificacion copyWith({DateTime? fechaLectura}) {
    return Notificacion(
      id: id,
      titulo: titulo,
      cuerpo: cuerpo,
      tipo: tipo,
      enviadaPush: enviadaPush,
      fechaCreacion: fechaCreacion,
      idCita: idCita,
      fechaLectura: fechaLectura ?? this.fechaLectura,
    );
  }
}

