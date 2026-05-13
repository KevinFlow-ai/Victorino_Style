package org.victorino_style.dto;

import org.victorino_style.entity.Notificacion;

import java.time.Instant;

// DTO de respuesta para la bandeja de notificaciones in-app.
// Evita exponer la entidad JPA directamente y sus relaciones LAZY.
public record NotificacionDto(

        Long id,

        // Titulo de la notificacion (max 250 caracteres).
        String titulo,

        // Cuerpo / mensaje de la notificacion (max 500 caracteres).
        String cuerpo,

        // Tipo: CONFIRMACION_RESERVA, CANCELACION_PELUQUERIA, RECORDATORIO_24H, etc.
        String tipo,

        // ID de la cita relacionada (puede ser null si no hay cita asociada).
        Long idCita,

        // true si Firebase confirmo la entrega del push.
        boolean enviadaPush,

        // Fecha en que se creo la notificacion.
        Instant fechaCreacion,

        // null = no leida. Con valor = ya fue leida.
        Instant fechaLectura

) {

    // -----------------------------------------------------------------------
    // Factory method: convierte la entidad JPA en este DTO.
    // Se usa en el Service para no exponer la entidad hacia afuera.
    // -----------------------------------------------------------------------
    public static NotificacionDto from(Notificacion n) {
        return new NotificacionDto(
                n.getId(),
                n.getTituloNotificacion(),
                n.getCuerpoNotificacion(),
                n.getTipoNotificacion(),
                n.getIdCitaRelacionadaNotificacion() != null
                        ? n.getIdCitaRelacionadaNotificacion().getId()
                        : null,
                n.getEnviadaPushNotificacion(),
                n.getFechaCreacionNotificacion(),
                n.getFechaLecturaNotificacion()
        );
    }
}

