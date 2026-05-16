package org.victorino_style.entity.enums;

// Enumerado con los siete tipos de notificación que el sistema puede emitir.
// Se mapea con la columna `tipo_notificacion` (ENUM) de la tabla `notificacion`.
public enum TipoNotificacion {

    // Confirmación inmediata al reservar una cita correctamente.
    CONFIRMACION_RESERVA,

    // Recordatorio enviado 24 horas antes de la cita.
    RECORDATORIO_24H,

    // El cliente ha cancelado su cita (se notifica al empleado).
    CANCELACION_CLIENTE,

    // La peluquería ha cancelado la cita (se notifica al cliente; típico de la cancelación masiva).
    CANCELACION_PELUQUERIA,

    // Notificación al empleado cuando le crean una cita nueva (incluye walk-in del admin).
    NUEVA_CITA_EMPLEADO,

    // Notificación al empleado cuando el cliente modifica una cita ya confirmada (cambia hora, servicio, etc.).
    MODIFICACION_CITA,

    // Aviso al usuario de que su contraseña ha sido modificada.
    CONTRASENA_ACTUALIZADA,

    // Aviso genérico de la peluquería que no encaja en los anteriores.
    AVISO_GENERAL
}

// ============================================================================
// TipoNotificacion
// ----------------------------------------------------------------------------
// Este enum cataloga las notificaciones que el sistema envía a los usuarios
// (clientes, empleados y administradores).
//
// ¿PARA QUÉ SIRVE?
// - Se almacena en `notificacion.tipo_notificacion`.
// - Lo usa NotificacionService para decidir el título, el cuerpo y la regla
//   de envío push (ver la lógica de "no molestar" del empleado y la
//   preferencia `push_activa_cliente` del cliente).
// - El frontend lo usa para pintar iconos y colores en la bandeja in-app.
//
// REGLA DE ENVÍO:
// - In-app: SIEMPRE se inserta fila en `notificacion`, sea cual sea el tipo.
// - Push FCM: solo si el destinatario lo permite (cliente con push activa,
//   empleado fuera de su rango de silencio y con el modo "no molestar"
//   desactivado).
// ============================================================================
