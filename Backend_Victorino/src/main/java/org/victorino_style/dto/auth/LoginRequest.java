package org.victorino_style.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

// DTO de entrada para POST /auth/login. Compartido por los 3 roles.
public record LoginRequest(

        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no es válido")
        String correo,

        @NotBlank(message = "La contraseña es obligatoria")
        String password
) {
}


// ============================================================================
// LoginRequest
// ----------------------------------------------------------------------------
// Este DTO (Data Transfer Object) representa el cuerpo que debe enviar el
// cliente (Flutter) al realizar una petición POST /auth/login.
//
// ¿PARA QUÉ SIRVE?
// - Transporta las credenciales del usuario: correo y contraseña.
// - Es usado por AuthController para validar la entrada y delegar en AuthService.
// - Está anotado con validaciones (@NotBlank, @Email) para asegurar que los
//   datos enviados por el cliente son correctos antes de procesarlos.
//
// ¿POR QUÉ ES UN RECORD?
// - Los records son inmutables y perfectos para DTOs.
// - Reducen código repetitivo (getters, constructor, equals, hashCode).
// - Se serializan/deserializan fácilmente a JSON.
//
// VALIDACIONES IMPORTANTES:
// - @NotBlank: evita valores vacíos o solo espacios.
// - @Email: valida que el formato del correo sea correcto.
//
// Este DTO se usa para CLIENTE, EMPLEADO y ADMINISTRADOR, ya que el login es
// compartido para todos los roles.
// ============================================================================