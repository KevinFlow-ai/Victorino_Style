// DTOs espejo de los records del backend del paquete configuración:
// HorarioPeluqueriaResponse, DescansoResponse, FestivoResponse, CierreAnualResponse.
import '../../domain/entidades/horario_peluqueria.dart';


// ============================================================================
//  INTRODUCCIÓN
// ============================================================================
//
// Este archivo contiene **DTOs**.
//
// DTO significa **Data Transfer Object**.
// Es un objeto que sirve para **transportar datos entre la API y tu app**.
//
// En Clean Architecture:
//
//   API JSON → DTO → Entidad (Dominio) → UI
//
// Los DTOs:
//
//   ✔️ Reciben datos del backend (JSON)
//   ✔️ Los convierten a objetos de Dart
//   ✔️ Transforman esos datos a entidades del dominio
//   ✔️ Preparan datos para enviarlos de vuelta al backend
//
// IMPORTANTE:
//   - Los DTOs NO contienen lógica de negocio.
//   - Solo convierten datos.
//   - Son un "espejo" del backend.
//
// ============================================================================
// DIAGRAMA DEL FLUJO DE DATOS
// ============================================================================
//
//   ┌──────────────┐
//   │   BACKEND     │
//   │  (JSON crudo) │
//   └───────┬──────┘
//           │
//           ▼
//   ┌────────────────┐
//   │      DTO        │  <-- interpreta el JSON
//   └───────┬────────┘
//           │
//           ▼
//   ┌────────────────┐
//   │    ENTIDAD      │  <-- modelo limpio del dominio
//   └────────────────┘






// ============================================================================
//  DTO: HorarioDto
// ============================================================================
//
// Representa el horario de la peluquería tal como viene del backend.
// El backend devuelve horas como "HH:mm:ss", pero la UI solo usa "HH:mm".
//
class HorarioDto {
  const HorarioDto({
    required this.idPeluqueria,
    required this.nombre,
    this.aperturaLunes,    this.cierreLunes,
    this.aperturaMartes,   this.cierreMartes,
    this.aperturaMiercoles,this.cierreMiercoles,
    this.aperturaJueves,   this.cierreJueves,
    this.aperturaViernes,  this.cierreViernes,
    this.aperturaSabado,   this.cierreSabado,
    this.aperturaDomingo,  this.cierreDomingo,
  });

  // Campos EXACTAMENTE como vienen del backend
  final int idPeluqueria;
  final String nombre;

  // Horas opcionales (pueden ser null)
  final String? aperturaLunes;     final String? cierreLunes;
  final String? aperturaMartes;    final String? cierreMartes;
  final String? aperturaMiercoles; final String? cierreMiercoles;
  final String? aperturaJueves;    final String? cierreJueves;
  final String? aperturaViernes;   final String? cierreViernes;
  final String? aperturaSabado;    final String? cierreSabado;
  final String? aperturaDomingo;   final String? cierreDomingo;

  // --------------------------------------------------------------------------
  // FACTORY: convierte JSON → DTO
  // --------------------------------------------------------------------------
  //
  // El backend devuelve "HH:mm:ss", pero la UI solo quiere "HH:mm".
  //
  factory HorarioDto.fromJson(Map<String, dynamic> j) {
    String? hora(String key) {
      final v = j[key] as String?;
      if (v == null) return null;
      return v.length >= 5 ? v.substring(0, 5) : v; // recorta segundos
    }

    return HorarioDto(
      idPeluqueria: (j['idPeluqueria'] as num).toInt(),
      nombre: j['nombre'] as String,
      aperturaLunes: hora('aperturaLunes'),     cierreLunes: hora('cierreLunes'),
      aperturaMartes: hora('aperturaMartes'),   cierreMartes: hora('cierreMartes'),
      aperturaMiercoles: hora('aperturaMiercoles'), cierreMiercoles: hora('cierreMiercoles'),
      aperturaJueves: hora('aperturaJueves'),   cierreJueves: hora('cierreJueves'),
      aperturaViernes: hora('aperturaViernes'), cierreViernes: hora('cierreViernes'),
      aperturaSabado: hora('aperturaSabado'),   cierreSabado: hora('cierreSabado'),
      aperturaDomingo: hora('aperturaDomingo'), cierreDomingo: hora('cierreDomingo'),
    );
  }

  // --------------------------------------------------------------------------
  // DTO → ENTIDAD
  // --------------------------------------------------------------------------
  //
  // Convierte el DTO en una entidad del dominio.
  // Las entidades son modelos LIMPIOS que usa la app.
  //
  HorarioPeluqueria aEntidad() => HorarioPeluqueria(
    idPeluqueria: idPeluqueria,
    nombre: nombre,
    aperturaLunes: aperturaLunes,     cierreLunes: cierreLunes,
    aperturaMartes: aperturaMartes,   cierreMartes: cierreMartes,
    aperturaMiercoles: aperturaMiercoles, cierreMiercoles: cierreMiercoles,
    aperturaJueves: aperturaJueves,   cierreJueves: cierreJueves,
    aperturaViernes: aperturaViernes, cierreViernes: cierreViernes,
    aperturaSabado: aperturaSabado,   cierreSabado: cierreSabado,
    aperturaDomingo: aperturaDomingo, cierreDomingo: cierreDomingo,
  );

  // --------------------------------------------------------------------------
  // ENTIDAD → JSON (para enviar al backend)
  // --------------------------------------------------------------------------
  //
  // El backend espera "HH:mm:ss", así que añadimos ":00".
  //
  static Map<String, dynamic> aBody(HorarioPeluqueria h) {
    String? f(String? hora) => hora == null || hora.isEmpty ? null : '$hora:00';
    return {
      'aperturaLunes': f(h.aperturaLunes),       'cierreLunes': f(h.cierreLunes),
      'aperturaMartes': f(h.aperturaMartes),     'cierreMartes': f(h.cierreMartes),
      'aperturaMiercoles': f(h.aperturaMiercoles), 'cierreMiercoles': f(h.cierreMiercoles),
      'aperturaJueves': f(h.aperturaJueves),     'cierreJueves': f(h.cierreJueves),
      'aperturaViernes': f(h.aperturaViernes),   'cierreViernes': f(h.cierreViernes),
      'aperturaSabado': f(h.aperturaSabado),     'cierreSabado': f(h.cierreSabado),
      'aperturaDomingo': f(h.aperturaDomingo),   'cierreDomingo': f(h.cierreDomingo),
    };
  }
}

// ============================================================================
//  DTO: DescansoDto
// ============================================================================
//
// Representa un descanso de un empleado.
// Convierte JSON → DTO → Entidad.
//
class DescansoDto {
  const DescansoDto({
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.horaInicio,
    required this.duracionMinutos,
  });

  final int idEmpleado;
  final String nombreEmpleado;
  final String horaInicio;
  final int duracionMinutos;

  factory DescansoDto.fromJson(Map<String, dynamic> j) {
    final ini = j['horaInicio'] as String;
    return DescansoDto(
      idEmpleado: (j['idEmpleado'] as num).toInt(),
      nombreEmpleado: j['nombreEmpleado'] as String,
      horaInicio: ini.length >= 5 ? ini.substring(0, 5) : ini,
      duracionMinutos: (j['duracionMinutos'] as num).toInt(),
    );
  }

  DescansoEmpleado aEntidad() => DescansoEmpleado(
    idEmpleado: idEmpleado,
    nombreEmpleado: nombreEmpleado,
    horaInicio: horaInicio,
    duracionMinutos: duracionMinutos,
  );
}

// ============================================================================
//  DTO: FestivoDto
// ============================================================================
//
// Representa un festivo.
// Convierte JSON → DTO → Entidad.
// También convierte strings del backend a enums del dominio.
//
class FestivoDto {
  const FestivoDto({
    required this.id,
    required this.fecha,
    required this.descripcion,
    required this.tipo,
  });

  final int id;
  final String fecha;
  final String descripcion;
  final String tipo;

  factory FestivoDto.fromJson(Map<String, dynamic> j) => FestivoDto(
    id: (j['idFestivo'] as num).toInt(),
    fecha: j['fecha'] as String,
    descripcion: j['descripcion'] as String,
    tipo: j['tipo'] as String,
  );

  Festivo aEntidad() => Festivo(
    id: id,
    fecha: fecha,
    descripcion: descripcion,
    tipo: _tipoDesdeString(tipo),
  );

  // Convierte string → enum
  static TipoFestivo _tipoDesdeString(String t) {
    switch (t) {
      case 'NACIONAL': return TipoFestivo.nacional;
      case 'AUTONOMICO': return TipoFestivo.autonomico;
      case 'LOCAL': return TipoFestivo.local;
      case 'VACACIONES': return TipoFestivo.vacaciones;
      case 'MANTENIMIENTO': return TipoFestivo.mantenimiento;
      default: return TipoFestivo.nacional;
    }
  }

  // Convierte enum → string
  static String tipoAString(TipoFestivo t) => t.name.toUpperCase();
}

// ============================================================================
//  DTO: CierreAnualDto
// ============================================================================
//
// Representa el cierre anual de la peluquería.
// Convierte JSON → DTO → Entidad.
//
class CierreAnualDto {
  const CierreAnualDto({this.fechaInicio, this.fechaFin});
  final String? fechaInicio;
  final String? fechaFin;

  factory CierreAnualDto.fromJson(Map<String, dynamic> j) => CierreAnualDto(
    fechaInicio: j['fechaInicio'] as String?,
    fechaFin: j['fechaFin'] as String?,
  );

  CierreAnual aEntidad() => CierreAnual(fechaInicio: fechaInicio, fechaFin: fechaFin);
}
