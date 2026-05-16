package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.victorino_style.dto.cliente.CambiarPasswordClienteRequest;
import org.victorino_style.dto.cliente.ConfiguracionPushRequest;
import org.victorino_style.dto.cliente.EditarPerfilClienteRequest;
import org.victorino_style.dto.cliente.EliminarCuentaRequest;
import org.victorino_style.dto.cliente.PerfilClienteResponse;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Cliente;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.exception.CorreoDuplicadoException;
import org.victorino_style.exception.PasswordIncorrectaException;
import org.victorino_style.exception.RecursoNoEncontradoException;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.repository.ClienteRepository;
import org.victorino_style.repository.DeviceTokenFcmRepository;
import org.victorino_style.repository.RefreshTokenRepository;
import org.victorino_style.repository.UsuarioRepository;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

// Servicio que gestiona toda la pestaña "Perfil" del cliente final:
//   - Leer perfil propio.
//   - Editar nombre, apellidos, correo y telefono.
//   - Cambiar foto.
//   - Cambiar contraseña (con verificacion de la actual).
//   - Activar/desactivar push.
//   - Eliminar la cuenta con anonimizacion RGPD + cancelacion de citas futuras.
@Slf4j
@Service
@RequiredArgsConstructor
public class PerfilClienteService {

    private final ClienteRepository clienteRepository;
    private final UsuarioRepository usuarioRepository;
    private final CitaRepository citaRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final DeviceTokenFcmRepository deviceTokenFcmRepository;
    private final PasswordEncoder passwordEncoder;
    private final FileStorageService fileStorageService;
    private final NotificacionService notificacionService;
    private final AuditoriaService auditoriaService;

    // Auto-inyeccion LAZY para forzar el paso por el proxy CGLIB cuando llamamos a
    // metodos @Transactional(REQUIRES_NEW) dentro de un bucle. Sin esto, las llamadas
    // "this.metodo()" bypasean Spring y la anotacion transaccional se ignora.
    @Lazy
    @Autowired
    private PerfilClienteService self;

    // ============================================================
    //  LECTURA DEL PERFIL
    // ============================================================
    @Transactional(readOnly = true)
    public PerfilClienteResponse obtenerPerfil(Long idCliente) {
        Cliente cliente = cargarCliente(idCliente);
        return aRespuesta(cliente);
    }

    // ============================================================
    //  EDITAR PERFIL (nombre, apellidos, correo, telefono)
    // ============================================================
    @Transactional
    public PerfilClienteResponse editarPerfil(Long idCliente, EditarPerfilClienteRequest dto) {
        Cliente cliente = cargarCliente(idCliente);
        Usuario usuario = cliente.getUsuario();

        String correoNuevo = dto.correo().trim().toLowerCase(Locale.ROOT);
        // Si el correo cambia, comprobamos que no este en uso por otro usuario.
        if (!correoNuevo.equals(usuario.getCorreoUsuario())
                && usuarioRepository.existsByCorreoUsuario(correoNuevo)) {
            throw new CorreoDuplicadoException(correoNuevo);
        }

        cliente.setNombreCliente(dto.nombre().trim());
        cliente.setApellidosCliente(dto.apellidos().trim());
        cliente.setTelefonoCliente(
                dto.telefono() == null || dto.telefono().isBlank() ? null : dto.telefono().trim());
        usuario.setCorreoUsuario(correoNuevo);
        usuario.setFechaModificacionUsuario(Instant.now());

        clienteRepository.save(cliente);
        usuarioRepository.save(usuario);

        auditoriaService.registrar("EDITAR_PERFIL_CLIENTE", "CLIENTE", idCliente,
                "Cliente actualizo sus datos personales");

        log.info("Perfil de cliente {} actualizado", idCliente);
        return aRespuesta(cliente);
    }

    // ============================================================
    //  SUBIR FOTO
    // ============================================================
    @Transactional
    public String subirFoto(Long idCliente, MultipartFile foto) {
        Cliente cliente = cargarCliente(idCliente);
        // El servicio compartido se encarga de validar y devolver la URL relativa.
        String rutaNueva = fileStorageService.reemplazar(foto, "cliente", cliente.getFotoCliente());
        cliente.setFotoCliente(rutaNueva);
        clienteRepository.save(cliente);
        log.info("Cliente {} subio nueva foto: {}", idCliente, rutaNueva);
        return rutaNueva;
    }

    // ============================================================
    //  CAMBIAR CONTRASEÑA
    // ============================================================
    @Transactional
    public void cambiarPassword(Long idCliente, CambiarPasswordClienteRequest dto) {
        Cliente cliente = cargarCliente(idCliente);
        Usuario usuario = cliente.getUsuario();

        // Verificar la contraseña actual.
        if (!passwordEncoder.matches(dto.actual(), usuario.getContrasenaUsuario())) {
            log.info("Cambio de pwd fallido (actual incorrecta) para cliente {}", idCliente);
            throw new PasswordIncorrectaException();
        }

        // Hashear la nueva y guardar.
        usuario.setContrasenaUsuario(passwordEncoder.encode(dto.nueva()));
        usuario.setFechaModificacionUsuario(Instant.now());
        usuarioRepository.save(usuario);

        // Revocar todos los refresh tokens activos: cierre de sesion en otros dispositivos.
        int revocados = refreshTokenRepository.revocarTodosPorUsuario(usuario.getId());

        // Notificar al usuario que su contraseña se cambio.
        notificacionService.crearNotificacion(
                usuario, null, TipoNotificacion.CONTRASENA_ACTUALIZADA,
                "Contraseña actualizada",
                "Tu contraseña ha sido actualizada correctamente. Si no fuiste tu, contacta con la peluqueria.");

        auditoriaService.registrar("CAMBIAR_PWD_CLIENTE", "USUARIO", usuario.getId(),
                "Cliente cambio pwd. Refresh tokens revocados: " + revocados);

        log.info("Cliente {} cambio contraseña. Refresh tokens revocados: {}", idCliente, revocados);
    }

    // ============================================================
    //  CONFIGURAR PUSH (activar/desactivar)
    // ============================================================
    @Transactional
    public void configurarPush(Long idCliente, ConfiguracionPushRequest dto) {
        Cliente cliente = cargarCliente(idCliente);
        cliente.setPushActivaCliente(dto.pushActiva());
        clienteRepository.save(cliente);
        log.info("Cliente {} configuro push: {}", idCliente, dto.pushActiva());
    }

    // ============================================================
    //  ELIMINAR CUENTA (RGPD: soft-delete con anonimizacion)
    // ============================================================
    @Transactional
    public void eliminarCuenta(Long idCliente, EliminarCuentaRequest dto) {
        Cliente cliente = cargarCliente(idCliente);
        Usuario usuario = cliente.getUsuario();

        // 1) Verificar la contraseña actual como ultima barrera contra borrados accidentales.
        if (!passwordEncoder.matches(dto.password(), usuario.getContrasenaUsuario())) {
            log.info("Intento de eliminacion fallido (pwd incorrecta) para cliente {}", idCliente);
            throw new PasswordIncorrectaException();
        }

        // 2) Cancelar todas las citas futuras CONFIRMADAS, una por una en REQUIRES_NEW.
        //    Asi una cancelacion fallida no aborta el resto.
        List<Cita> futuras = citaRepository.findFuturasConfirmadasCliente(
                idCliente, LocalDate.now(), LocalTime.now());

        int canceladas = 0;
        int omitidas = 0;
        for (Cita c : futuras) {
            try {
                self.cancelarCitaFutura(c.getId());
                canceladas++;
            } catch (Exception ex) {
                log.warn("No se pudo cancelar cita {} al eliminar cuenta: {}", c.getId(), ex.getMessage());
                omitidas++;
            }
        }

        // 3) Anonimizar Cliente (datos personales).
        String fotoAntigua = cliente.getFotoCliente();
        cliente.setNombreCliente("Cliente eliminado");
        cliente.setApellidosCliente("");
        cliente.setTelefonoCliente(null);
        cliente.setFotoCliente(null);
        cliente.setPushActivaCliente(false);
        clienteRepository.save(cliente);

        // 4) Anonimizar Usuario y marcar soft-delete.
        Instant ahora = Instant.now();
        String correoAnonimo = "eliminado-" + usuario.getId() + "@victorino.es";
        usuario.setCorreoUsuario(correoAnonimo);
        usuario.setContrasenaUsuario(passwordEncoder.encode(UUID.randomUUID().toString()));
        usuario.setFechaEliminacionUsuario(ahora);
        usuario.setFechaModificacionUsuario(ahora);
        usuarioRepository.save(usuario);

        // 5) Revocar todos los refresh tokens y borrar device tokens FCM.
        refreshTokenRepository.revocarTodosPorUsuario(usuario.getId());
        deviceTokenFcmRepository.deleteByIdUsuario_Id(usuario.getId());

        // 6) Borrar la foto antigua del disco (best effort).
        if (fotoAntigua != null) {
            fileStorageService.borrarSiExiste(fotoAntigua);
        }

        auditoriaService.registrar("ELIMINAR_CUENTA", "CLIENTE", idCliente,
                "Cliente elimino su cuenta. Citas futuras canceladas: " + canceladas
                        + ", omitidas: " + omitidas);

        log.info("Cuenta de cliente {} eliminada. Canceladas: {}, omitidas: {}",
                idCliente, canceladas, omitidas);
    }

    // Cancela UNA cita futura del cliente que esta eliminando su cuenta.
    // Se ejecuta en su propia transaccion para que un fallo aislado no aborte
    // todo el proceso. Es publico para que Spring envuelva el metodo con el proxy.
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void cancelarCitaFutura(Long idCita) {
        Cita cita = citaRepository.findByIdParaActualizar(idCita)
                .orElseThrow(() -> new IllegalStateException("Cita ya inexistente: " + idCita));
        if (cita.getEstadoCita() != EstadoCita.CONFIRMADA) {
            throw new IllegalStateException("Cita " + idCita + " ya no es CONFIRMADA");
        }
        cita.setEstadoCita(EstadoCita.CANCELADA_PELUQUERIA);
        cita.setFechaModificacionCita(Instant.now());
        citaRepository.save(cita);

        // Notificar al empleado afectado (reusamos CANCELACION_CLIENTE con texto personalizado).
        if (cita.getIdEmpleado() != null && cita.getIdEmpleado().getUsuario() != null) {
            notificacionService.crearNotificacion(
                    cita.getIdEmpleado().getUsuario(), cita, TipoNotificacion.CANCELACION_CLIENTE,
                    "Cita cancelada (cliente eliminado)",
                    "Una cita del " + cita.getFechaCita() + " a las "
                            + cita.getHoraInicioCita()
                            + " ha sido cancelada porque el cliente ha eliminado su cuenta.");
        }
    }

    // ============================================================
    //  HELPERS
    // ============================================================

    private Cliente cargarCliente(Long idCliente) {
        return clienteRepository.findById(idCliente)
                .orElseThrow(() -> new RecursoNoEncontradoException("Cliente no encontrado con id " + idCliente));
    }

    private PerfilClienteResponse aRespuesta(Cliente c) {
        Usuario u = c.getUsuario();
        return new PerfilClienteResponse(
                c.getId(),
                c.getNombreCliente(),
                c.getApellidosCliente(),
                u.getCorreoUsuario(),
                c.getTelefonoCliente(),
                c.getFotoCliente(),
                Boolean.TRUE.equals(c.getPushActivaCliente())
        );
    }
}

// ============================================================================
// PerfilClienteService
// ----------------------------------------------------------------------------
// Servicio del modulo Perfil del cliente final autenticado.
//
// FLUJOS PRINCIPALES:
//
//   GET /cliente/perfil
//     └─ obtenerPerfil(idCliente)
//
//   PUT /cliente/perfil          (datos personales)
//     └─ editarPerfil(idCliente, dto)
//         ├─ valida unicidad de correo (CorreoDuplicadoException 409)
//         └─ actualiza Cliente + Usuario y audita
//
//   POST /cliente/perfil/foto     (multipart)
//     └─ subirFoto(idCliente, MultipartFile)
//         └─ FileStorageService.reemplazar(...) -> /uploads/cliente/uuid.jpg
//
//   POST /cliente/perfil/cambiar-pwd
//     └─ cambiarPassword(idCliente, dto)
//         ├─ valida pwd actual (PasswordIncorrectaException 409)
//         ├─ hashea la nueva
//         ├─ revoca todos los refresh tokens
//         ├─ notifica CONTRASENA_ACTUALIZADA
//         └─ audita "CAMBIAR_PWD_CLIENTE"
//
//   PUT /cliente/perfil/notificaciones
//     └─ configurarPush(idCliente, {pushActiva: bool})
//         └─ actualiza cliente.push_activa_cliente
//
//   DELETE /cliente/perfil       (eliminar cuenta)
//     └─ eliminarCuenta(idCliente, dto)
//         ├─ valida pwd (PasswordIncorrectaException 409)
//         ├─ cancela citas futuras CONFIRMADAS (REQUIRES_NEW, una por una)
//         │     └─ notifica CANCELACION_CLIENTE al empleado de cada cita
//         ├─ anonimiza Cliente (nombre/apellidos/telefono/foto)
//         ├─ anonimiza Usuario (correo eliminado-{id}@victorino.es, pwd aleatoria)
//         ├─ marca fechaEliminacionUsuario (soft-delete)
//         ├─ revoca refresh tokens y borra device tokens FCM
//         ├─ borra foto antigua del disco
//         └─ audita "ELIMINAR_CUENTA"
//
// PATRON REQUIRES_NEW + AUTO-INYECCION LAZY:
//   - Para que @Transactional(REQUIRES_NEW) funcione en cancelarCitaFutura(...),
//     debe llamarse via proxy CGLIB. Por eso usamos `self.cancelarCitaFutura(...)`
//     en lugar de `this.cancelarCitaFutura(...)`.
//   - Es el mismo patron que CancelacionMasivaService.
//
// RGPD:
//   - La fila del usuario y del cliente NO se borran fisicamente: se anonimizan.
//   - Asi, las citas historicas siguen apuntando al id pero NO contienen datos
//     personales identificables. Cumple el principio de "minimizacion de datos".
// ============================================================================
