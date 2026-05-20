package org.victorino_style.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.dto.auth.ForgotPasswordRequest;
import org.victorino_style.dto.auth.ResetPasswordRequest;
import org.victorino_style.dto.auth.VerifyOtpRequest;
import org.victorino_style.service.MailService;
import org.victorino_style.service.PasswordRecoveryService;

import java.util.Map;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Tag(name = "Recuperación de contraseña", description = "Solicitud, verificación y cambio de contraseña")
public class PasswordRecoveryController {

    private final PasswordRecoveryService passwordRecoveryService;
    private final MailService mailService;

    @PostMapping("/forgot-password")
    @Operation(summary = "Genera y enva un cdigo de recuperacin al correo del usuario")
    public ResponseEntity<Map<String, String>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        String codigo = passwordRecoveryService.crearCodigoRecuperacion(request.correo());
        try {
            mailService.enviarCodigoRecuperacion(request.correo(), codigo);
        } catch (Exception e) {
            // Invalidar el token para no dejar tokens huérfanos.
            // Usamos try-catch para que un fallo al invalidar no enmascare el error de correo.
            try {
                passwordRecoveryService.invalidarTokensActivos(request.correo());
            } catch (Exception ex) {
                // Ignorar errores secundarios al invalidar; lo importante es re-lanzar el error de correo.
            }
            // Re-lanzar como MailException para que GlobalExceptionHandler devuelva 503.
            if (e instanceof org.springframework.mail.MailException mailEx) {
                throw mailEx;
            }
            // Si no es MailException (p.ej. RuntimeException inesperada), envolverlo.
            throw new org.springframework.mail.MailSendException("Error inesperado al enviar correo: " + e.getMessage(), e);
        }
        return ResponseEntity.ok(Map.of("message", "Cdigo enviado correctamente"));
    }

    @PostMapping("/verify-otp")
    @Operation(summary = "Verifica si el código de recuperación es válido")
    public ResponseEntity<Map<String, String>> verifyOtp(
            @Valid @RequestBody VerifyOtpRequest request) {

        boolean codigoValido = passwordRecoveryService.verificarCodigo(
                request.correo(),
                request.codigo()
        );
        if (!codigoValido) {
            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "message",
                            "Código inválido o caducado"
                    ));
        }
        return ResponseEntity.ok(
                Map.of("message", "Código válido")
        );
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Actualiza la contraseña usando un código de recuperación válido")
    public ResponseEntity<Map<String, String>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request) {

        passwordRecoveryService.cambiarPassword(
                request.correo(),
                request.codigo(),
                request.nuevaPassword()
        );

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Contraseña actualizada correctamente"
                )
        );
    }
}