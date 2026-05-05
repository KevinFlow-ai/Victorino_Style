// DTOs espejo de los records del paquete agenda del backend.
// ---------------------------------------------------------
// Este archivo contiene clases DTO (Data Transfer Objects) que sirven como
// "puentes" entre el JSON recibido del backend y las entidades del dominio.
// Su función es transformar datos crudos (Map<String, dynamic>) en objetos
// fuertemente tipados usados por la app.

import '../../domain/entidades/cita.dart';


// -----------------------------------------------------------------------------
// CONVERSIÓN ENTRE STRING Y ENUM EstadoCita
// -----------------------------------------------------------------------------
// El backend envía el estado como un String (ej: "CONFIRMADA").
// Aquí lo convertimos al enum EstadoCita usado en Flutter.

EstadoCita _estadoDesdeString(String s) {
  switch (s) {
    case 'CONFIRMADA': return EstadoCita.confirmada;
    case 'EN_PROCESO': return EstadoCita.enProceso;
    case 'COMPLETADA': return EstadoCita.completada;
    case 'CANCELADA_CLIENTE': return EstadoCita.canceladaCliente;
    case 'CANCELADA_PELUQUERIA': return EstadoCita.canceladaPeluqueria;
    case 'NO_PRESENTADO': return EstadoCita.noPresentado;
    default: return EstadoCita.confirmada; // fallback seguro
  }
}

// Convierte el enum EstadoCita a String para enviarlo al backend.
String estadoCitaAString(EstadoCita e) {
  switch (e) {
    case EstadoCita.confirmada: return 'CONFIRMADA';
    case EstadoCita.enProceso: return 'EN_PROCESO';
    case EstadoCita.completada: return 'COMPLETADA';
    case EstadoCita.canceladaCliente: return 'CANCELADA_CLIENTE';
    case EstadoCita.canceladaPeluqueria: return 'CANCELADA_PELUQUERIA';
    case EstadoCita.noPresentado: return 'NO_PRESENTADO';
  }
}


// -----------------------------------------------------------------------------
// DTO PARA CITA ADMINISTRATIVA (CitaAdminDto)
// -----------------------------------------------------------------------------
// Recibe un JSON del backend y lo convierte en una entidad CitaAdmin.
// Esta entidad es la que usa la UI y la lógica de negocio.

class CitaAdminDto {
  const CitaAdminDto(this.json);
  final Map<String, dynamic> json;

  // Convierte el JSON en una entidad CitaAdmin.
  CitaAdmin aEntidad() {
    // Función interna para recortar la hora a formato HH:mm.
    String hora(String key) {
      final v = json[key] as String;
      return v.length >= 5 ? v.substring(0, 5) : v;
    }

    return CitaAdmin(
      idCita: (json['idCita'] as num).toInt(),
      fecha: json['fecha'] as String,
      horaInicio: hora('horaInicio'),
      horaFin: hora('horaFin'),
      estado: _estadoDesdeString(json['estado'] as String),
      nota: json['nota'] as String?,
      idCliente: (json['idCliente'] as num?)?.toInt(),
      nombreCliente: json['nombreCliente'] as String,
      esInvitado: json['esInvitado'] as bool,
      idEmpleado: (json['idEmpleado'] as num).toInt(),
      nombreEmpleado: json['nombreEmpleado'] as String,
      fotoEmpleado: (json['fotoEmpleado'] as String?) ?? '',
      idServicio: (json['idServicio'] as num).toInt(),
      nombreServicio: json['nombreServicio'] as String,
      duracionMinutos: (json['duracionMinutos'] as num).toInt(),
      precioServicio: json['precioServicio'] as num,
    );
  }
}


// -----------------------------------------------------------------------------
// DTO PARA HISTORIAL DE CLIENTE
// -----------------------------------------------------------------------------
// Convierte un JSON que contiene datos del cliente + lista de citas.

class HistorialClienteDto {
  const HistorialClienteDto(this.json);
  final Map<String, dynamic> json;

  HistorialCliente aEntidad() {
    // Convierte la lista de citas del JSON en una lista de CitaAdmin.
    final citas = (json['citas'] as List<dynamic>? ?? [])
        .map((j) => CitaAdminDto(j as Map<String, dynamic>).aEntidad())
        .toList();

    return HistorialCliente(
      idCliente: (json['idCliente'] as num).toInt(),
      nombreCompleto: json['nombreCompleto'] as String,
      correo: json['correo'] as String,
      telefono: json['telefono'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      cuentaActiva: json['cuentaActiva'] as bool,
      totalCitas: (json['totalCitas'] as num).toInt(),
      citas: citas,
    );
  }
}


// -----------------------------------------------------------------------------
// DTO PARA AVISOS DE CLIENTE
// -----------------------------------------------------------------------------
// Convierte un JSON en un AvisoCliente, usado para mostrar alertas
// sobre clientes con cancelaciones frecuentes.

class AvisoClienteDto {
  const AvisoClienteDto(this.json);
  final Map<String, dynamic> json;

  AvisoCliente aEntidad() => AvisoCliente(
    idCliente: (json['idCliente'] as num).toInt(),
    nombreCompleto: json['nombreCompleto'] as String,
    correo: json['correo'] as String,
    cancelacionesUltimos30Dias: (json['cancelacionesUltimos30Dias'] as num).toInt(),
  );
}


// -----------------------------------------------------------------------------
// BODY PARA CREAR WALK-IN (POST /admin/citas/walk-in)
// -----------------------------------------------------------------------------
// Convierte un objeto DatosWalkIn en el JSON exacto que espera el backend.

Map<String, dynamic> walkInABody(DatosWalkIn d) => {
  'idEmpleado': d.idEmpleado,
  'idServicio': d.idServicio,
  'fecha': d.fecha,
  'horaInicio': '${d.horaInicio}:00', // backend espera HH:mm:ss
  'idCliente': d.idCliente,
  'nombreInvitado': d.nombreInvitado,
  'apellidosInvitado': d.apellidosInvitado,
  'telefonoInvitado': d.telefonoInvitado,
  'nota': d.nota,
};
