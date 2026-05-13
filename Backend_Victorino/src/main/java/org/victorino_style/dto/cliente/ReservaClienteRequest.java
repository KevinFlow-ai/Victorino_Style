package org.victorino_style.dto.cliente;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalTime;

// DTO de entrada para que un cliente registrado reserve una cita desde la app.
// El idCliente se extrae del JWT, no del cuerpo de la petición.
public record ReservaClienteRequest(

        // Empleado con el que se quiere la cita.
        @NotNull(message = "El empleado es obligatorio")
        Long idEmpleado,

        // Servicio que se va a realizar.
        @NotNull(message = "El servicio es obligatorio")
        Long idServicio,

        // Fecha de la cita (YYYY-MM-DD).
        @NotNull(message = "La fecha es obligatoria")
        LocalDate fecha,

        // Hora de inicio (HH:mm).
        @NotNull(message = "La hora de inicio es obligatoria")
        LocalTime horaInicio,

        // Nota opcional para el empleado (máx. 350 caracteres).
        @Size(max = 350, message = "La nota no puede superar los 350 caracteres")
        String nota
) {
}

