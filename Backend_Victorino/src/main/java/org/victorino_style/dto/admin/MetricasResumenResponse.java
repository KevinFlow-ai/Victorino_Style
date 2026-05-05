package org.victorino_style.dto.admin;

import java.time.DayOfWeek;
import java.util.List;

// DTO de salida con el resumen de métricas del negocio para el rango pedido.
// Una única respuesta agrupa los KPIs y todas las series usadas por el dashboard.
public record MetricasResumenResponse(

        // Total de citas en el rango (todas, en cualquier estado).
        long totalCitas,

        // Citas completadas (estado COMPLETADA).
        long citasCompletadas,

        // Citas canceladas (cliente o peluquería).
        long citasCanceladas,

        // Citas marcadas como NO_PRESENTADO.
        long citasNoPresentado,

        // Tasa de asistencia global = completadas / (total - canceladas) * 100.
        // Se devuelve como porcentaje con dos decimales (ej. 86.50).
        double tasaAsistencia,

        // Servicio más reservado en el rango (puede ser null si no hay citas).
        ServicioPopular servicioMasSolicitado,

        // Empleado con más citas atendidas en el rango (puede ser null si no hay citas).
        EmpleadoPopular empleadoMasReservado,

        // Distribución de citas por día de la semana.
        List<DistribucionDia> distribucionPorDiaSemana,

        // Distribución de citas por franja horaria (intervalos de 1 hora).
        List<DistribucionFranja> distribucionPorFranjaHoraria
) {

    // Servicio popular: id, nombre y nº de reservas en el rango.
    public record ServicioPopular(Long idServicio, String nombre, long reservas) {}

    // Empleado popular: id, nombre y nº de citas atendidas (no canceladas) en el rango.
    public record EmpleadoPopular(Long idEmpleado, String nombre, long citasAtendidas) {}

    // Distribución por día de la semana.
    public record DistribucionDia(DayOfWeek dia, long citas) {}

    // Distribución por franja horaria.
    // `horaInicio` se expresa como String "HH:mm" para evitar dependencia de LocalTime en JSON.
    public record DistribucionFranja(String horaInicio, long citas) {}
}

// ============================================================================
// MetricasResumenResponse
// ----------------------------------------------------------------------------
// Respuesta única que alimenta TODOo el dashboard de métricas del admin.
//
// ¿PARA QUÉ SIRVE?
// - Endpoint GET /admin/metricas/resumen?fechaInicio&fechaFin.
// - El frontend pinta:
//      * KPIs numéricos en cards (total citas, tasa asistencia, etc.).
//      * Gráfica de barras con citasCompletadas/Canceladas/NoPresentado.
//      * Ranking del servicio y empleado más populares.
//      * Distribución por día de semana (gráfica de barras).
//      * Distribución por franja horaria (gráfica de líneas).
//
// PRINCIPIO ARQUITECTÓNICO:
// - Todas las métricas se calculan con @Query JPQL en `CitaRepository`.
// - JAMÁS se cargan entidades en memoria para sumar/agrupar.
// - Esto garantiza que el endpoint sigue siendo rápido cuando la tabla
//   `cita` crezca a miles de filas.
//
// SUB-RECORDS:
// - Se definen anidados para mantener la cohesión: un único archivo
//   contiene todos los formatos relacionados con métricas.
// ============================================================================
