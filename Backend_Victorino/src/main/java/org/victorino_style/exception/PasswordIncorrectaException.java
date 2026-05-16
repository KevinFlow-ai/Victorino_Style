package org.victorino_style.exception;

// Lanzada cuando el usuario introduce una contraseña actual incorrecta al cambiar
// su contraseña o al eliminar su cuenta. Se traduce a HTTP 409 Conflict porque
// no se trata de credenciales de login (401) sino de una verificación adicional
// dentro de un flujo de un usuario ya autenticado.
public class PasswordIncorrectaException extends RuntimeException {

    public PasswordIncorrectaException() {
        super("La contraseña actual no es correcta");
    }

    public PasswordIncorrectaException(String mensaje) {
        super(mensaje);
    }
}

// ============================================================================
// PasswordIncorrectaException
// ----------------------------------------------------------------------------
// Se lanza en dos flujos sensibles del módulo cliente:
//  1) Cambio de contraseña: el cliente introduce la actual + la nueva, y la
//     actual no coincide con el hash BCrypt almacenado.
//  2) Eliminación de cuenta: el cliente confirma con su contraseña para evitar
//     borrados accidentales (sesiones secuestradas, dispositivos compartidos).
//
// ¿POR QUÉ 409 Y NO 401?
// - 401 (Unauthorized) implica "el cliente no está autenticado". Aquí el cliente
//   está perfectamente autenticado, pero falla una verificación de negocio.
// - 409 (Conflict) refleja mejor "tu petición choca con un estado del sistema"
//   (en este caso, tu contraseña actual no coincide con la almacenada).
//
// El frontend muestra un SnackBar amarillo (FailureConflicto), no rojo de auth.
// ============================================================================
