package org.victorino_style.dto.admin;

/**
 * Respuesta con la configuración SMTP activa.
 * La contraseña nunca se devuelve por seguridad.
 *
 * @param host        Servidor SMTP (ej. smtp.gmail.com)
 * @param port        Puerto (ej. 587)
 * @param user        Correo remitente (ej. peluqueria@gmail.com)
 * @param ssl         false=STARTTLS, true=SSL directo
 * @param configurado true si hay configuración guardada en BD; false si se usa application.properties
 */
public record ConfiguracionCorreoResponse(
        String host,
        Integer port,
        String user,
        boolean ssl,
        boolean configurado
) {}

