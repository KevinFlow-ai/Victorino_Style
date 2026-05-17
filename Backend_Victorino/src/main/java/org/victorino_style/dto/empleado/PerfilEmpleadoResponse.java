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
        boolean noMolestar
) {
}
