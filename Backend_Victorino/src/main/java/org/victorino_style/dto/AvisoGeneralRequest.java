package org.victorino_style.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// DTO para que el administrador envie un aviso general a un usuario concreto.
public record AvisoGeneralRequest(

        // Si se especifica, el aviso va solo a ese usuario concreto.
        Long idDestinatario,

        @NotBlank(message = "El titulo es obligatorio")
        @Size(max = 250)
        String titulo,

        @NotBlank(message = "El cuerpo es obligatorio")
        @Size(max = 500)
        String cuerpo
) {}

