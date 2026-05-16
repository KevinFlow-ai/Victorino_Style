package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.victorino_style.dto.cliente.CitaClienteResponse;
import org.victorino_style.dto.cliente.HuecoDisponibleResponse;
import org.victorino_style.dto.cliente.ModificarCitaRequest;
import org.victorino_style.dto.cliente.ReservarCitaRequest;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.service.CitaClienteService;
import org.victorino_style.service.DisponibilidadService;

import java.time.LocalDate;
import java.util.List;

// Controlador REST de todas las operaciones del cliente sobre SUS citas:
//   - Reservar, modificar, cancelar.
//   - Listar historial, ver detalle, obtener cita activa.
//   - Calcular huecos disponibles para el wizard.
//
// SEGURIDAD: todos los endpoints requieren rol CLIENTE. El idCliente se extrae
// del JWT (no del body) para evitar suplantaciones.
@RestController
@RequestMapping("/cliente/citas")
@PreAuthorize("hasRole('CLIENTE')")
@RequiredArgsConstructor
public class CitaClienteController {

    private final CitaClienteService citaClienteService;
    private final DisponibilidadService disponibilidadService;

    // GET /cliente/citas?estado=CONFIRMADA → historial del cliente con filtro opcional por estado.
    // Si estado se omite, devuelve todas las citas del cliente.
    @GetMapping
    public List<CitaClienteResponse> listarMisCitas(
            @AuthenticationPrincipal String idUsuarioJwt,
            @RequestParam(required = false) EstadoCita estado) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        return citaClienteService.listarMisCitas(idCliente, estado);
    }

    // GET /cliente/citas/activa → cita activa mas proxima del cliente (CONFIRMADA o EN_PROCESO).
    // Devuelve 200 con el cuerpo si existe, 204 No Content si no hay ninguna.
    // Lo usa el Home para decidir si pintar la card "Mi proxima cita" o el CTA "Reservar".
    @GetMapping("/activa")
    public ResponseEntity<CitaClienteResponse> obtenerCitaActiva(
            @AuthenticationPrincipal String idUsuarioJwt) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        return citaClienteService.obtenerMiCitaActiva(idCliente)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    // GET /cliente/citas/{id} → detalle de UNA cita propia.
    @GetMapping("/{id}")
    public CitaClienteResponse obtenerDetalle(
            @AuthenticationPrincipal String idUsuarioJwt,
            @PathVariable Long id) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        return citaClienteService.obtenerMiCita(idCliente, id);
    }

    // POST /cliente/citas → reservar (CONFIRMACION_RESERVA al cliente + NUEVA_CITA_EMPLEADO al empleado).
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CitaClienteResponse reservar(
            @AuthenticationPrincipal String idUsuarioJwt,
            @Valid @RequestBody ReservarCitaRequest request) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        return citaClienteService.reservar(idCliente, request);
    }

    // PUT /cliente/citas/{id} → modificar (solo si CONFIRMADA, MODIFICACION_CITA al empleado).
    @PutMapping("/{id}")
    public CitaClienteResponse modificar(
            @AuthenticationPrincipal String idUsuarioJwt,
            @PathVariable Long id,
            @Valid @RequestBody ModificarCitaRequest request) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        return citaClienteService.modificar(idCliente, id, request);
    }

    // POST /cliente/citas/{id}/cancelar → cancelar (CANCELACION_CLIENTE al empleado).
    @PostMapping("/{id}/cancelar")
    public ResponseEntity<Void> cancelar(
            @AuthenticationPrincipal String idUsuarioJwt,
            @PathVariable Long id) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        citaClienteService.cancelar(idCliente, id);
        return ResponseEntity.noContent().build();
    }

    // GET /cliente/citas/disponibilidad?idServicio=&fecha=&idEmpleado=&idCitaExcluir=
    // Lo usa el Paso 3 del wizard: devuelve la lista de chips de hora disponibles para
    // el servicio y la fecha indicados. idEmpleado puede omitirse (modo "Cualquiera").
    // idCitaExcluir se usa en modo edicion para que la propia cita no aparezca como ocupada.
    @GetMapping("/disponibilidad")
    public List<HuecoDisponibleResponse> calcularDisponibilidad(
            @RequestParam Long idServicio,
            @RequestParam LocalDate fecha,
            @RequestParam(required = false) Long idEmpleado,
            @RequestParam(required = false) Long idCitaExcluir) {
        return disponibilidadService.calcularHuecos(idServicio, fecha, idEmpleado, idCitaExcluir);
    }
}

// ============================================================================
// CitaClienteController
// ----------------------------------------------------------------------------
// Concentra los 7 endpoints del cliente sobre citas. Es un "delgado" como debe
// ser: solo orquesta llamadas a CitaClienteService y DisponibilidadService.
//
// CONTRATO REST FINAL (ruta base /api/v1):
//
//   GET    /cliente/citas?estado=...             → List<CitaClienteResponse>
//   GET    /cliente/citas/activa                 → CitaClienteResponse | 204
//   GET    /cliente/citas/{id}                   → CitaClienteResponse
//   GET    /cliente/citas/disponibilidad?...     → List<HuecoDisponibleResponse>
//   POST   /cliente/citas                        → 201 CitaClienteResponse
//   PUT    /cliente/citas/{id}                   → 200 CitaClienteResponse
//   POST   /cliente/citas/{id}/cancelar          → 204
//
// EXTRACCION DEL ID:
//   - @AuthenticationPrincipal devuelve el subject del JWT como String, que es el
//     id del usuario. Se parsea a Long. Es el mismo id de la herencia JOINED del
//     Cliente (id_usuario == id_cliente).
//
// ERRORES POSIBLES:
//   - 400 si fallan @Valid de los DTOs.
//   - 401 si no hay JWT valido (filtro previo).
//   - 403 si el rol no es CLIENTE.
//   - 404 si la cita no existe o no pertenece al cliente.
//   - 409 segun la regla incumplida (mismo dia, semana, servicio, solape, etc.).
// ============================================================================
