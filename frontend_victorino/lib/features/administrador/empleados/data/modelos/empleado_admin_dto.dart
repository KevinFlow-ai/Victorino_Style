// DTOs espejo de los records Java EmpleadoAdminResponse y CancelacionMasivaResponse.
// -----------------------------------------------------------------------------
// Estos DTOs representan exactamente la estructura JSON que envía el backend.
// La capa domain NO conoce estos DTOs: solo conoce las entidades puras.
// La capa data usa estos DTOs para convertir JSON → entidades de dominio.

import '../../domain/entidades/empleado.dart';


// -----------------------------------------------------------------------------
// DTO: EmpleadoAdminDto
// -----------------------------------------------------------------------------
// Representa un empleado tal como viene del backend.
// Luego se convierte en la entidad Empleado (dominio).
class EmpleadoAdminDto {
  const EmpleadoAdminDto({
    required this.idEmpleado,
    required this.nombre,
    required this.apellidos,
    required this.correo,
    required this.fotoUrl,
    required this.activo,
    required this.rol,
    required this.esAdministrador,
    this.telefono,
  });

  // Campos EXACTOS que vienen del backend
  final int idEmpleado;
  final String nombre;
  final String apellidos;
  final String correo;
  final String? telefono;
  final String fotoUrl;
  final bool activo;
  final String rol;
  final bool esAdministrador;

  // Constructor factory para crear el DTO desde JSON
  factory EmpleadoAdminDto.fromJson(Map<String, dynamic> json) {
    return EmpleadoAdminDto(
      idEmpleado: (json['idEmpleado'] as num).toInt(),
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String,
      correo: json['correo'] as String,
      telefono: json['telefono'] as String?,
      fotoUrl: (json['fotoUrl'] as String?) ?? '', // fallback si viene null
      activo: json['activo'] as bool,
      rol: json['rol'] as String,
      esAdministrador: json['esAdministrador'] as bool,
    );
  }

  // Conversión DTO → entidad de dominio.
  // La capa domain solo trabaja con Empleado, no con DTOs.
  Empleado aEntidad() => Empleado(
    id: idEmpleado,
    nombre: nombre,
    apellidos: apellidos,
    correo: correo,
    telefono: telefono,
    fotoUrl: fotoUrl,
    activo: activo,
    esAdministrador: esAdministrador,
  );
}


// -----------------------------------------------------------------------------
// DTO: CancelacionMasivaDto
// -----------------------------------------------------------------------------
// Representa la respuesta del backend cuando se cancelan citas masivamente
// por baja de un empleado.
class CancelacionMasivaDto {
  const CancelacionMasivaDto({
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.citasCanceladas,
    required this.clientesNotificados,
    required this.citasOmitidas,
  });

  final int idEmpleado;
  final String nombreEmpleado;
  final int citasCanceladas;
  final int clientesNotificados;
  final int citasOmitidas;

  // Constructor factory para crear el DTO desde JSON
  factory CancelacionMasivaDto.fromJson(Map<String, dynamic> json) {
    return CancelacionMasivaDto(
      idEmpleado: (json['idEmpleado'] as num).toInt(),
      nombreEmpleado: json['nombreEmpleado'] as String,
      citasCanceladas: (json['citasCanceladas'] as num).toInt(),
      clientesNotificados: (json['clientesNotificados'] as num).toInt(),
      citasOmitidas: (json['citasOmitidas'] as num).toInt(),
    );
  }

  // Conversión DTO → entidad de dominio.
  ResumenCancelacionMasiva aEntidad() => ResumenCancelacionMasiva(
    idEmpleado: idEmpleado,
    nombreEmpleado: nombreEmpleado,
    citasCanceladas: citasCanceladas,
    clientesNotificados: clientesNotificados,
    citasOmitidas: citasOmitidas,
  );
}
