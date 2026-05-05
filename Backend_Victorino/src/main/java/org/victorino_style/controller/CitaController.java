package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.dto.admin.AvisoClienteResponse;
import org.victorino_style.dto.admin.CitaAdminResponse;
import org.victorino_style.dto.admin.HistorialClienteResponse;
import org.victorino_style.dto.admin.WalkInRequest;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.service.CitaService;

import java.time.LocalDate;
import java.util.List;

// Controlador REST para la agenda global del admin, walk-in, historial cliente y avisos.

@RestController // Indica que esta clase es un controlador REST. Combina @Controller + @ResponseBody. Todos
// los métodos devuelven directamente datos (JSON normalmente)

@RequestMapping("/admin") // Define la ruta base para todos los endpoints de este controlador. Por ejemplo: /admin/agenda


@PreAuthorize("hasRole('ADMINISTRADOR')") //  Indica que solo usuarios con el rol ADMINISTRADOR pueden acceder a
// cualquiera de los métodos de este controlador.

@RequiredArgsConstructor //Genera un constructor con los argumentos requeridos. Un constructor que recibe CitaService.
public class CitaController {

    private final CitaService citaService;

    // ---- Endpoint: Agenda global ----
    @GetMapping("/agenda") // Métodoo HTTP: GET
    public List<CitaAdminResponse> agendaGlobal(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde, //Espera formato YYYY-MM-DD, por ejemplo 2025-12-25.
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta,
            @RequestParam(required = false) Long empleadoId,
            @RequestParam(required = false) EstadoCita estado) {
        return citaService.agendaGlobal(desde, hasta, empleadoId, estado);

        // Qué hace:
        //Devuelve una lista de citas (List<CitaAdminResponse>) para la agenda global del
        // administrador, filtrada por:
        //desde: fecha de inicio (obligatoria)
        //hasta: fecha de fin (obligatoria)
        //empleadoId: id del empleado (opcional)
        //estado: estado de la cita (opcional), por ejemplo En proceso, CANCELADA, etc.









    }

    // ---- Endpoint: HISTORIAL DE CLIENTE ----
    @GetMapping("/clientes/{id}/historial")// Ruta completa: /admin/clientes/{id=10}/historial
    public HistorialClienteResponse historialCliente(@PathVariable Long id) {
        return citaService.historialCliente(id);

        /*

        Qué hace:
        Devuelve el historial de citas de un cliente concreto.

        @PathVariable Long id:
        El id viene en la URL como parte de la ruta, no como parámetro de query. Ejemplo:
        /admin/clientes/5/historial → id = 5.

        Devuelve:
        Un objeto HistorialClienteResponse (probablemente con datos del cliente y sus citas).

        Flujo:
        1. Spring extrae el id de la URL.
        2. Llama a citaService.historialCliente(id).
        3. Devuelve el resultado como JSON.
         */



    }

    // ---- WALK-IN ----
    @PostMapping("/citas/walk-in") // Métoddo HTTP: POST. Ruta completa: /admin/citas/walk-in
    @ResponseStatus(HttpStatus.CREATED)
    public CitaAdminResponse crearWalkIn(@Valid @RequestBody WalkInRequest request) {
        return citaService.crearWalkIn(request);
    }

    // ---- AVISOS DE CANCELACIONES FRECUENTES ----
    @GetMapping("/avisos/cancelaciones-frecuentes") // Métodoo HTTP: GET
    public List<AvisoClienteResponse> avisos() {
        return citaService.avisosCancelacionesFrecuentes();

        /*
        Qué hace:
        Devuelve una lista de clientes con cancelaciones frecuentes

        Devuelve:
        List<AvisoClienteResponse> con la información de esos clientes/avisos.

        Flujo:

        1. Spring recibe la petición.
        2. Llama a citaService.avisosCancelacionesFrecuentes().
        3. Devuelve la lista como JSON.
        */
    }
}


/*
    ¿Qué tipo de archivo es este?
    Es un controlador REST de Spring Boot. Su responsabilidad es recibir peticiones HTTP, validar
    datos básicos, y delegar la lógica de negocio a una capa de servicio (CitaService).

    En concreto, este controlador gestiona cosas relacionadas con:
        Agenda global del administrador
        Historial de un cliente
        Creación de citas tipo walk-in (sin cita previa
        Avisos de clientes con cancelaciones frecuentes
        Es un controlador REST que expone endpoints bajo /admin.
        Está protegido por rol: solo ADMINISTRADOR puede acceder.
        No contiene lógica de negocio, solo Recibe peticiones HTTP.

 */