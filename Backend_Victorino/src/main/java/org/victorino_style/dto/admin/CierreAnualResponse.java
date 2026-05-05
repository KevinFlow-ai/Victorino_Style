package org.victorino_style.dto.admin;

import java.time.LocalDate;

// DTO de salida (response) que representa el cierre anual configurado en el sistema.
// Este record se envía al frontend cuando el administrador consulta el período
// en el que la peluquería estará cerrada por vacaciones.
//
// Un "record" en Java es una clase inmutable ideal para transportar datos,
// especialmente en APIs REST, porque:
// - Es conciso y fácil de leer
// - Genera automáticamente constructor, getters, equals, hashCode y toString
// - Garantiza que los valores no cambian una vez creado el objeto
//
// Este DTO contiene:
// - fechaInicio: primer día del cierre anual (puede ser null si no hay cierre configurado)
// - fechaFin: último día del cierre anual (también puede ser null)
//
// El hecho de que ambos campos puedan ser null permite representar
// que actualmente NO existe un cierre anual activo.

public record CierreAnualResponse(

        // Primer día del cierre anual (puede ser null si no hay cierre activo).
        LocalDate fechaInicio,

        // Último día del cierre anual (puede ser null si no hay cierre activo).
        LocalDate fechaFin

) {
    // No se necesita cuerpo adicional a menos que quieras métodos extra.
}


// ============================================================================
// CierreAnualResponse
// ----------------------------------------------------------------------------
// Respuesta con el periodo de cierre anual vigente.
//
// ¿PARA QUÉ SIRVE?
// - Lo devuelve GET /admin/cierre-anual y PUT /admin/cierre-anual.
// - El frontend lo usa en la sección "Annual Recess" para mostrar las
//   fechas y permitir editarlas.
//
// VALORES NULL:
// - Si ambas fechas son null, el frontend muestra "Sin cierre programado".
// ============================================================================
