package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.dto.AvisoGeneralRequest;
import org.victorino_style.dto.NotificacionDto;
import org.victorino_style.dto.RegistrarTokenFcmRequest;
import org.victorino_style.service.NotificacionService;

import java.util.List;

@RestController
@RequestMapping("/notificaciones")
@RequiredArgsConstructor
public class NotificacionController {

    private final NotificacionService notificacionService;

    // Registrar el token FCM del dispositivo. Publico porque se llama justo despues del login.
    @PostMapping("/fcm-token")
    public ResponseEntity<Void> registrarToken(@RequestBody RegistrarTokenFcmRequest request) {
        notificacionService.guardarTokenFcm(
                request.idUsuario(),
                request.tokenFcm(),
                request.plataformaFcm(),
                Boolean.TRUE.equals(request.esLoginExplicito())
        );
        return ResponseEntity.ok().build();
    }

    // Bandeja in-app del usuario autenticado. El id se extrae del JWT.
    @GetMapping
    public ResponseEntity<List<NotificacionDto>> obtener(
            @AuthenticationPrincipal String idUsuarioJwt) {
        Long idUsuario = Long.parseLong(idUsuarioJwt);
        return ResponseEntity.ok(notificacionService.obtenerNotificaciones(idUsuario));
    }

    // Marcar una notificacion como leida.
    @PatchMapping("/{id}/leer")
    public ResponseEntity<Void> marcarLeida(@PathVariable Long id) {
        notificacionService.marcarComoLeida(id);
        return ResponseEntity.ok().build();
    }

    // Enviar aviso general a un usuario concreto. Solo administradores.
    @PostMapping("/aviso-general")
    @PreAuthorize("hasRole('ADMINISTRADOR')")
    public ResponseEntity<Void> avisoGeneral(@Valid @RequestBody AvisoGeneralRequest req) {
        notificacionService.enviarAvisoGeneral(req.idDestinatario(), req.titulo(), req.cuerpo());
        return ResponseEntity.ok().build();
    }
}

