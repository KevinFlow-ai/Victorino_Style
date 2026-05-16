package org.victorino_style.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.victorino_style.dto.cliente.EmpleadoPublicoResponse;
import org.victorino_style.dto.cliente.ServicioPublicoResponse;
import org.victorino_style.mapper.CatalogoMapper;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.ServicioRepository;

import java.util.List;

// Controlador que expone el catalogo publico de servicios y empleados activos.
// Visible para CUALQUIER usuario autenticado (cliente, empleado o administrador),
// pero NO publico-sin-login (asi evitamos scraping del catalogo).
//
// Es el alimento principal del Home y del wizard del cliente:
//   - Home: lista de "Servicios destacados".
//   - Paso 1 del wizard: lista de servicios para seleccionar.
//   - Paso 2 del wizard: lista de empleados con foto.
@RestController
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
public class CatalogoController {

    private final ServicioRepository servicioRepository;
    private final EmpleadoRepository empleadoRepository;
    private final CatalogoMapper catalogoMapper;

    // GET /servicios → catalogo activo (sin servicios dados de baja logica).
    // Ordenados alfabeticamente por nombre.
    @GetMapping("/servicios")
    public List<ServicioPublicoResponse> listarServicios() {
        return servicioRepository.findByFechaEliminacionServicioIsNullOrderByNombreServicioAsc()
                .stream()
                .map(catalogoMapper::aRespuestaServicio)
                .toList();
    }

    // GET /empleados → empleados activos (sin baja logica del usuario).
    // Ordenados por nombre + apellidos.
    @GetMapping("/empleados")
    public List<EmpleadoPublicoResponse> listarEmpleados() {
        return empleadoRepository.findAllActivos()
                .stream()
                .map(catalogoMapper::aRespuestaEmpleado)
                .toList();
    }
}

// ============================================================================
// CatalogoController
// ----------------------------------------------------------------------------
// Controlador REST que sirve el catalogo publico de servicios y empleados.
//
// SEGURIDAD:
//   - @PreAuthorize("isAuthenticated()") -> exige token JWT valido, pero da igual el rol.
//   - El admin tiene sus propios endpoints en /admin/servicios y /admin/empleados que
//     devuelven mas campos (precio coste, correo del empleado, descanso, etc.).
//   - Este endpoint sirve DTOs ligeros (ServicioPublicoResponse, EmpleadoPublicoResponse)
//     que omiten datos sensibles.
//
// CONEXION CON EL FRONTEND:
//   - El Provider Riverpod `catalogoProvider` del modulo cliente llama a GET /servicios
//     y GET /empleados al abrir el Home y al pulsar pull-to-refresh.
//   - Asi el cliente ve cambios del admin (alta/edicion/baja) "en tiempo real" sin
//     reiniciar la app.
//
// FILTRADO:
//   - findByFechaEliminacionServicioIsNullOrderByNombreServicioAsc filtra los servicios
//     dados de baja logica (fecha_eliminacion_servicio IS NOT NULL).
//   - findAllActivos filtra los empleados cuyo usuario tiene fecha_eliminacion_usuario.
// ============================================================================
