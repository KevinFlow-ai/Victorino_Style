// DTO espejo del record Java PerfilClienteResponse.
// Convierte el JSON del backend en la entidad PerfilCliente.

import '../../domain/entidades/perfil_cliente.dart';

class PerfilClienteDto {
  const PerfilClienteDto({
    required this.idCliente,
    required this.nombre,
    required this.apellidos,
    required this.correo,
    required this.pushActiva,
    this.telefono,
    this.fotoUrl,
  });

  final int idCliente;
  final String nombre;
  final String apellidos;
  final String correo;
  final String? telefono;
  final String? fotoUrl;
  final bool pushActiva;

  factory PerfilClienteDto.fromJson(Map<String, dynamic> json) {
    return PerfilClienteDto(
      idCliente: (json['idCliente'] as num).toInt(),
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String,
      correo: json['correo'] as String,
      telefono: json['telefono'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      pushActiva: json['pushActiva'] as bool,
    );
  }

  PerfilCliente aEntidad() => PerfilCliente(
        idCliente: idCliente,
        nombre: nombre,
        apellidos: apellidos,
        correo: correo,
        telefono: telefono,
        fotoUrl: fotoUrl,
        pushActiva: pushActiva,
      );
}
