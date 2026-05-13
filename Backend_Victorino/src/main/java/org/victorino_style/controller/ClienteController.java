package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.dto.admin.CitaAdminResponse;
import org.victorino_style.dto.cliente.ReservaClienteRequest;
import org.victorino_style.service.CitaService;

// Controlador REST para operaciones del cliente autenticado sobre sus citas.
// Reservar una nueva cita (dispara CONFIRMACION_RESERVA) y cancelar la propia
// cita (dispara CANCELACION_CLIENTE al empleado).
@RestController
@RequestMapping("/cliente")
@PreAuthorize("hasRole('CLIENTE')")
@RequiredArgsConstructor
public class ClienteController {

    private final CitaService citaService;

    // ---- POST /cliente/citas → RESERVA (CONFIRMACION_RESERVA al cliente) ----
    @PostMapping("/citas")
    @ResponseStatus(HttpStatus.CREATED)
    public CitaAdminResponse reservar(
            @AuthenticationPrincipal String idUsuarioJwt,
            @Valid @RequestBody ReservaClienteRequest request) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        return citaService.reservar(idCliente, request);
    }

    // ---- DELETE /cliente/citas/{idCita} → CANCELACION (CANCELACION_CLIENTE al empleado) ----
    @DeleteMapping("/citas/{idCita}")
    public ResponseEntity<Void> cancelar(
            @AuthenticationPrincipal String idUsuarioJwt,
            @PathVariable Long idCita) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        citaService.cancelarPorCliente(idCliente, idCita);
        return ResponseEntity.noContent().build();
    }
}
