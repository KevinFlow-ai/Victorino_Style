package org.victorino_style.dto.admin;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Payload para actualizar la configuración SMTP dinámica desde el panel admin.
 *
 * Ejemplos de valores por proveedor:
 *
 *  Gmail          → host=smtp.gmail.com       port=587  ssl=false
 *  Outlook/Hotmail→ host=smtp.office365.com   port=587  ssl=false
 *  Yahoo          → host=smtp.mail.yahoo.com  port=587  ssl=false
 *  educaMadrid    → host=smtp.educa.madrid.org port=587  ssl=false
 *  SSL directo    → cualquier host             port=465  ssl=true
 */
public record ConfiguracionCorreoRequest(

        @NotBlank(message = "El host SMTP es obligatorio")
        String host,

        @NotNull(message = "El puerto SMTP es obligatorio")
        @Min(value = 1,     message = "Puerto mínimo: 1")
        @Max(value = 65535, message = "Puerto máximo: 65535")
        Integer port,

        @NotBlank(message = "El usuario (correo remitente) es obligatorio")
        String user,

        @NotBlank(message = "La contraseña es obligatoria")
        String password,

        /** false = STARTTLS (puerto 587); true = SSL directo (puerto 465) */
        boolean ssl
) {}

