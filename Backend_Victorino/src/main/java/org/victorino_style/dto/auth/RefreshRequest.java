package org.victorino_style.dto.auth;

import jakarta.validation.constraints.NotBlank; // Importa la validación @NotBlank para asegurar que el campo no esté vacío.

// DTO de entrada para POST /auth/refresh. El cliente envía el refresh token tal cual lo recibió.
public record RefreshRequest(

        @NotBlank(message = "El refresh token es obligatorio")
        String refreshToken
) {
}


// ============================================================================
// RefreshRequest
// ----------------------------------------------------------------------------
// Este DTO representa el cuerpo que debe enviar el cliente (Flutter) cuando
// realiza una petición POST /auth/refresh.
//
// ¿PARA QUÉ SIRVE?
// - El cliente envía aquí el *refresh token* tal cual lo recibió durante el login.
// - El backend usa ese refresh token para generar un nuevo access token sin que
//   el usuario tenga que volver a iniciar sesión.
// - Es parte del flujo estándar de autenticación basada en JWT.
//
// VALIDACIÓN:
// - @NotBlank asegura que el refresh token no venga vacío.
//   Si el cliente envía un string vacío o solo espacios, Spring devuelve 400
//   automáticamente antes de llegar al servicio.
//
// NOTA IMPORTANTE:
// - El access token NO se envía aquí porque ya va en el header Authorization.
// - Este DTO solo transporta el refresh token que se usará para renovar la sesión.
// ============================================================================