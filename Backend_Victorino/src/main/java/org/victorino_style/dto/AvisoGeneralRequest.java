package org.victorino_style.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// Este es un DTO para manejar que el administrador envíe un aviso general a un usuario concreto
// o a todos los usuarios de un rol correctamente.
public record AvisoGeneralRequest(

        // Si se especifica, el aviso va solo a ese usuario concreto.
        Long idDestinatario,

        @NotBlank(message = "El título es obligatorio")
        @Size(max = 250)
        String titulo,

        @NotBlank(message = "El cuerpo es obligatorio")
        @Size(max = 500)
        String cuerpo
) {}

