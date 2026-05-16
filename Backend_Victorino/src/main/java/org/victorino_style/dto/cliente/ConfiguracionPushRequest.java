package org.victorino_style.dto.cliente;

import jakarta.validation.constraints.NotNull;

// DTO de entrada para activar o desactivar las notificaciones push del cliente.
// Lo recibe PUT /cliente/perfil/notificaciones. Modifica cliente.push_activa_cliente en BD.
public record ConfiguracionPushRequest(

        // Si true, el cliente acepta recibir push FCM. Si false, solo recibe in-app.
        // La bandeja in-app siempre se actualiza independientemente de este flag.
        @NotNull(message = "El valor pushActiva es obligatorio")
        Boolean pushActiva
) {
}

// ============================================================================
// ConfiguracionPushRequest
// ----------------------------------------------------------------------------
// Cuerpo del switch "Recibir notificaciones push" de la pestaña "Perfil" del cliente.
//
// EFECTOS:
//   - Actualiza cliente.push_activa_cliente.
//   - A partir de ese momento, NotificacionService.deboEnviarPush(usuario) devuelve
//     false para este cliente, y FirebaseService.enviarPush(...) no se invoca.
//   - La bandeja in-app sigue rellenándose con TODAS las notificaciones (regla del
//     CLAUDE.md: "in-app SIEMPRE, push opcional").
//
// NO REQUIERE AUDITORÍA porque es un cambio de configuración personal trivial.
// ============================================================================
