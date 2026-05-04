package org.victorino_style.exception;

// Lanzada en /auth/login cuando el correo no existe o la pwd no coincide.
// El mensaje es genérico a propósito (OWASP Authentication Cheat Sheet) para
// no filtrar si el correo está registrado.
// La traduce GlobalExceptionHandler a HTTP 401 Unauthorized.
public class CredencialesInvalidasException extends RuntimeException {

    public CredencialesInvalidasException() {
        super("Correo o contraseña incorrectos");
    }
}
