package org.victorino_style.dto.admin;

/**
 * DTO para el resumen del perfil del empleado.
 * Los nombres de los campos coinciden exactamente con lo que espera el Frontend.
 */
public record EmpleadoPerfilResumenDTO(
    Long id,
    String nombreCompleto,
    String fotoUrl,
    long citasCompletadas,
    String tiempoExperiencia
) {}
