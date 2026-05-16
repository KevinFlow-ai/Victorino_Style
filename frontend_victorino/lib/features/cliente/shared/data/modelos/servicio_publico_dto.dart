// DTO espejo del record Java ServicioPublicoResponse.
// Convierte el JSON del backend en la entidad de dominio ServicioPublico.

import '../../domain/entidades/servicio_publico.dart';

class ServicioPublicoDto {
  const ServicioPublicoDto({
    required this.idServicio,
    required this.nombre,
    required this.duracionMinutos,
    required this.precio,
    required this.fotoUrl,
    this.descripcion,
  });

  final int idServicio;
  final String nombre;
  final String? descripcion;
  final int duracionMinutos;
  final num precio;
  final String fotoUrl;

  factory ServicioPublicoDto.fromJson(Map<String, dynamic> json) {
    return ServicioPublicoDto(
      idServicio: (json['idServicio'] as num).toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      duracionMinutos: (json['duracionMinutos'] as num).toInt(),
      precio: json['precio'] as num,
      fotoUrl: (json['fotoUrl'] as String?) ?? '',
    );
  }

  ServicioPublico aEntidad() => ServicioPublico(
        idServicio: idServicio,
        nombre: nombre,
        descripcion: descripcion,
        duracionMinutos: duracionMinutos,
        precio: precio,
        fotoUrl: fotoUrl,
      );
}
