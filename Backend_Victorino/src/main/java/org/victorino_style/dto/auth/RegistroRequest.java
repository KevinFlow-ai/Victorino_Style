package org.victorino_style.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

// DTO de entrada para POST /auth/registro. Solo se registran clientes desde la app.
// Se usa Java record para inmutabilidad y concisión (Java 21).
public record RegistroRequest(

        // Nombre del cliente. Obligatorio, máx. 100 caracteres (mismo límite que la columna).
        @NotBlank(message = "El nombre es obligatorio")
        @Size(max = 100, message = "El nombre no puede superar los 100 caracteres")
        String nombre,

        // Apellidos del cliente. Obligatorios.
        // Máximo 150 caracteres.
        @NotBlank(message = "Los apellidos son obligatorios")
        @Size(max = 150, message = "Los apellidos no pueden superar los 150 caracteres")
        String apellidos,

        // Teléfono opcional. Si llega, debe respetar el límite de 20 caracteres.
        @Size(max = 20, message = "El teléfono no puede superar los 20 caracteres")
        String telefono,

        // Correo electrónico del cliente.
        // Obligatorio, con formato válido y máximo 254 caracteres.
        // Debe ser único en la base de datos.
        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no es válido")
        @Size(max = 254, message = "El correo no puede superar los 254 caracteres")
        String correo,

        // Política de pwd: 8-72 caracteres, al menos una mayúscula y un dígito.
        // 72 es el límite de BCrypt; más allá los caracteres se ignoran.
        @NotBlank(message = "La contraseña es obligatoria")
        @Pattern(
                regexp = "^(?=.*[A-Z])(?=.*\\d).{8,72}$",
                message = "La contraseña debe tener entre 8 y 72 caracteres, al menos una mayúscula y un número"
        )
        String password
) {
}


// ============================================================================
// RegistroRequest
// ----------------------------------------------------------------------------
// Este DTO representa el cuerpo que debe enviar el cliente (Flutter) cuando
// realiza una petición POST /auth/registro.
//
// ¿PARA QUÉ SIRVE?
// - Transporta los datos necesarios para registrar un nuevo CLIENTE.
// - Solo los clientes se registran desde la app; empleados y administradores
//   se crean desde el panel interno.
// - AuthController recibe este DTO, lo valida y lo envía a AuthService.
//
// ¿POR QUÉ ES UN RECORD?
// - Los records son inmutables, ideales para DTOs.
// - Reducen código repetitivo (getters, constructor, equals, hashCode).
// - Se serializan fácilmente a JSON.
//
// VALIDACIONES IMPORTANTES:
// - @NotBlank → evita campos vacíos.
// - @Size → controla límites máximos según la BD.
// - @Email → valida formato del correo.
// - @Pattern → valida la política de contraseñas (mayúscula + número + longitud).
//
// NOTA SOBRE LA CONTRASEÑA:
// - BCrypt solo procesa los primeros 72 caracteres, por eso el límite máximo.
// - La expresión regular exige:
//      * al menos una mayúscula
//      * al menos un dígito
//      * longitud entre 8 y 72 caracteres
// ============================================================================