package org.victorino_style.dto.admin;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

// DTO de entrada para crear o editar un empleado desde el panel del administrador.
// Se usa en POST /admin/empleados (alta) y PUT /admin/empleados/{id} (edición).
// La foto NO viaja en este record: se sube por separado vía POST /admin/empleados/{id}/foto.
public record EmpleadoAdminRequest(

        // Nombre del empleado. Obligatorio, máx. 100 caracteres (igual que la columna `nombre_empleado`).
        @NotBlank(message = "El nombre es obligatorio")
        @Size(max = 100, message = "El nombre no puede superar los 100 caracteres")
        String nombre,

        // Apellidos del empleado. Obligatorios, máx. 150 caracteres.
        @NotBlank(message = "Los apellidos son obligatorios")
        @Size(max = 150, message = "Los apellidos no pueden superar los 150 caracteres")
        String apellidos,

        // Teléfono opcional. Si llega, debe respetar el límite de 20 caracteres.
        @Size(max = 20, message = "El teléfono no puede superar los 20 caracteres")
        String telefono,

        // Correo electrónico del empleado. Obligatorio, único en BD, máx. 254 caracteres.
        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no es válido")
        @Size(max = 254, message = "El correo no puede superar los 254 caracteres")
        String correo,

        // Contraseña provisional que el admin asigna al empleado. Solo se exige en alta.
        // En edición se acepta nulo (no se cambia). Misma política que el registro de cliente.
        @Pattern(
                regexp = "^$|^(?=.*[A-Z])(?=.*\\d).{8,72}$",
                message = "La contraseña debe tener entre 8 y 72 caracteres, al menos una mayúscula y un número"
        )
        String passwordProvisional
) {
}

// ============================================================================
// EmpleadoAdminRequest
// ----------------------------------------------------------------------------
// DTO que el administrador envía al panel para dar de alta o editar a un empleado.
//
// ¿PARA QUÉ SIRVE?
// - Lo recibe EmpleadoAdminController en los endpoints:
//      POST /admin/empleados            (alta de un nuevo empleado)
//      PUT  /admin/empleados/{id}       (edición de un empleado existente)
// - EmpleadoAdminService convierte el DTO en una fila de `usuario` + `empleado`
//   (herencia JOINED) y lo persiste con las validaciones de negocio.
//
// VALIDACIONES IMPORTANTES:
// - @NotBlank en nombre, apellidos y correo evita strings vacíos.
// - @Size respeta los límites de cada columna en BD.
// - @Email comprueba el formato del correo.
// - @Pattern de la contraseña usa una regex que también acepta cadena vacía
//   ("^$|...") porque en EDICIÓN el admin puede no querer cambiarla.
//
// FOTO:
// - La foto NO va en este DTO. Se sube en un endpoint separado multipart:
//      POST /admin/empleados/{id}/foto
// - El servicio rechaza el alta inicial si tras la creación no llega foto:
//   regla del CLAUDE.md "foto obligatoria al crear empleado".
//
// ROL:
// - Este DTO siempre crea filas con rol EMPLEADO. Si en el futuro el admin
//   quisiera convertir un empleado en administrador, se hará en otro endpoint.
// ============================================================================
