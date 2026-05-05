package org.victorino_style.dto.admin;

import java.time.LocalTime;

// DTO de salida con el descanso fijo diario actual de un empleado.
public record DescansoResponse(

        // Identificador del empleado al que pertenece el descanso.
        Long idEmpleado,

        // Nombre completo del empleado (para que el frontend pinte la etiqueta sin segunda llamada).
        String nombreEmpleado,

        // Hora a la que comienza el descanso.
        LocalTime horaInicio,

        // Duración del descanso en minutos.
        Integer duracionMinutos
) {
}

// ============================================================================
// DescansoResponse
// ----------------------------------------------------------------------------
// Respuesta con el descanso configurado para un empleado.
//
// ¿PARA QUÉ SIRVE?
// - Lo devuelve PUT /admin/empleados/{id}/descanso tras guardar.
// - El frontend lo usa en la sección "Fixed Breaks" del panel de Negocio.
//
// CAMPO `nombreEmpleado`:
// - Se incluye por comodidad para evitar que el frontend tenga que cruzar
//   con la lista de empleados para mostrar el nombre. HorarioMapper lo
//   compone a partir de `Empleado.nombreEmpleado + " " + apellidosEmpleado`.
// ============================================================================
