package org.victorino_style.dto.cliente;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// DTO de entrada para editar los datos personales del cliente autenticado.
// Lo recibe PUT /cliente/perfil. El id del cliente se extrae del JWT, no del cuerpo.
// La foto y la contraseña NO viajan aquí: tienen endpoints propios.
public record EditarPerfilClienteRequest(

        // Nombre. Obligatorio, máx. 100 caracteres (mismo límite que cliente.nombre_cliente).
        @NotBlank(message = "El nombre es obligatorio")
        @Size(max = 100, message = "El nombre no puede superar los 100 caracteres")
        String nombre,

        // Apellidos. Obligatorios, máx. 150 caracteres.
        @NotBlank(message = "Los apellidos son obligatorios")
        @Size(max = 150, message = "Los apellidos no pueden superar los 150 caracteres")
        String apellidos,

        // Correo electrónico. Obligatorio, formato válido, máx. 254 caracteres. Si cambia se
        // valida que no esté en uso por otro usuario (lanza CorreoDuplicadoException si choca).
        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no es válido")
        @Size(max = 254, message = "El correo no puede superar los 254 caracteres")
        String correo,

        // Teléfono opcional. Si llega, máx. 20 caracteres.
        @Size(max = 20, message = "El teléfono no puede superar los 20 caracteres")
        String telefono
) {
}

// ============================================================================
// EditarPerfilClienteRequest
// ----------------------------------------------------------------------------
// Cuerpo de la edición de datos personales del cliente desde la pestaña "Perfil".
//
// VALIDACIONES:
//  - @NotBlank en nombre, apellidos y correo evita strings vacíos.
//  - @Size respeta los límites de cada columna en BD.
//  - @Email comprueba el formato.
//
// QUÉ NO INCLUYE:
//  - Contraseña: se cambia en POST /cliente/perfil/cambiar-pwd con su propio DTO.
//  - Foto: se sube en POST /cliente/perfil/foto (multipart).
//  - Preferencia de push: PUT /cliente/perfil/notificaciones con ConfiguracionPushRequest.
//
// EFECTOS DE CAMBIAR EL CORREO:
//  - PerfilClienteService valida unicidad. Si choca → CorreoDuplicadoException (409).
//  - No requiere reautenticación: el JWT actual sigue siendo válido (el sub es id, no correo).
// ============================================================================
