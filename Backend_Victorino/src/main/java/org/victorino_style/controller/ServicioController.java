package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.victorino_style.dto.admin.FotoResponse;
import org.victorino_style.dto.admin.ServicioAdminRequest;
import org.victorino_style.dto.admin.ServicioAdminResponse;
import org.victorino_style.service.ServicioService;

import java.util.List;

// Controlador REST para gestión del catálogo de servicios.
// Su función es permitir al administrador listar, obtener, crear, editar,
// dar de baja lógicamente y subir fotos de los servicios ofrecidos.
//
// Este controlador:
// - Expone endpoints bajo la ruta base /admin/servicios
// - Requiere el rol ADMINISTRADOR para acceder a cualquier endpoint
// - No contiene lógica de negocio: delega todoo en ServicioService
// - Maneja operaciones CRUD y subida de imágenes para los servicios

@RestController
@RequestMapping("/admin/servicios") // Ruta base para todos los endpoints del controlador.
@PreAuthorize("hasRole('ADMINISTRADOR')")
@RequiredArgsConstructor
public class ServicioController {

    private final ServicioService servicioService; // Servicio que contiene la lógica de negocio
    // para gestionar el catálogo de servicios.

    // ---- LISTADO ----
    @GetMapping // Métodoo HTTP: GET. Ruta completa: GET /admin/servicios
    public List<ServicioAdminResponse> listar(
            @RequestParam(name = "incluirInactivos", defaultValue = "false") boolean incluirInactivos) {
        // @RequestParam: parámetro opcional en la URL.
        // Ejemplo: /admin/servicios?incluirInactivos=true
        // defaultValue = "false": si no se envía, se usa false.

        return servicioService.listar(incluirInactivos);

        /*
        Qué hace:
        Devuelve una lista de servicios, pudiendo incluir los inactivos si se indica.

        Flujo:
        1. Spring lee el parámetro incluirInactivos.
        2. Llama a servicioService.listar(incluirInactivos).
        3. El servicio consulta la base de datos.
        4. El controlador devuelve la lista como JSON.
         */
    }

    // ---- DETALLE ----
    @GetMapping("/{id}") // Método HTTP: GET. Ruta completa: GET /admin/servicios/{id}
    public ServicioAdminResponse obtener(@PathVariable Long id) {
        // @PathVariable: el id viene en la URL. Ejemplo: /admin/servicios/7 → id = 7

        return servicioService.obtener(id);

        /*
        Qué hace:
        Devuelve la información detallada de un servicio concreto.

        Flujo:
        1. Spring extrae el id de la URL.
        2. Llama a servicioService.obtener(id).
        3. El servicio busca el servicio en la base de datos.
        4. El controlador devuelve el resultado como JSON.
         */
    }

    // ---- ALTA ----
    @PostMapping // Método HTTP: POST. Ruta completa: POST /admin/servicios
    @ResponseStatus(HttpStatus.CREATED) // Devuelve código 201 CREATED si todo va bien.
    public ServicioAdminResponse crear(@Valid @RequestBody ServicioAdminRequest request) {
        // @RequestBody: los datos vienen en el cuerpo de la petición en formato JSON.
        // @Valid: valida el objeto según sus anotaciones (ej: @NotNull, @Size, etc.)

        return servicioService.crear(request);

        /*
        Qué hace:
        Crea un nuevo servicio en el catálogo.

        Flujo:
        1. Spring convierte el JSON en un ServicioAdminRequest.
        2. Valida el contenido (@Valid).
        3. Llama a servicioService.crear(request).
        4. El servicio guarda el nuevo servicio en la base de datos.
        5. El controlador devuelve el servicio creado con código 201.
         */
    }

    // ---- EDICIÓN ----
    @PutMapping("/{id}") // Método HTTP: PUT. Ruta completa: PUT /admin/servicios/{id}
    public ServicioAdminResponse editar(@PathVariable Long id,
                                        @Valid @RequestBody ServicioAdminRequest request) {
        // @PathVariable id: identifica qué servicio se va a editar.
        // @RequestBody request: contiene los nuevos datos del servicio.

        return servicioService.editar(id, request);

        /*
        Qué hace:
        Actualiza los datos de un servicio existente.

        Flujo:
        1. Spring extrae el id de la URL.
        2. Convierte el JSON en ServicioAdminRequest y lo valida.
        3. Llama a servicioService.editar(id, request).
        4. El servicio actualiza el registro en la base de datos.
        5. El controlador devuelve el servicio actualizado como JSON.
         */
    }

    // ---- BAJA LÓGICA ----
    @DeleteMapping("/{id}") // Métoodo HTTP: DELETE. Ruta completa: DELETE /admin/servicios/{id}
    public ResponseEntity<Void> darBaja(@PathVariable Long id) {
        servicioService.darBaja(id);

        /*
        Qué hace:
        Realiza una baja lógica del servicio (normalmente marcarlo como inactivo).

        Flujo:
        1. Spring extrae el id.
        2. Llama a servicioService.darBaja(id).
        3. El servicio actualiza el estado del servicio en la base de datos.
         */

        return ResponseEntity.noContent().build(); // Devuelve 204 No Content.
    }

    // ---- SUBIDA DE FOTO ----
    @PostMapping(value = "/{id}/foto", consumes = "multipart/form-data")
    // Métodoo HTTP: POST. Ruta: POST /admin/servicios/{id}/foto
    // consumes = "multipart/form-data": indica que recibe un archivo.
    public FotoResponse subirFoto(@PathVariable Long id,
                                  @RequestParam("archivo") MultipartFile archivo) {
        // @RequestParam("archivo"): el archivo enviado desde un formulario.

        return servicioService.subirFoto(id, archivo);

        /*
        Qué hace:
        Sube o actualiza la foto asociada a un servicio.

        Flujo:
        1. Spring extrae el id del servicio.
        2. Recibe el archivo enviado (MultipartFile).
        3. Llama a servicioService.subirFoto(id, archivo).
        4. El servicio guarda la imagen (en disco, nube, etc.) y actualiza la referencia.
        5. El controlador devuelve información de la foto (FotoResponse).
         */
    }
}
