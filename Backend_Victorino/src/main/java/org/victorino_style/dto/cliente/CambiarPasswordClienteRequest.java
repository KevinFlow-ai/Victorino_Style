package org.victorino_style.dto.cliente;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

// DTO de entrada para que el cliente cambie su contraseña desde la pestaña "Perfil".
// Lo recibe POST /cliente/perfil/cambiar-pwd. Requiere la actual + la nueva para evitar
// cambios desde sesiones secuestradas. Mismas reglas de complejidad que en el registro.
public record CambiarPasswordClienteRequest(

        // Contraseña actual del cliente, sin hash. El servicio la compara contra el BCrypt
        // almacenado con passwordEncoder.matches(). Si no coincide → 409 PasswordIncorrecta.
        @NotBlank(message = "La contraseña actual es obligatoria")
        String actual,

        // Contraseña nueva. Debe tener entre 8 y 72 caracteres, al menos una mayúscula
        // y un número. Misma regex que registro/empleado para mantener consistencia.
        @NotBlank(message = "La contraseña nueva es obligatoria")
        @Pattern(
                regexp = "^(?=.*[A-Z])(?=.*\\d).{8,72}$",
                message = "La contraseña debe tener entre 8 y 72 caracteres, al menos una mayúscula y un número"
        )
        String nueva
) {
}

// ============================================================================
// CambiarPasswordClienteRequest
// ----------------------------------------------------------------------------
// Cuerpo del cambio de contraseña del cliente desde la pestaña "Perfil".
//
// FLUJO:
//   1. Frontend envía {actual, nueva}.
//   2. PerfilClienteService.cambiarPassword():
//      - Busca el Usuario por id (del JWT).
//      - passwordEncoder.matches(actual, usuario.contrasenaUsuario)
//        → si false: throw PasswordIncorrectaException (409).
//      - Hashea la nueva con BCrypt cost 10 y la guarda.
//      - Revoca todos los refresh_token del usuario (fuerza relogin en otros dispositivos).
//      - Genera notificación CONTRASENA_ACTUALIZADA (in-app + push si activa).
//      - Registra auditoría "CAMBIAR_PWD".
//   3. Devuelve 204 No Content.
//
// ¿POR QUÉ EXIGIR LA ACTUAL?
//   - Previene cambios desde sesiones secuestradas o dispositivos olvidados.
//   - El flujo "olvidé mi contraseña" usa el código de recuperación por correo
//     (otro endpoint distinto, NO este).
// ============================================================================
