package org.victorino_style.dto.cliente;

import java.time.LocalTime;

// DTO de salida que representa un hueco horario disponible para reservar.
// Lo devuelve GET /cliente/citas/disponibilidad como elemento de una lista.
// El Paso 3 del wizard lo usa para construir los chips de hora seleccionables.
public record HuecoDisponibleResponse(

        // Hora de inicio del hueco (HH:mm:ss). Cada hueco dura exactamente el
        // duracion_servicio del servicio elegido en el Paso 1.
        LocalTime horaInicio,

        // Hora de fin del hueco (horaInicio + duracion del servicio).
        LocalTime horaFin,

        // ID del empleado que estará libre en este hueco. Siempre presente.
        // - En modo "empleado concreto" (cliente eligió uno en el Paso 2): coincide con ese empleado.
        // - En modo "Cualquiera disponible": el algoritmo devuelve el empleado con menor carga ese día.
        Long idEmpleado,

        // Nombre del empleado asignado al hueco (para mostrar debajo del chip de hora
        // cuando el cliente eligió "Cualquiera").
        String nombreEmpleado,

        // Foto del empleado (ruta relativa). Útil para enriquecer la UI del chip.
        String fotoEmpleado
) {
}

// ============================================================================
// HuecoDisponibleResponse
// ----------------------------------------------------------------------------
// Resultado del cálculo de disponibilidad para una fecha + servicio dados.
//
// CÓMO LO USA EL FRONTEND:
//   - En el Paso 3 del wizard, lista de chips horizontales con la hora.
//   - En modo "Cualquiera disponible" (Paso 2 → null), debajo del chip aparece
//     el nombre del empleado. Si el cliente acepta, el frontend envía ese
//     idEmpleado concreto al POST /cliente/citas (modo híbrido con fallback).
//   - Si entre el GET disponibilidad y el POST otro cliente roba la franja,
//     el POST devolverá 409 y el frontend volverá a recargar disponibilidad.
//
// FILTROS APLICADOS POR DisponibilidadService:
//   - Día abierto (no festivo activo, no cierre anual).
//   - Dentro del horario de apertura/cierre del día de la semana.
//   - Fuera del descanso fijo del empleado.
//   - Sin solape con citas activas (CONFIRMADA/EN_PROCESO).
//   - hora_inicio + duracion ≤ cierre del día.
//   - El empleado no está dado de baja lógica (fecha_eliminacion_usuario IS NULL).
// ============================================================================
