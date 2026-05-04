package org.victorino_style.dto.auth;

import jakarta.validation.constraints.NotBlank;

// DTO de entrada para POST /auth/logout. El access token va en la cabecera Authorization.
public record LogoutRequest(

        @NotBlank(message = "El refresh token es obligatorio")
        String refreshToken
) {
}


// ============================================================================
// LogoutRequest
// ----------------------------------------------------------------------------
// Este DTO representa el cuerpo que debe enviar el cliente (Flutter) cuando
// realiza una petición POST /auth/logout.
//
// ¿PARA QUÉ SIRVE?
// - El logout en tu backend NO se hace borrando tokens en el cliente.
// - Aquí el cliente envía el *refresh token* que quiere revocar.
// - AuthService se encarga de invalidarlo (por ejemplo, marcándolo como revocado
//   en la base de datos o eliminándolo de la lista de tokens válidos).
//
// ¿POR QUÉ ES UN RECORD?
// - Los records son inmutables, ideales para DTOs.
// - Reducen código repetitivo (getters, constructor, equals, hashCode).
// - Se serializan fácilmente a JSON.
//
// VALIDACIÓN:
// - @NotBlank asegura que el refresh token no venga vacío.
//   Si el cliente envía un string vacío o solo espacios, la petición falla
//   automáticamente con un error 400 antes de llegar al servicio.
//
// NOTA IMPORTANTE:
// - El access token NO se envía aquí porque ya va en el header Authorization.
// - Este DTO solo transporta el refresh token que se quiere revocar.
// ============================================================================