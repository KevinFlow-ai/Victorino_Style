package org.victorino_style.dto.empleado;

import java.time.LocalTime;

/**
 * DTO para que el empleado actualice sus propios ajustes de "No Molestar".
 */
public record ConfiguracionEmpleadoRequest(
    LocalTime silencioInicio,
    LocalTime silencioFin,
    boolean noMolestar
) {
}
