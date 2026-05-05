package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.victorino_style.dto.admin.CancelacionMasivaResponse;
import org.victorino_style.dto.admin.EmpleadoAdminRequest;
import org.victorino_style.dto.admin.EmpleadoAdminResponse;
import org.victorino_style.dto.admin.FotoResponse;
import org.victorino_style.service.CancelacionMasivaService;
import org.victorino_style.service.EmpleadoService;

import java.util.List;

// Controlador REST para la gestión de empleados desde el panel del administrador.
// Todos los endpoints requieren rol ADMINISTRADOR.
// Controlador REST para la gestión de empleados en el panel de administración.
// Permite listar, ver detalle, crear, editar, dar de baja lógicamente,
// subir foto y cancelar masivamente citas futuras de un empleado.
//
// Es un controlador REST que expone endpoints bajo /admin/empleados.
// Está protegido por rol: solo ADMINISTRADOR puede acceder.
// No contiene lógica de negocio: recibe peticiones HTTP y delega en EmpleadoService
// y CancelacionMasivaService.

@RestController // Indica que esta clase es un controlador REST. Combina @Controller + @ResponseBody.
// Todos los métodos devuelven directamente datos (normalmente en formato JSON).

@RequestMapping("/admin/empleados") // Define la ruta base para todos los endpoints de este controlador.
// Por ejemplo: /admin/empleados, /admin/empleados/{id}, /admin/empleados/{id}/foto, etc.

@PreAuthorize("hasRole('ADMINISTRADOR')") // Indica que solo usuarios con el rol ADMINISTRADOR pueden acceder
// a cualquiera de los métodos de este controlador.

@RequiredArgsConstructor // Genera un constructor con los argumentos requeridos (los campos final).
// Spring usará ese constructor para inyectar EmpleadoService y CancelacionMasivaService.
public class EmpleadoController {

    private final EmpleadoService empleadoService; // Servicio que contiene la lógica de negocio relacionada con empleados.
    private final CancelacionMasivaService cancelacionMasivaService; // Servicio para cancelar citas futuras de un empleado.

    // ---- LISTADO ----
    @GetMapping // Método HTTP: GET. Ruta completa: GET /admin/empleados
    public List<EmpleadoAdminResponse> listar(
            @RequestParam(name = "incluirInactivos", defaultValue = "false") boolean incluirInactivos) {
        // @RequestParam: el parámetro viene en la query string, por ejemplo:
        // /admin/empleados?incluirInactivos=true
        // defaultValue = "false": si no se envía el parámetro, se toma false por defecto.

        return empleadoService.listar(incluirInactivos);

        /*
        Qué hace:
        Devuelve una lista de empleados (List<EmpleadoAdminResponse>), pudiendo incluir o no
        los empleados inactivos según el valor de incluirInactivos.

        Flujo:
        1. Spring lee el parámetro incluirInactivos de la URL (o usa false si no se envía).
        2. Llama a empleadoService.listar(incluirInactivos).
        3. El servicio consulta la base de datos y devuelve la lista de empleados.
        4. El controlador devuelve esa lista como JSON.
         */
    }

    // ---- DETALLE ----
    @GetMapping("/{id}") // Método HTTP: GET. Ruta completa: GET /admin/empleados/{id}
    public EmpleadoAdminResponse obtener(@PathVariable Long id) {
        // @PathVariable: el id viene en la ruta, por ejemplo:
        // /admin/empleados/5 → id = 5

        return empleadoService.obtener(id);

        /*
        Qué hace:
        Devuelve la información detallada de un empleado concreto.

        Devuelve:
        Un EmpleadoAdminResponse con los datos del empleado.

        Flujo:
        1. Spring extrae el id de la URL.
        2. Llama a empleadoService.obtener(id).
        3. El servicio busca el empleado en la base de datos.
        4. El controlador devuelve el resultado como JSON.
         */
    }

    // ---- ALTA ----
    @PostMapping // Método HTTP: POST. Ruta completa: POST /admin/empleados
    @ResponseStatus(HttpStatus.CREATED) // Si todo va bien, responde con código 201 CREATED.
    public EmpleadoAdminResponse crear(@Valid @RequestBody EmpleadoAdminRequest request) {
        // @RequestBody: los datos del empleado vienen en el cuerpo de la petición en formato JSON.
        // @Valid: se valida el objeto EmpleadoAdminRequest según sus anotaciones de validación.

        return empleadoService.crear(request);

        /*
        Qué hace:
        Crea un nuevo empleado con los datos recibidos en el cuerpo de la petición.

        Devuelve:
        Un EmpleadoAdminResponse con la información del empleado recién creado.

        Flujo:
        1. Spring convierte el JSON del body en un EmpleadoAdminRequest.
        2. Valida el objeto (@Valid).
        3. Llama a empleadoService.crear(request).
        4. El servicio guarda el nuevo empleado en la base de datos.
        5. El controlador devuelve el empleado creado con código 201 CREATED.
         */
    }

    // ---- EDICIÓN ----
    @PutMapping("/{id}") // Método HTTP: PUT. Ruta completa: PUT /admin/empleados/{id}
    public EmpleadoAdminResponse editar(@PathVariable Long id,
                                        @Valid @RequestBody EmpleadoAdminRequest request) {
        // @PathVariable id: identifica qué empleado se va a editar.
        // @RequestBody request: contiene los nuevos datos del empleado.
        // @Valid: valida el contenido del request.

        return empleadoService.editar(id, request);

        /*
        Qué hace:
        Actualiza los datos de un empleado existente.

        Devuelve:
        Un EmpleadoAdminResponse con los datos actualizados del empleado.

        Flujo:
        1. Spring extrae el id de la URL.
        2. Convierte el JSON del body en EmpleadoAdminRequest y lo valida.
        3. Llama a empleadoService.editar(id, request).
        4. El servicio actualiza el empleado en la base de datos.
        5. El controlador devuelve el empleado actualizado como JSON.
         */
    }

    // ---- BAJA LÓGICA ----
    @DeleteMapping("/{id}") // Método HTTP: DELETE. Ruta completa: DELETE /admin/empleados/{id}
    public ResponseEntity<Void> darBaja(@PathVariable Long id) {
        // @PathVariable id: identifica qué empleado se va a dar de baja.

        empleadoService.darBaja(id);

        /*
        Qué hace:
        Realiza una baja lógica del empleado (normalmente marcarlo como inactivo en lugar de borrarlo físicamente).

        Flujo:
        1. Spring extrae el id de la URL.
        2. Llama a empleadoService.darBaja(id).
        3. El servicio marca al empleado como inactivo en la base de datos.
         */

        return ResponseEntity.noContent().build();
        // Devuelve una respuesta HTTP 204 No Content (operación correcta sin cuerpo de respuesta).
    }

    // ---- SUBIDA DE FOTO (multipart) ----
    @PostMapping(value = "/{id}/foto", consumes = "multipart/form-data")
    // Método HTTP: POST. Ruta: POST /admin/empleados/{id}/foto
    // consumes = "multipart/form-data": indica que este endpoint recibe un formulario con archivos (subida de ficheros).
    public FotoResponse subirFoto(@PathVariable Long id,
                                  @RequestParam("archivo") MultipartFile archivo) {
        // @PathVariable id: empleado al que se le sube la foto.
        // @RequestParam("archivo"): el archivo enviado en el formulario con el nombre "archivo".

        return empleadoService.subirFoto(id, archivo);

        /*
        Qué hace:
        Sube o actualiza la foto de un empleado.

        Devuelve:
        Un FotoResponse con información sobre la foto (por ejemplo, URL o nombre del archivo).

        Flujo:
        1. Spring extrae el id de la URL.
        2. Lee el archivo enviado en el formulario (MultipartFile).
        3. Llama a empleadoService.subirFoto(id, archivo).
        4. El servicio guarda la foto (en disco, en la nube, etc.) y actualiza la referencia en la base de datos.
        5. El controlador devuelve la información de la foto como JSON.
         */
    }

    // ---- CANCELACIÓN MASIVA DE CITAS FUTURAS ----
    @PostMapping("/{id}/cancelar-citas") // Método HTTP: POST. Ruta: POST /admin/empleados/{id}/cancelar-citas
    public CancelacionMasivaResponse cancelarCitasFuturas(@PathVariable Long id) {
        // @PathVariable id: empleado cuyas citas futuras se van a cancelar.

        return cancelacionMasivaService.cancelarFuturasDelEmpleado(id);

        /*
        Qué hace:
        Cancela de forma masiva todas las citas futuras asociadas a un empleado concreto.
        Esto puede usarse, por ejemplo, si el empleado se va de la empresa o estará ausente
        durante un tiempo prolongado.

        Devuelve:
        Un CancelacionMasivaResponse con información sobre cuántas citas se cancelaron, etc.

        Flujo:
        1. Spring extrae el id de la URL.
        2. Llama a cancelacionMasivaService.cancelarFuturasDelEmpleado(id).
        3. El servicio busca todas las citas futuras del empleado y las marca como canceladas.
        4. El controlador devuelve el resultado de la cancelación masiva como JSON.
         */
    }
}

/*
Resumen del archivo:

Este archivo define el EmpleadoController, un controlador REST de Spring Boot
para gestionar empleados desde el panel de administración.

Responsabilidades:
- Listar empleados (con opción de incluir inactivos).
- Obtener el detalle de un empleado.
- Crear nuevos empleados.
- Editar empleados existentes.
- Dar de baja lógica a empleados.
- Subir la foto de un empleado (multipart/form-data).
- Cancelar masivamente las citas futuras de un empleado.

Características:
- Todos los endpoints están bajo la ruta base /admin/empleados.
- Solo accesible para usuarios con rol ADMINISTRADOR (@PreAuthorize).
- No contiene lógica de negocio: delega en EmpleadoService y CancelacionMasivaService.
- Usa DTOs (EmpleadoAdminRequest, EmpleadoAdminResponse, FotoResponse, CancelacionMasivaResponse)
  para separar la capa de API de la capa de entidades de base de datos.
*/

