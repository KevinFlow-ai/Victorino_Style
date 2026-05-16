package org.victorino_style.dto.cliente;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalTime;

// DTO de entrada para reservar una cita desde la app del cliente (wizard de 4 pasos).
// Lo recibe POST /cliente/citas. El idCliente NO viaja aquí: se extrae del JWT.
// Sustituye al antiguo ReservaClienteRequest, que se eliminará al refactorizar ClienteController.
public record ReservarCitaRequest(

        // Servicio a realizar. Obligatorio.
        @NotNull(message = "El servicio es obligatorio")
        Long idServicio,

        // Empleado concreto con el que se quiere la cita. NULLABLE: si es null se interpreta
        // como modo "Cualquiera disponible" y el backend asigna el empleado de menor carga
        // ese día entre los que tienen el hueco libre. Cuando no es null, el backend reserva
        // con ese empleado específico (modo normal).
        Long idEmpleado,

        // Fecha de la cita (YYYY-MM-DD). Obligatoria. Debe estar entre hoy y hoy+30 días
        // (validado por CitaFueraDeAntelacionException).
        @NotNull(message = "La fecha es obligatoria")
        LocalDate fecha,

        // Hora de inicio (HH:mm:ss). Obligatoria. La hora_fin se calcula sumando la duración
        // del servicio. Si excede el cierre del día → CitaSolapadaException.
        @NotNull(message = "La hora de inicio es obligatoria")
        LocalTime horaInicio,

        // Nota opcional para el empleado. Máx. 280 caracteres (regla del CLAUDE.md aunque
        // la columna permite 350, dejamos margen). Puede ser null o cadena vacía.
        @Size(max = 280, message = "La nota no puede superar los 280 caracteres")
        String nota,

        // Flag que indica si el cliente eligió "Cualquiera disponible" en el Paso 2 del wizard.
        // Si es true y la franja del idEmpleado concreto ya esta ocupada al hacer commit, el
        // backend reintenta UNA VEZ asignando otro empleado libre (fallback). Si es false (eligio
        // a un empleado especifico), no hay reintento: se devuelve 409 directamente.
        // Puede ser null → se interpreta como false (modo empleado concreto).
        Boolean cualquieraDisponible
) {
}

// ============================================================================
// ReservarCitaRequest
// ----------------------------------------------------------------------------
// Cuerpo del Paso 4 del wizard ("Confirmar reserva"). El frontend lo envía
// con los valores acumulados durante los pasos 1-3.
//
// CAMPO idEmpleado NULLABLE:
//   - El cliente puede elegir "Cualquiera disponible" en el Paso 2 del wizard.
//   - En ese caso el frontend, tras consultar GET /cliente/citas/disponibilidad,
//     conoce el empleado concreto que mostró bajo el chip de hora (mejor UX:
//     el cliente VE quién le va a tocar). Por defecto envía ese idEmpleado.
//   - SI antes de confirmar otro cliente roba la franja (race condition), el
//     backend al detectar 409 reintenta UNA VEZ con el siguiente empleado de
//     menor carga libre. Esto se llama "fallback de cualquiera" y solo se aplica
//     si el frontend marcó que era una elección "Cualquiera" (ver flag interno).
//   - Si idEmpleado es null directamente, el backend asigna desde el principio
//     el empleado de menor carga libre en esa franja.
//
// VALIDACIONES de SOLAPE / DESCANSO / FESTIVO / ANTELACIÓN: todas en CitaClienteService.
// ============================================================================
