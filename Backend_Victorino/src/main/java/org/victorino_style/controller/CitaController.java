package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.dto.admin.*; // Importamos todos los DTOs necesarios
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.service.CitaService;

import java.security.Principal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Controlador REST para la agenda global del admin, walk-in, historial cliente y avisos.
 *
 * Es un controlador REST que expone endpoints bajo /admin.
 * Está protegido por rol: ADMINISTRADOR y EMPLEADO pueden acceder a la mayoría.
 * No contiene lógica de negocio, solo recibe peticiones HTTP.
 */
@RestController
@RequestMapping("/admin")
@PreAuthorize("hasAnyRole('ADMINISTRADOR', 'EMPLEADO')")
@RequiredArgsConstructor
public class CitaController {

    private final CitaService citaService;

    // ---- Endpoint: Agenda global ----
    @GetMapping("/agenda")
    public List<CitaAdminResponse> agendaGlobal(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta,
            @RequestParam(required = false) Long empleadoId,
            @RequestParam(required = false) EstadoCita estado) {
        return citaService.agendaGlobal(desde, hasta, empleadoId, estado);
    }

    // ---- Endpoint: HISTORIAL DE CLIENTE ----
    @GetMapping("/clientes/{id}/historial")
    public HistorialClienteResponse historialCliente(@PathVariable Long id) {
        return citaService.historialCliente(id);
    }

    // ---- WALK-IN ----
    @PostMapping("/citas/walk-in")
    @ResponseStatus(HttpStatus.CREATED)
    public CitaAdminResponse crearWalkIn(@Valid @RequestBody WalkInRequest request) {
        return citaService.crearWalkIn(request);
    }

    // ---- Endpoint: Marcar como NO PRESENTADO ----
    @PatchMapping("/citas/{id}/no-presentado")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void marcarNoPresentado(@PathVariable Long id) {
        citaService.marcarNoPresentado(id);
    }

    // ---- NUEVO: Resumen de Perfil por ID (Usado por la App) ----
    @GetMapping("/empleados/{id}/resumen")
    public EmpleadoPerfilResumenDTO obtenerResumenEmpleado(@PathVariable Long id) {
        // Buscamos directamente por ID recibido en la URL
        return citaService.obtenerResumenPerfilPorId(id);
    }

    // ---- NUEVO: Cambio de contraseña ----
    @PatchMapping("/empleados/me/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void cambiarPassword(Principal principal, @RequestBody Map<String, String> passwords) {
        // principal.getName() devuelve el identificador (ID en este proyecto) del usuario logueado
        citaService.actualizarPassword(
                principal.getName(),
                passwords.get("oldPassword"),
                passwords.get("newPassword")
        );
    }

    // ---- AVISOS DE CANCELACIONES FRECUENTES
    @PreAuthorize("hasRole('ADMINISTRADOR')")
    @GetMapping("/avisos/cancelaciones-frecuentes")
    public List<AvisoClienteResponse> avisos() {
        return citaService.avisosCancelacionesFrecuentes();
    }
}
