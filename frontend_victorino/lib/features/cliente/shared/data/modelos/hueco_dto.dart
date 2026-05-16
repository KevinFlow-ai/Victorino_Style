// DTO espejo del record Java HuecoDisponibleResponse.
// Convierte el JSON del backend en la entidad Hueco.

import '../../domain/entidades/hueco.dart';

class HuecoDto {
  const HuecoDto({
    required this.horaInicio,
    required this.horaFin,
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.fotoEmpleado,
  });

  final String horaInicio;
  final String horaFin;
  final int idEmpleado;
  final String nombreEmpleado;
  final String fotoEmpleado;

  factory HuecoDto.fromJson(Map<String, dynamic> json) {
    return HuecoDto(
      horaInicio: json['horaInicio'] as String,
      horaFin: json['horaFin'] as String,
      idEmpleado: (json['idEmpleado'] as num).toInt(),
      nombreEmpleado: json['nombreEmpleado'] as String,
      fotoEmpleado: (json['fotoEmpleado'] as String?) ?? '',
    );
  }

  Hueco aEntidad() => Hueco(
        horaInicio: horaInicio,
        horaFin: horaFin,
        idEmpleado: idEmpleado,
        nombreEmpleado: nombreEmpleado,
        fotoEmpleado: fotoEmpleado,
      );
}
