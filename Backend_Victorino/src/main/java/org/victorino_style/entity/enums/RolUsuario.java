
package org.victorino_style.entity.enums;

// Enumerado con los tres roles del sistema.
// Se mapea como ENUM en MySQL para garantizar integridad y limitar valores.
public enum RolUsuario {

    // Rol asignado a los clientes que usan la app para reservar citas.
    CLIENTE,

    // Rol asignado a los empleados de la peluquería.
    EMPLEADO,

    // Rol con permisos completos para gestionar todo el sistema.
    ADMINISTRADOR
}

// ============================================================================
// RolUsuario
// ----------------------------------------------------------------------------
// Este enum define los **tres roles posibles** dentro del sistema Victorino Style.
// Los roles determinan los permisos y el tipo de acceso que cada usuario tiene
// dentro de la aplicación.
//
// ¿PARA QUÉ SIRVE ESTE ENUM?
// - Se utiliza en la autenticación y autorización (Spring Security).
// - Se incluye dentro del JWT como claim para que el backend pueda saber
//   qué tipo de usuario está realizando la petición.
// - Se mapea como ENUM en MySQL, lo que significa que en la base de datos
//   se almacena como un valor de texto limitado a estas opciones.
//
// ROLES DISPONIBLES:
// - CLIENTE: usuario final que reserva citas y gestiona su perfil.
// - EMPLEADO: trabajador de la peluquería (puede ver citas, clientes, etc.).
// - ADMINISTRADOR: tiene acceso total al sistema.
//
// Este enum es fundamental para controlar permisos y comportamientos
// diferenciados entre los distintos tipos de usuarios.
// ============================================================================
