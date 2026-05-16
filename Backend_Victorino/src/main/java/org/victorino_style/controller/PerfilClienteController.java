package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.victorino_style.dto.cliente.CambiarPasswordClienteRequest;
import org.victorino_style.dto.cliente.ConfiguracionPushRequest;
import org.victorino_style.dto.cliente.EditarPerfilClienteRequest;
import org.victorino_style.dto.cliente.EliminarCuentaRequest;
import org.victorino_style.dto.cliente.PerfilClienteResponse;
import org.victorino_style.dto.admin.FotoResponse;
import org.victorino_style.service.PerfilClienteService;

// Controlador REST de la pestaña Perfil del cliente final autenticado.
// Cubre lectura del perfil, edicion de datos, foto, pwd, switch push y eliminacion de cuenta.
@RestController
@RequestMapping("/cliente/perfil")
@PreAuthorize("hasRole('CLIENTE')")
@RequiredArgsConstructor
public class PerfilClienteController {

    private final PerfilClienteService perfilClienteService;

    // GET /cliente/perfil → datos personales + flag push.
    @GetMapping
    public PerfilClienteResponse obtenerPerfil(
            @AuthenticationPrincipal String idUsuarioJwt) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        return perfilClienteService.obtenerPerfil(idCliente);
    }

    // PUT /cliente/perfil → editar nombre, apellidos, correo y telefono.
    @PutMapping
    public PerfilClienteResponse editarPerfil(
            @AuthenticationPrincipal String idUsuarioJwt,
            @Valid @RequestBody EditarPerfilClienteRequest request) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        return perfilClienteService.editarPerfil(idCliente, request);
    }

    // POST /cliente/perfil/foto → multipart con la nueva foto. Devuelve {fotoUrl}.
    // Reusamos FotoResponse (definido en admin) porque es identico al que usa el admin.
    @PostMapping(value = "/foto", consumes = "multipart/form-data")
    public FotoResponse subirFoto(
            @AuthenticationPrincipal String idUsuarioJwt,
            @RequestPart("foto") MultipartFile foto) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        String ruta = perfilClienteService.subirFoto(idCliente, foto);
        return new FotoResponse(ruta);
    }

    // POST /cliente/perfil/cambiar-pwd → body {actual, nueva}. 204 si OK; 409 si actual incorrecta.
    @PostMapping("/cambiar-pwd")
    public ResponseEntity<Void> cambiarPassword(
            @AuthenticationPrincipal String idUsuarioJwt,
            @Valid @RequestBody CambiarPasswordClienteRequest request) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        perfilClienteService.cambiarPassword(idCliente, request);
        return ResponseEntity.noContent().build();
    }

    // PUT /cliente/perfil/notificaciones → body {pushActiva: bool}. Activa o desactiva push FCM.
    @PutMapping("/notificaciones")
    public ResponseEntity<Void> configurarPush(
            @AuthenticationPrincipal String idUsuarioJwt,
            @Valid @RequestBody ConfiguracionPushRequest request) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        perfilClienteService.configurarPush(idCliente, request);
        return ResponseEntity.noContent().build();
    }

    // DELETE /cliente/perfil → eliminar la cuenta (RGPD). Body {password} como confirmacion.
    @DeleteMapping
    public ResponseEntity<Void> eliminarCuenta(
            @AuthenticationPrincipal String idUsuarioJwt,
            @Valid @RequestBody EliminarCuentaRequest request) {
        Long idCliente = Long.parseLong(idUsuarioJwt);
        perfilClienteService.eliminarCuenta(idCliente, request);
        return ResponseEntity.noContent().build();
    }
}

// ============================================================================
// PerfilClienteController
// ----------------------------------------------------------------------------
// Controlador delgado del modulo Perfil. Toda la logica reside en PerfilClienteService.
//
// CONTRATO REST:
//
//   GET    /cliente/perfil                       → PerfilClienteResponse
//   PUT    /cliente/perfil                       → PerfilClienteResponse (edicion)
//   POST   /cliente/perfil/foto (multipart)      → FotoResponse {fotoUrl}
//   POST   /cliente/perfil/cambiar-pwd            → 204 (body {actual, nueva})
//   PUT    /cliente/perfil/notificaciones         → 204 (body {pushActiva})
//   DELETE /cliente/perfil                       → 204 (body {password})
//
// SOBRE EL DTO `FotoResponse`:
//   - Lo definimos originalmente para el admin (admin/EmpleadoFotoController y
//     servicios). Lo reusamos aqui porque la estructura es identica: una sola
//     ruta relativa devuelta tras una subida exitosa. Es una decision pragmatica
//     que evita duplicacion.
//
// CONSIDERACIONES DE SEGURIDAD:
//   - El cambio de pwd y la eliminacion de cuenta exigen la pwd actual en el
//     body como ultima barrera contra suplantaciones.
//   - El cambio de pwd revoca todos los refresh tokens existentes; el dispositivo
//     actual ya no podra refrescar y tendra que volver a iniciar sesion.
// ============================================================================
