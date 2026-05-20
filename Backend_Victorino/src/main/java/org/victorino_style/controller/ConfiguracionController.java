package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.dto.admin.CierreAnualRequest;
import org.victorino_style.dto.admin.CierreAnualResponse;
import org.victorino_style.dto.admin.ConfiguracionCorreoRequest;
import org.victorino_style.dto.admin.ConfiguracionCorreoResponse;
import org.victorino_style.dto.admin.DescansoRequest;
import org.victorino_style.dto.admin.DescansoResponse;
import org.victorino_style.dto.admin.FestivoRequest;
import org.victorino_style.dto.admin.FestivoResponse;
import org.victorino_style.dto.admin.HorarioPeluqueriaRequest;
import org.victorino_style.dto.admin.HorarioPeluqueriaResponse;
import org.victorino_style.repository.UsuarioRepository;
import org.victorino_style.service.ConfiguracionService;
import org.victorino_style.service.MailService;

import java.util.Map;

import java.util.List;

// Controlador REST de configuración del negocio: horario peluquería, descansos por
// empleado, festivos puntuales y cierre anual.


@RestController
@RequestMapping("/admin")
@PreAuthorize("hasAnyRole('ADMINISTRADOR', 'EMPLEADO')")
@RequiredArgsConstructor
public class ConfiguracionController {

    private final ConfiguracionService configuracionService;
    private final MailService mailService;
    private final UsuarioRepository usuarioRepository;

    // ---- HORARIO SEMANAL ----
    @GetMapping("/horario") // Acceso para EMPLEADO y ADMINISTRADOR (hereda de la clase)
    public HorarioPeluqueriaResponse obtenerHorario() {
        return configuracionService.obtenerHorario();
    }

    @PreAuthorize("hasRole('ADMINISTRADOR')") // Solo el administrador puede editar el horario
    @PutMapping("/horario")
    public HorarioPeluqueriaResponse actualizarHorario(@Valid @RequestBody HorarioPeluqueriaRequest request) {
        return configuracionService.actualizarHorario(request);
    }

    // ---- DESCANSO POR EMPLEADO ----
    @PreAuthorize("hasRole('ADMINISTRADOR')") // Solo el administrador configura descansos
    @PutMapping("/empleados/{id}/descanso")
    public DescansoResponse actualizarDescanso(@PathVariable Long id,
                                               @Valid @RequestBody DescansoRequest request) {
        return configuracionService.actualizarDescanso(id, request);
    }

    // ---- FESTIVOS ----
    @GetMapping("/festivos") // Acceso para EMPLEADO y ADMINISTRADOR
    public List<FestivoResponse> listarFestivos() {
        return configuracionService.listarFestivos();
    }

    @PreAuthorize("hasRole('ADMINISTRADOR')") // Solo administrador crea festivos
    @PostMapping("/festivos")
    @ResponseStatus(HttpStatus.CREATED)
    public FestivoResponse crearFestivo(@Valid @RequestBody FestivoRequest request) {
        return configuracionService.crearFestivo(request);
    }

    @PreAuthorize("hasRole('ADMINISTRADOR')") // Solo administrador elimina festivos
    @DeleteMapping("/festivos/{id}")
    public ResponseEntity<Void> eliminarFestivo(@PathVariable Long id) {
        configuracionService.eliminarFestivo(id);
        return ResponseEntity.noContent().build();
    }

    // ---- CIERRE ANUAL ----
    @GetMapping("/cierre-anual")
    public CierreAnualResponse obtenerCierreAnual() {
        return configuracionService.obtenerCierreAnual();
    }

    @PreAuthorize("hasRole('ADMINISTRADOR')") // Solo administrador edita el cierre anual
    @PutMapping("/cierre-anual")
    public CierreAnualResponse actualizarCierreAnual(@Valid @RequestBody CierreAnualRequest request) {
        return configuracionService.actualizarCierreAnual(request);
    }

    // ---- CONFIGURACIÓN DE CORREO (SMTP DINÁMICO) ----

    /**
     * GET /admin/correo — Devuelve la configuración SMTP guardada en BD.
     * Sin contraseña por seguridad.
     */
    @GetMapping("/correo")
    public ConfiguracionCorreoResponse obtenerConfigCorreo() {
        return configuracionService.obtenerConfigCorreo();
    }

    /**
     * PUT /admin/correo — Guarda la configuración SMTP.
     */
    @PreAuthorize("hasRole('ADMINISTRADOR')")
    @PutMapping("/correo")
    public ConfiguracionCorreoResponse actualizarConfigCorreo(
            @Valid @RequestBody ConfiguracionCorreoRequest request) {
        return configuracionService.actualizarConfigCorreo(request);
    }

    /**
     * POST /admin/correo/probar — Envía un correo de prueba al propio admin
     * para verificar que la configuración SMTP funciona.
     * Si falla, el GlobalExceptionHandler devuelve 503 con el motivo exacto.
     *
     * Nota: el principal del SecurityContext es el ID numérico del usuario (String),
     * no el correo. Se busca en BD para obtener la dirección de email real.
     */
    @PreAuthorize("hasRole('ADMINISTRADOR')")
    @PostMapping("/correo/probar")
    public ResponseEntity<Map<String, String>> probarCorreo() {
        // El JwtAuthenticationFilter pone el ID del usuario como principal ("1", "2"…)
        String idStr = org.springframework.security.core.context.SecurityContextHolder
                .getContext().getAuthentication().getName();
        Long id = Long.parseLong(idStr);
        String correoAdmin = usuarioRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"))
                .getCorreoUsuario();

        mailService.enviarCorreoPrueba(correoAdmin);
        return ResponseEntity.ok(Map.of("message",
                "Correo de prueba enviado a " + correoAdmin + ". Revisa tu bandeja de entrada."));
    }
}



    /*
        Es otro controlador REST de Spring Boot, encargado de gestionar toda la configuración del sistema relacionada con:

        Horario semanal de la peluquería
        Descansos de empleados
        Festivos
        Cierre anual
        Es decir: todoo lo que un administrador puede configurar sobre el funcionamiento del negocio
     */