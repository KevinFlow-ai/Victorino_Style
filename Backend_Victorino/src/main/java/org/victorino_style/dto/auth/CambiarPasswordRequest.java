package org.victorino_style.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// Este es un DTO para manejar el endpoint POST /auth/cambiar-password.
// En el cual el usuario envía su contraseña actual y la nueva que quiere establecer.
public record CambiarPasswordRequest(

        @NotBlank(message = "La contraseña actual es obligatoria")
        String passwordActual,

        @NotBlank(message = "La nueva contraseña es obligatoria")
        @Size(min = 6, message = "La nueva contraseña debe tener al menos 6 caracteres")
        String passwordNueva
) {}

