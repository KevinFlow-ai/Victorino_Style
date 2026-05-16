package org.victorino_style.dto.cliente;

import jakarta.validation.constraints.NotBlank;

// DTO de entrada para eliminar la cuenta del cliente autenticado.
// Lo recibe DELETE /cliente/perfil. Requiere la contraseña actual como confirmación.
public record EliminarCuentaRequest(

        // Contraseña actual del cliente, sin hash. Si no coincide con el BCrypt almacenado
        // → 409 PasswordIncorrecta. Es la última barrera contra borrados accidentales.
        @NotBlank(message = "La contraseña es obligatoria para eliminar la cuenta")
        String password
) {
}

// ============================================================================
// EliminarCuentaRequest
// ----------------------------------------------------------------------------
// Cuerpo de la eliminación de cuenta del cliente (botón rojo "Eliminar mi cuenta"
// en la pestaña "Perfil" → modal de doble confirmación → introducir contraseña).
//
// FLUJO COMPLETO (PerfilClienteService.eliminarCuenta):
//   1. Verificar password vs hash BCrypt (si no coincide → 409).
//   2. Buscar todas las citas futuras CONFIRMADAS del cliente.
//   3. Por cada una, en transacción REQUIRES_NEW (igual que la cancelación masiva del admin):
//        - estado = CANCELADA_PELUQUERIA.
//        - Notificar al empleado con CANCELACION_CLIENTE + cuerpo "Cliente eliminado".
//   4. Anonimizar Cliente: nombre="Cliente eliminado", apellidos="", teléfono=null, foto=null.
//   5. Anonimizar Usuario: correo="eliminado-{id}@victorino.es", contraseña aleatoria,
//      fechaEliminacionUsuario=now, fechaEliminacionCliente=now.
//   6. Revocar todos los refresh_token y borrar todos los device_token_fcm.
//   7. Auditoría "ELIMINAR_CUENTA".
//   8. Devuelve 204. Las citas pasadas quedan apuntando al id anonimizado (histórico).
//
// REGLA RGPD (regla 13 del CLAUDE.md):
//   - Soft-delete con anonimización: no se borra fila, se anonimiza para conservar
//     histórico de citas con id pero sin datos personales identificables.
// ============================================================================
