// DTO espejo del record Java EmpleadoPublicoResponse.
// Convierte el JSON del backend en la entidad de dominio EmpleadoPublico.

import '../../domain/entidades/empleado_publico.dart';

class EmpleadoPublicoDto {
  const EmpleadoPublicoDto({
    required this.idEmpleado,
    required this.nombre,
    required this.apellidos,
    required this.fotoUrl,
  });

  final int idEmpleado;
  final String nombre;
  final String apellidos;
  final String fotoUrl;

  factory EmpleadoPublicoDto.fromJson(Map<String, dynamic> json) {
    return EmpleadoPublicoDto(
      idEmpleado: (json['idEmpleado'] as num).toInt(),
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String,
      fotoUrl: (json['fotoUrl'] as String?) ?? '',
    );
  }

  EmpleadoPublico aEntidad() => EmpleadoPublico(
        idEmpleado: idEmpleado,
        nombre: nombre,
        apellidos: apellidos,
        fotoUrl: fotoUrl,
      );
}
