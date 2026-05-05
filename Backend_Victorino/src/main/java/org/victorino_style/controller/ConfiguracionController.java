package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.dto.admin.CierreAnualRequest;
import org.victorino_style.dto.admin.CierreAnualResponse;
import org.victorino_style.dto.admin.DescansoRequest;
import org.victorino_style.dto.admin.DescansoResponse;
import org.victorino_style.dto.admin.FestivoRequest;
import org.victorino_style.dto.admin.FestivoResponse;
import org.victorino_style.dto.admin.HorarioPeluqueriaRequest;
import org.victorino_style.dto.admin.HorarioPeluqueriaResponse;
import org.victorino_style.service.ConfiguracionService;

import java.util.List;

// Controlador REST de configuración del negocio: horario peluquería, descansos por
// empleado, festivos puntuales y cierre anual.


@RestController //Indica que esta clase expone endpoints REST y que todos los métodos devuelven JSON.
@RequestMapping("/admin") // Define la ruta base: Todos los endpoints empiezan por /admin: /admin/horario
@PreAuthorize("hasRole('ADMINISTRADOR')") // Solo usuarios con el rol ADMINISTRADOR pueden acceder a estos endpoints.
@RequiredArgsConstructor
public class ConfiguracionController {

    private final ConfiguracionService configuracionService;

    // ---- HORARIO SEMANAL ----
    @GetMapping("/horario")
    public HorarioPeluqueriaResponse obtenerHorario() {
        return configuracionService.obtenerHorario();
    }

    @PutMapping("/horario")
    public HorarioPeluqueriaResponse actualizarHorario(@Valid @RequestBody HorarioPeluqueriaRequest request) {
        return configuracionService.actualizarHorario(request);
    }

    // ---- DESCANSO POR EMPLEADO ----
    @PutMapping("/empleados/{id}/descanso")
    public DescansoResponse actualizarDescanso(@PathVariable Long id,
                                               @Valid @RequestBody DescansoRequest request) {
        return configuracionService.actualizarDescanso(id, request);
    }

    // ---- FESTIVOS ----
    @GetMapping("/festivos")
    public List<FestivoResponse> listarFestivos() {
        return configuracionService.listarFestivos();
    }

    @PostMapping("/festivos")
    @ResponseStatus(HttpStatus.CREATED)
    public FestivoResponse crearFestivo(@Valid @RequestBody FestivoRequest request) {
        return configuracionService.crearFestivo(request);
    }

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

    @PutMapping("/cierre-anual")
    public CierreAnualResponse actualizarCierreAnual(@Valid @RequestBody CierreAnualRequest request) {
        return configuracionService.actualizarCierreAnual(request);
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