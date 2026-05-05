package org.victorino_style.dto.admin;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.time.LocalTime;

// DTO de entrada para configurar el descanso fijo diario de un empleado concreto.
// Lo recibe HorarioAdminController en PUT /admin/empleados/{id}/descanso.
public record DescansoRequest(

        // Hora a la que comienza el descanso (HH:mm). Obligatoria.
        @NotNull(message = "La hora de inicio del descanso es obligatoria")
        LocalTime horaInicio,

        // Duración del descanso en minutos. Mínimo 10, máximo 120 (igual que la columna BD).
        @NotNull(message = "La duración del descanso es obligatoria")
        @Min(value = 10, message = "La duración mínima del descanso es 10 minutos")
        @Max(value = 60, message = "La duración máxima del descanso es 60 minutos")
        Integer duracionMinutos
) {
}

// ============================================================================
// DescansoRequest
// ----------------------------------------------------------------------------
// DTO con los datos del descanso fijo diario de un empleado.
//
// ¿PARA QUÉ SIRVE?
// - Endpoint PUT /admin/empleados/{id}/descanso.
// - HorarioAdminService busca o crea la fila en `horario_empleado`
//   asociada al empleado (relación 1:1) y actualiza descanso_inicio_horario
//   y descanso_duracion_horario.
//
// REGLA DE NEGOCIO:
// - Cada empleado tiene UN único descanso al día (no varios). Si en el
//   futuro se quisieran añadir más, habría que cambiar la cardinalidad de
//   `horario_empleado`.
// - El sistema bloquea el tramo [horaInicio, horaInicio + duracion] al
//   calcular huecos disponibles para reservar.
// - Los descansos pueden solaparse entre empleados (Marco descansa a las 10
//   y Elena a las 11), eso lo permite el modelo y es deseable para que
//   nunca esté toda la plantilla descansando a la vez.
// ============================================================================
