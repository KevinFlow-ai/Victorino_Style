package org.victorino_style.dto.empleado;

import org.victorino_style.entity.enums.RolUsuario;
import java.time.LocalTime;

/**
 * DTO de salida con los datos del perfil del empleado autenticado.
 * Utilizado por el empleado para ver sus propios datos y configuración de "No Molestar".
 */
public record PerfilEmpleadoResponse(
        Long idEmpleado,
        String nombre,
        String apellidos,
        String correo,
        String fotoUrl,
        RolUsuario rol,
        LocalTime silencioInicio,
        LocalTime silencioFin,
        boolean noMolestar,

        // Hora de inicio del descanso fijo diario en formato "HH:mm".
        // Null si el empleado todavía no tiene descanso configurado.
        // Lo consume la agenda del empleado para pintar la franja gris.
        String horaDescanso,

        // Duración del descanso en minutos. Null si no está configurado.
        Integer duracionDescansoMinutos
) {
}
