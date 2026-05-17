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
// Su función es permitir al administrador y empleado listar y obtener servicios,
// y restringir al administrador la creación, edición y baja.
//
// Este controlador:
// - Expone endpoints bajo la ruta base /admin/servicios
// - Permite acceso a ADMINISTRADOR y EMPLEADO para consultas
// - Requiere el rol ADMINISTRADOR para operaciones de modificación
// - No contiene lógica de negocio: delega todoo en ServicioService

@RestController
@RequestMapping("/admin/servicios") // Ruta base para todos los endpoints del controlador.
@PreAuthorize("hasAnyRole('ADMINISTRADOR', 'EMPLEADO')") // Permite acceso base a ambos roles.
@RequiredArgsConstructor
public class ServicioController {

    private final ServicioService servicioService;
    // para gestionar el catálogo de servicios.


    // ---- LISTADO ----
    @GetMapping // Accesible por ADMINISTRADOR y EMPLEADO
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
    @GetMapping("/{id}") // Accesible por ADMINISTRADOR y EMPLEADO
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
    @PreAuthorize("hasRole('ADMINISTRADOR')") // Restringido solo a administradores
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
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
    @PreAuthorize("hasRole('ADMINISTRADOR')") // Restringido solo a administradores
    @PutMapping("/{id}")
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
    @PreAuthorize("hasRole('ADMINISTRADOR')") // Restringido solo a administradores
    @DeleteMapping("/{id}")
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

        return ResponseEntity.noContent().build();
    }

    // ---- SUBIDA DE FOTO ----
    @PreAuthorize("hasRole('ADMINISTRADOR')") // Restringido solo a administradores
    @PostMapping(value = "/{id}/foto", consumes = "multipart/form-data")
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