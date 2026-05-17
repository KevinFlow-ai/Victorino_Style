package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.dto.empleado.ConfiguracionEmpleadoRequest;
import org.victorino_style.dto.empleado.PerfilEmpleadoResponse;
import org.victorino_style.service.EmpleadoService;

/**
 * Controlador para que el empleado autenticado gestione su propio perfil y configuración.
 */
@RestController
@RequestMapping("/empleado/perfil")
@PreAuthorize("hasRole('EMPLEADO')")
@RequiredArgsConstructor
public class PerfilEmpleadoController {

    private final EmpleadoService empleadoService;

    @GetMapping
    public PerfilEmpleadoResponse obtenerPerfil(@AuthenticationPrincipal String idUsuarioJwt) {
        Long idEmpleado = Long.parseLong(idUsuarioJwt);
        return empleadoService.obtenerPerfil(idEmpleado);
    }

    @PutMapping("/configuracion")
    public ResponseEntity<Void> actualizarConfiguracion(
            @AuthenticationPrincipal String idUsuarioJwt,
            @Valid @RequestBody ConfiguracionEmpleadoRequest request) {
        Long idEmpleado = Long.parseLong(idUsuarioJwt);
        empleadoService.actualizarConfiguracion(idEmpleado, request);
        return ResponseEntity.noContent().build();
    }
}
