package org.victorino_style.dto.admin;

// DTO de salida tras ejecutar la cancelación masiva de las citas futuras de un empleado.
public record CancelacionMasivaResponse(

        // Identificador del empleado afectado.
        Long idEmpleado,

        // Nombre completo del empleado (para que la UI muestre el resumen sin segunda llamada).
        String nombreEmpleado,

        // Número total de citas que se han marcado como CANCELADA_PELUQUERIA.
        int citasCanceladas,

        // Número de clientes únicos a los que se ha enviado notificación.
        int clientesNotificados,

        // Número de citas que NO se pudieron cancelar (por ejemplo, ya estaban en estado terminal).
        // Útil para mostrar al admin un mensaje claro: "8 canceladas, 1 ya estaba completada".
        int citasOmitidas
) {
}

// ============================================================================
// CancelacionMasivaResponse
// ----------------------------------------------------------------------------
// Resumen del resultado de POST /admin/empleados/{id}/cancelar-citas.
//
// ¿PARA QUÉ SIRVE?
// - Tras ejecutar la operación, el frontend muestra un modal con el resumen:
//      "Se han cancelado 8 citas y notificado a 6 clientes."
//
// CONCURRENCIA:
// - El servicio cancela cada cita en su propia transacción
//   (@Transactional(propagation=REQUIRES_NEW)) para que un fallo en una
//   no afecte al resto. Si una cita estaba en estado terminal o no pudo
//   bloquearse, se cuenta en `citasOmitidas`.
//
// NOTIFICACIONES:
// - Por cada cita cancelada se inserta una fila en `notificacion`
//   (in-app) y, según preferencias del cliente, se intenta enviar push
//   FCM (TODOo: pendiente de configuración).
// ============================================================================
