package org.victorino_style.dto.admin;

import java.time.LocalDate;

// DTO de entrada para configurar el cierre anual de la peluquería.
// Ambas fechas pueden ser null para indicar que no hay cierre programado.
// Lo recibe HorarioAdminController en PUT /admin/cierre-anual.
// DTO de entrada (request) para configurar el cierre anual de la peluquería.
// Este record se utiliza cuando el administrador quiere definir un período completo
// en el que el negocio permanecerá cerrado por vacaciones.
//
// Un "record" en Java es una clase inmutable pensada para transportar datos.
// Es ideal para requests porque:
// - Es conciso y fácil de leer
// - Genera automáticamente constructor, getters, equals, hashCode y toString
// - Garantiza que los valores no cambian una vez creado el objeto
//
// Este DTO contiene:
// - fechaInicio: primer día en que la peluquería estará cerrada
// - fechaFin: último día del cierre
//
// El servicio que reciba este DTO será responsable de validar que:
// - fechaInicio <= fechaFin
// - No se solape con otros cierres
// - Las fechas tengan sentido según la lógica del negocio

public record CierreAnualRequest(

        // Primer día (incluido) en el que la peluquería estará cerrada por vacaciones.
        LocalDate fechaInicio,

        // Último día (incluido) en el que la peluquería estará cerrada.
        LocalDate fechaFin

) {
    // No se necesita cuerpo adicional a menos que quieras métodos extra.
}


// ============================================================================
// CierreAnualRequest
// ----------------------------------------------------------------------------
// DTO para registrar el periodo de vacaciones anuales de la peluquería.
//
// ¿PARA QUÉ SIRVE?
// - Endpoint PUT /admin/cierre-anual.
// - HorarioAdminService valida que fechaInicio <= fechaFin (cuando ambas
//   están informadas) y persiste los campos en la fila singleton de
//   `peluqueria` (cierre_anual_inicio, cierre_anual_fin).
//
// REGLA DE NEGOCIO:
// - Cualquier día contenido en [fechaInicio, fechaFin] (ambos inclusive)
//   bloquea TODOS los huecos para reservar.
// - Si las dos fechas son null, no hay cierre vigente (la peluquería abre
//   con normalidad todo el año salvo festivos puntuales).
// - Por defecto, el seed inicializa el cierre en agosto. El admin lo
//   puede mover.
// ============================================================================
