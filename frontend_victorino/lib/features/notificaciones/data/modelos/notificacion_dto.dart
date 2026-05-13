import '../../domain/entidades/notificacion.dart';

// DTO que mapea el JSON del backend al dominio de Flutter.
// El backend devuelve:
//   { "id", "titulo", "cuerpo", "tipo", "idCita", "enviadaPush",
//     "fechaCreacion", "fechaLectura" }
class NotificacionDto {
  const NotificacionDto({
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
  final String tipo;
  final bool enviadaPush;
  final DateTime fechaCreacion;
  final int? idCita;
  final DateTime? fechaLectura;

  factory NotificacionDto.fromJson(Map<String, dynamic> json) {
    return NotificacionDto(
      id: json['id'] as int,
      titulo: json['titulo'] as String? ?? '',
      cuerpo: json['cuerpo'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      enviadaPush: json['enviadaPush'] as bool? ?? false,
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      idCita: json['idCita'] as int?,
      fechaLectura: json['fechaLectura'] != null
          ? DateTime.parse(json['fechaLectura'] as String)
          : null,
    );
  }

  Notificacion aEntidad() {
    return Notificacion(
      id: id,
      titulo: titulo,
      cuerpo: cuerpo,
      tipo: tipo,
      enviadaPush: enviadaPush,
      fechaCreacion: fechaCreacion,
      idCita: idCita,
      fechaLectura: fechaLectura,
    );
  }
}

