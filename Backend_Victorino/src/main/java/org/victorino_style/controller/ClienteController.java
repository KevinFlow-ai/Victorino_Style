package org.victorino_style.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.service.CitaService;

// Este es un controlador REST para las operaciones que puede realizas el cliente sobre sus propias citas.
// Todas las rutas manajedas aquí exigen el rol de CLIENTE.
@RestController
@RequestMapping("/cliente")
@PreAuthorize("hasRole('CLIENTE')")
@RequiredArgsConstructor
public class ClienteController {

    private final CitaService citaService;

    // ============================================================
    //  PATCH /cliente/citas/{id}/cancelar
    // ============================================================
    // Con este manejo el cliente puede cancelar su propia cita. El servicio verificará que la cita le pertenece
    // y que está en estado confirmado. Y notificará al empleado con CANCELACION_CLIENTE.
    @PatchMapping("/citas/{id}/cancelar")
    public ResponseEntity<Void> cancelarCita(
            @PathVariable Long id,
            @AuthenticationPrincipal String idUsuarioJwt) {
        citaService.cancelarPorCliente(id, Long.parseLong(idUsuarioJwt));
        return ResponseEntity.noContent().build();
    }
}
