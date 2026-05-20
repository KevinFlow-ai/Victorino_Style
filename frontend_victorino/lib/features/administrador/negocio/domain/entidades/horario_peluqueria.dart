// ============================================================================
// INTRODUCCIÓN
// ============================================================================
//
// Este archivo contiene las **entidades del dominio** del submódulo "negocio".
//
// En Clean Architecture, una ENTIDAD:
//
//   - Representa un concepto del negocio real.
//   - Es un modelo puro, sin dependencias de Flutter, HTTP, JSON, ni nada externo.
//   - No tiene lógica de infraestructura.
//   - No sabe nada de la UI ni de cómo se guardan los datos.
//
// Las entidades son el corazón del dominio.
//
// DIAGRAMA:
//
//   API JSON → DTO → ENTIDAD → UI
//
// Las entidades deben ser simples, claras y estables.
// Si mañana cambias de backend, las entidades no deberían cambiar.
//
// ============================================================================
// NOTA SOBRE HORAS
// ============================================================================
//
// Las horas se guardan como strings "HH:mm".
// Esto se hace para evitar usar TimeOfDay (que pertenece a Flutter).
// El dominio debe ser independiente de Flutter.
//
// ============================================================================
// ENTIDAD: HorarioPeluqueria
// ============================================================================
//
// Representa el horario semanal de la peluquería.
// Cada día tiene una hora de apertura y una de cierre.
// Si un día está cerrado, ambas pueden ser null.
//
class HorarioPeluqueria {
  const HorarioPeluqueria({
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

  final int idPeluqueria;
  final String nombre;

  // Cada par apertura/cierre puede ser null si ese día no se trabaja.
  final String? aperturaLunes;     final String? cierreLunes;
  final String? aperturaMartes;    final String? cierreMartes;
  final String? aperturaMiercoles; final String? cierreMiercoles;
  final String? aperturaJueves;    final String? cierreJueves;
  final String? aperturaViernes;   final String? cierreViernes;
  final String? aperturaSabado;    final String? cierreSabado;
  final String? aperturaDomingo;   final String? cierreDomingo;
}

// ============================================================================
// ENTIDAD: DescansoEmpleado
// ============================================================================
//
// Representa un descanso de un empleado.
// Contiene:
//   - id del empleado
//   - nombre
//   - hora de inicio del descanso
//   - duración en minutos
//
class DescansoEmpleado {
  const DescansoEmpleado({
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.horaInicio,
    required this.duracionMinutos,
  });

  final int idEmpleado;
  final String nombreEmpleado;
  final String horaInicio; // Formato "HH:mm"
  final int duracionMinutos;
}

// ============================================================================
// ENUM: TipoFestivo
// ============================================================================
//
// Representa los tipos posibles de festivo.
// Este enum debe coincidir con el enum del backend.
//
// Los valores se usan para clasificar festivos:
//   - nacional
//   - autonomico
//   - local
//   - vacaciones
//   - mantenimiento
//
enum TipoFestivo { nacional, autonomico, local, vacaciones, mantenimiento }

// ============================================================================
// ENTIDAD: Festivo
// ============================================================================
//
// Representa un festivo concreto.
// Contiene:
//   - id
//   - fecha en formato YYYY-MM-DD
//   - descripción
//   - tipo (enum)
//
class Festivo {
  const Festivo({
    required this.id,
    required this.fecha, // YYYY-MM-DD
    required this.descripcion,
    required this.tipo,
  });

  final int id;
  final String fecha;
  final String descripcion;
  final TipoFestivo tipo;
}

// ============================================================================
// ENTIDAD: CierreAnual
// ============================================================================
//
// Representa un periodo de cierre anual de la peluquería.
// Puede no existir, por eso las fechas pueden ser null.
//
// Ejemplo:
//   fechaInicio = "2024-08-01"
//   fechaFin = "2024-08-15"
//
// Si ambos son null, significa que no hay cierre anual.
//
class CierreAnual {
  const CierreAnual({this.fechaInicio, this.fechaFin});

  final String? fechaInicio; // YYYY-MM-DD o null
  final String? fechaFin;
}

// ============================================================================
// ENTIDAD: ConfiguracionCorreo
// ============================================================================
//
// Configuración SMTP dinámica del servidor de correo.
// Permite usar cualquier proveedor (Gmail, Outlook, educaMadrid…).
//
// Si configurado=false significa que el backend usa su application.properties.
//
class ConfiguracionCorreo {
  const ConfiguracionCorreo({
    this.host,
    this.port,
    this.user,
    this.ssl = false,
    required this.configurado,
  });

  final String? host;   // ej. smtp.gmail.com
  final int? port;      // ej. 587
  final String? user;   // ej. correo@gmail.com
  final bool ssl;       // false=STARTTLS(587), true=SSL directo(465)
  final bool configurado; // true si hay config en BD
}
