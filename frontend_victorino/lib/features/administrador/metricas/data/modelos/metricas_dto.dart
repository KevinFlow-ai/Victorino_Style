// ============================================================================
// EXPLICACIÓN
// ============================================================================
//
// Este archivo define algo llamado "DTO". No te asustes: un DTO es simplemente
// una cajita que recibe datos crudos desde internet (normalmente en formato JSON)
// y los convierte en objetos que tu app entiende mejor.
//
// Piensa así:
//
// - El servidor te manda un mapa (Map<String, dynamic>) lleno de datos.
// - Este DTO toma ese mapa y lo transforma en un objeto bonito y ordenado
//   llamado "MetricasResumen", que es lo que tu app realmente usa.
//
// Es como recibir ingredientes sueltos y convertirlos en un plato ya preparado.
//
// ============================================================================
// IMPORTACIÓN DE LA ENTIDAD
// ============================================================================
//
// Aquí importamos la clase "MetricasResumen" y otras clases relacionadas.
// Estas son las estructuras finales que queremos construir.
//
import '../../domain/entidades/metricas_resumen.dart';


// ============================================================================
// CLASE DTO
// ============================================================================
//
// Esta clase recibe un JSON (un mapa con claves y valores).
// Ese JSON viene del servidor y puede tener números, textos, listas, etc.
//
// La clase tiene un métodoo llamado "aEntidad()" que convierte ese JSON
// en un objeto de tipo MetricasResumen.
//
// MetricasResumenDto = "caja que transforma datos crudos en datos útiles".
//
class MetricasResumenDto {
  const MetricasResumenDto(this.json);

  // Aquí guardamos el JSON tal cual llega del servidor.
  final Map<String, dynamic> json;

  // ==========================================================================
  // MÉTODOO aEntidad()
  // ==========================================================================
  //
  // Este métodoo toma el JSON y lo convierte en un objeto MetricasResumen.
  //
  // Paso a paso:
  // 1. Extraemos partes del JSON (servicio, empleado, distribuciones…).
  // 2. Convertimos cada parte a su tipo correspondiente.
  // 3. Devolvemos un MetricasResumen completamente armado.
  //
  MetricasResumen aEntidad() {
    // Extraemos del JSON los datos del servicio más solicitado.
    // Puede venir nulo, así que lo tratamos con cuidado.
    final servicio = json['servicioMasSolicitado'] as Map<String, dynamic>?;

    // Lo mismo para el empleado más reservado.
    final empleado = json['empleadoMasReservado'] as Map<String, dynamic>?;

    // Extraemos listas. Si no vienen, usamos listas vacías.
    final distDia = json['distribucionPorDiaSemana'] as List<dynamic>? ?? [];
    final distFranja = json['distribucionPorFranjaHoraria'] as List<dynamic>? ?? [];

    // Aquí construimos el objeto final MetricasResumen.
    return MetricasResumen(
      // Convertimos números del JSON a enteros.
      totalCitas: (json['totalCitas'] as num).toInt(),
      citasCompletadas: (json['citasCompletadas'] as num).toInt(),
      citasCanceladas: (json['citasCanceladas'] as num).toInt(),
      citasNoPresentado: (json['citasNoPresentado'] as num).toInt(),

      // Convertimos la tasa a double.
      tasaAsistencia: (json['tasaAsistencia'] as num).toDouble(),

      // Si servicio es nulo → dejamos null.
      // Si no, creamos un objeto ServicioPopular.
      servicioMasSolicitado: servicio == null
          ? null
          : ServicioPopular(
        idServicio: (servicio['idServicio'] as num).toInt(),
        nombre: servicio['nombre'] as String,
        reservas: (servicio['reservas'] as num).toInt(),
      ),

      // Igual para empleado.
      empleadoMasReservado: empleado == null
          ? null
          : EmpleadoPopular(
        idEmpleado: (empleado['idEmpleado'] as num).toInt(),
        nombre: empleado['nombre'] as String,
        citasAtendidas: (empleado['citasAtendidas'] as num).toInt(),
      ),

      // Convertimos la lista de distribución por día.
      // Cada elemento del JSON se convierte en un objeto DistribucionDia.
      distribucionPorDiaSemana: distDia.map((d) {
        final m = d as Map<String, dynamic>;
        return DistribucionDia(
          dia: m['dia'] as String,
          citas: (m['citas'] as num).toInt(),
        );
      }).toList(),

      // Convertimos la lista de distribución por franja horaria.
      distribucionPorFranjaHoraria: distFranja.map((d) {
        final m = d as Map<String, dynamic>;
        return DistribucionFranja(
          horaInicio: m['horaInicio'] as String,
          citas: (m['citas'] as num).toInt(),
        );
      }).toList(),
    );
  }
}
