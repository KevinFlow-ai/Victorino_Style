// ============================================================================
// CitaClienteDto — DTO espejo del record Java CitaClienteResponse
// ----------------------------------------------------------------------------
// Capa data: convierte el JSON crudo del backend en una entidad de dominio.
// La UI nunca toca este DTO; siempre lo recibe ya convertido a CitaCliente.
// ============================================================================

import '../../domain/entidades/cita_cliente.dart';
import '../../domain/entidades/estado_cita.dart';

class CitaClienteDto {
  const CitaClienteDto({
    required this.idCita,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.apellidosEmpleado,
    required this.fotoEmpleado,
    required this.idServicio,
    required this.nombreServicio,
    required this.duracionMinutos,
    required this.precioServicio,
    required this.fotoServicio,
    this.nota,
  });

  final int idCita;
  final String fecha;          // "YYYY-MM-DD" tal y como llega del backend.
  final String horaInicio;     // "HH:mm:ss".
  final String horaFin;        // "HH:mm:ss".
  final String estado;         // Valor crudo del enum (ej. "CONFIRMADA").
  final String? nota;
  final int idEmpleado;
  final String nombreEmpleado;
  final String apellidosEmpleado;
  final String fotoEmpleado;
  final int idServicio;
  final String nombreServicio;
  final int duracionMinutos;
  final num precioServicio;
  final String fotoServicio;

  // Construye el DTO desde el Map<String, dynamic> que devuelve Jackson en el JSON.
  factory CitaClienteDto.fromJson(Map<String, dynamic> json) {
    return CitaClienteDto(
      idCita: (json['idCita'] as num).toInt(),
      fecha: json['fecha'] as String,
      horaInicio: json['horaInicio'] as String,
      horaFin: json['horaFin'] as String,
      estado: json['estado'] as String,
      nota: json['nota'] as String?,
      idEmpleado: (json['idEmpleado'] as num).toInt(),
      nombreEmpleado: json['nombreEmpleado'] as String,
      apellidosEmpleado: json['apellidosEmpleado'] as String,
      fotoEmpleado: (json['fotoEmpleado'] as String?) ?? '',
      idServicio: (json['idServicio'] as num).toInt(),
      nombreServicio: json['nombreServicio'] as String,
      duracionMinutos: (json['duracionMinutos'] as num).toInt(),
      precioServicio: json['precioServicio'] as num,
      fotoServicio: (json['fotoServicio'] as String?) ?? '',
    );
  }

  // Convierte el DTO en la entidad de dominio que usa la UI.
  CitaCliente aEntidad() => CitaCliente(
        idCita: idCita,
        fecha: DateTime.parse(fecha),
        horaInicio: horaInicio,
        horaFin: horaFin,
        estado: EstadoCitaX.deString(estado),
        nota: nota,
        idEmpleado: idEmpleado,
        nombreEmpleado: nombreEmpleado,
        apellidosEmpleado: apellidosEmpleado,
        fotoEmpleado: fotoEmpleado,
        idServicio: idServicio,
        nombreServicio: nombreServicio,
        duracionMinutos: duracionMinutos,
        precioServicio: precioServicio,
        fotoServicio: fotoServicio,
      );
}
