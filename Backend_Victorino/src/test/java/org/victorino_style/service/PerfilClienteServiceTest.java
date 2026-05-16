package org.victorino_style.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.multipart.MultipartFile;
import org.victorino_style.dto.cliente.CambiarPasswordClienteRequest;
import org.victorino_style.dto.cliente.ConfiguracionPushRequest;
import org.victorino_style.dto.cliente.EditarPerfilClienteRequest;
import org.victorino_style.dto.cliente.EliminarCuentaRequest;
import org.victorino_style.dto.cliente.PerfilClienteResponse;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Cliente;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.entity.enums.RolUsuario;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.exception.CorreoDuplicadoException;
import org.victorino_style.exception.PasswordIncorrectaException;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.repository.ClienteRepository;
import org.victorino_style.repository.DeviceTokenFcmRepository;
import org.victorino_style.repository.RefreshTokenRepository;
import org.victorino_style.repository.UsuarioRepository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

// Tests unitarios del servicio PerfilClienteService. Cubre:
//   - obtenerPerfil
//   - editarPerfil (correo duplicado vs ok)
//   - cambiarPassword (pwd incorrecta vs ok, revoca tokens, notifica)
//   - configurarPush
//   - eliminarCuenta (pwd incorrecta vs ok, anonimiza, cancela citas futuras)
@ExtendWith(MockitoExtension.class)
class PerfilClienteServiceTest {

    @Mock private ClienteRepository clienteRepository;
    @Mock private UsuarioRepository usuarioRepository;
    @Mock private CitaRepository citaRepository;
    @Mock private RefreshTokenRepository refreshTokenRepository;
    @Mock private DeviceTokenFcmRepository deviceTokenFcmRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private FileStorageService fileStorageService;
    @Mock private NotificacionService notificacionService;
    @Mock private AuditoriaService auditoriaService;

    @InjectMocks
    private PerfilClienteService perfilClienteService;

    private Cliente cliente;
    private Usuario usuario;
    private Empleado empleado;

    @BeforeEach
    void preparar() {
        usuario = new Usuario();
        usuario.setId(100L);
        usuario.setCorreoUsuario("cli@x.com");
        usuario.setContrasenaUsuario("$2a$10$hashAntiguo");
        usuario.setRolUsuario(RolUsuario.CLIENTE);

        cliente = new Cliente();
        cliente.setId(100L);
        cliente.setUsuario(usuario);
        cliente.setNombreCliente("Marco");
        cliente.setApellidosCliente("Polo");
        cliente.setTelefonoCliente("600111222");
        cliente.setFotoCliente("/uploads/cliente/antigua.jpg");
        cliente.setPushActivaCliente(true);

        Usuario uEmp = new Usuario();
        uEmp.setId(7L);
        uEmp.setRolUsuario(RolUsuario.EMPLEADO);
        empleado = new Empleado();
        empleado.setId(7L);
        empleado.setUsuario(uEmp);
        empleado.setNombreEmpleado("Vito");

        // Inyectar el propio servicio como "self" para que cancelarCitaFutura via proxy funcione en tests.
        ReflectionTestUtils.setField(perfilClienteService, "self", perfilClienteService);
    }

    // ============================================================
    //  OBTENER PERFIL
    // ============================================================
    @Test
    @DisplayName("obtenerPerfil ok: devuelve datos del cliente")
    void obtenerOk() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));

        PerfilClienteResponse resp = perfilClienteService.obtenerPerfil(100L);

        assertThat(resp.idCliente()).isEqualTo(100L);
        assertThat(resp.nombre()).isEqualTo("Marco");
        assertThat(resp.correo()).isEqualTo("cli@x.com");
        assertThat(resp.pushActiva()).isTrue();
    }

    // ============================================================
    //  EDITAR PERFIL
    // ============================================================
    @Test
    @DisplayName("editarPerfil: correo nuevo ya en uso → 409 CorreoDuplicado")
    void editarCorreoDuplicado() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(usuarioRepository.existsByCorreoUsuario("nuevo@x.com")).thenReturn(true);

        EditarPerfilClienteRequest dto = new EditarPerfilClienteRequest(
                "Marco", "Polo", "nuevo@x.com", "600111222");

        assertThatThrownBy(() -> perfilClienteService.editarPerfil(100L, dto))
                .isInstanceOf(CorreoDuplicadoException.class);
        verify(usuarioRepository, never()).save(any());
    }

    @Test
    @DisplayName("editarPerfil ok: actualiza datos y audita")
    void editarOk() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(usuarioRepository.existsByCorreoUsuario(anyString())).thenReturn(false);
        when(clienteRepository.save(any(Cliente.class))).thenAnswer(inv -> inv.getArgument(0));
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(inv -> inv.getArgument(0));

        EditarPerfilClienteRequest dto = new EditarPerfilClienteRequest(
                "Marco", "Polo", "marco@nuevo.com", "+34600999888");

        PerfilClienteResponse resp = perfilClienteService.editarPerfil(100L, dto);

        assertThat(resp.correo()).isEqualTo("marco@nuevo.com");
        assertThat(resp.telefono()).isEqualTo("+34600999888");
        verify(auditoriaService).registrar(eq("EDITAR_PERFIL_CLIENTE"), eq("CLIENTE"), eq(100L), anyString());
    }

    // ============================================================
    //  SUBIR FOTO
    // ============================================================
    @Test
    @DisplayName("subirFoto ok: actualiza la ruta en BD y devuelve la nueva")
    void subirFotoOk() {
        MultipartFile foto = org.mockito.Mockito.mock(MultipartFile.class);
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(fileStorageService.reemplazar(foto, "cliente", "/uploads/cliente/antigua.jpg"))
                .thenReturn("/uploads/cliente/nueva.jpg");

        String ruta = perfilClienteService.subirFoto(100L, foto);

        assertThat(ruta).isEqualTo("/uploads/cliente/nueva.jpg");
        assertThat(cliente.getFotoCliente()).isEqualTo("/uploads/cliente/nueva.jpg");
    }

    // ============================================================
    //  CAMBIAR CONTRASEÑA
    // ============================================================
    @Test
    @DisplayName("cambiarPassword: pwd actual incorrecta → 409 PasswordIncorrecta")
    void cambiarPwdIncorrecta() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(passwordEncoder.matches("Mala1234", "$2a$10$hashAntiguo")).thenReturn(false);

        CambiarPasswordClienteRequest dto = new CambiarPasswordClienteRequest("Mala1234", "Nueva1234");

        assertThatThrownBy(() -> perfilClienteService.cambiarPassword(100L, dto))
                .isInstanceOf(PasswordIncorrectaException.class);
        verify(usuarioRepository, never()).save(any());
    }

    @Test
    @DisplayName("cambiarPassword ok: hashea, revoca tokens, notifica, audita")
    void cambiarPwdOk() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(passwordEncoder.matches("ActualOK1", "$2a$10$hashAntiguo")).thenReturn(true);
        when(passwordEncoder.encode("Nueva1234")).thenReturn("$2a$10$hashNuevo");
        when(refreshTokenRepository.revocarTodosPorUsuario(100L)).thenReturn(2);

        CambiarPasswordClienteRequest dto = new CambiarPasswordClienteRequest("ActualOK1", "Nueva1234");

        perfilClienteService.cambiarPassword(100L, dto);

        assertThat(usuario.getContrasenaUsuario()).isEqualTo("$2a$10$hashNuevo");
        verify(refreshTokenRepository).revocarTodosPorUsuario(100L);
        verify(notificacionService).crearNotificacion(eq(usuario), eq(null),
                eq(TipoNotificacion.CONTRASENA_ACTUALIZADA), anyString(), anyString());
        verify(auditoriaService).registrar(eq("CAMBIAR_PWD_CLIENTE"), eq("USUARIO"), eq(100L), anyString());
    }

    // ============================================================
    //  CONFIGURAR PUSH
    // ============================================================
    @Test
    @DisplayName("configurarPush: actualiza el flag en BD")
    void configurarPush() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(clienteRepository.save(any(Cliente.class))).thenAnswer(inv -> inv.getArgument(0));

        perfilClienteService.configurarPush(100L, new ConfiguracionPushRequest(false));

        assertThat(cliente.getPushActivaCliente()).isFalse();
    }

    // ============================================================
    //  ELIMINAR CUENTA
    // ============================================================
    @Test
    @DisplayName("eliminarCuenta: pwd incorrecta → 409 PasswordIncorrecta, sin cambios")
    void eliminarPwdIncorrecta() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(passwordEncoder.matches("Mala1234", "$2a$10$hashAntiguo")).thenReturn(false);

        assertThatThrownBy(() -> perfilClienteService.eliminarCuenta(100L,
                new EliminarCuentaRequest("Mala1234")))
                .isInstanceOf(PasswordIncorrectaException.class);
        verify(clienteRepository, never()).save(any());
        verify(usuarioRepository, never()).save(any());
    }

    @Test
    @DisplayName("eliminarCuenta ok: anonimiza, cancela futuras, revoca tokens, audita")
    void eliminarCuentaOk() {
        // Una cita futura CONFIRMADA del cliente que se debe cancelar.
        Cita futura = new Cita();
        futura.setId(500L);
        futura.setIdCliente(cliente);
        futura.setIdEmpleado(empleado);
        futura.setFechaCita(LocalDate.now().plusDays(3));
        futura.setHoraInicioCita(LocalTime.of(10, 0));
        futura.setHoraFinCita(LocalTime.of(10, 30));
        futura.setEstadoCita(EstadoCita.CONFIRMADA);

        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(passwordEncoder.matches("OK1Pwd1234", "$2a$10$hashAntiguo")).thenReturn(true);
        when(citaRepository.findFuturasConfirmadasCliente(eq(100L), any(LocalDate.class), any(LocalTime.class)))
                .thenReturn(List.of(futura));
        when(citaRepository.findByIdParaActualizar(500L)).thenReturn(Optional.of(futura));
        when(citaRepository.save(any(Cita.class))).thenAnswer(inv -> inv.getArgument(0));
        when(clienteRepository.save(any(Cliente.class))).thenAnswer(inv -> inv.getArgument(0));
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(inv -> inv.getArgument(0));
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$10$random");

        perfilClienteService.eliminarCuenta(100L, new EliminarCuentaRequest("OK1Pwd1234"));

        // Cita futura cancelada por la peluqueria.
        assertThat(futura.getEstadoCita()).isEqualTo(EstadoCita.CANCELADA_PELUQUERIA);

        // Cliente anonimizado.
        assertThat(cliente.getNombreCliente()).isEqualTo("Cliente eliminado");
        assertThat(cliente.getApellidosCliente()).isEmpty();
        assertThat(cliente.getTelefonoCliente()).isNull();
        assertThat(cliente.getFotoCliente()).isNull();
        assertThat(cliente.getPushActivaCliente()).isFalse();

        // Usuario anonimizado y marcado eliminado.
        assertThat(usuario.getCorreoUsuario()).isEqualTo("eliminado-100@victorino.es");
        assertThat(usuario.getFechaEliminacionUsuario()).isNotNull();

        // Tokens revocados y device tokens borrados.
        verify(refreshTokenRepository).revocarTodosPorUsuario(100L);
        verify(deviceTokenFcmRepository).deleteByIdUsuario_Id(100L);

        // Notificacion al empleado por la cancelacion masiva.
        verify(notificacionService).crearNotificacion(
                eq(empleado.getUsuario()), eq(futura),
                eq(TipoNotificacion.CANCELACION_CLIENTE), anyString(), anyString());

        // Auditoria.
        verify(auditoriaService).registrar(eq("ELIMINAR_CUENTA"), eq("CLIENTE"), eq(100L), anyString());

        // Foto antigua borrada del disco (best effort).
        verify(fileStorageService).borrarSiExiste("/uploads/cliente/antigua.jpg");
    }
}
