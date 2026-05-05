package org.victorino_style.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.multipart.MultipartFile;
import org.victorino_style.dto.admin.EmpleadoAdminRequest;
import org.victorino_style.dto.admin.EmpleadoAdminResponse;
import org.victorino_style.dto.admin.FotoResponse;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.RolUsuario;
import org.victorino_style.exception.CorreoDuplicadoException;
import org.victorino_style.exception.EmpleadoNoEncontradoException;
import org.victorino_style.exception.FotoObligatoriaException;
import org.victorino_style.mapper.EmpleadoMapper;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.UsuarioRepository;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

// Tests unitarios del servicio EmpleadoService.
// Cubren: alta, edición, baja lógica, listado y subida de foto.
@ExtendWith(MockitoExtension.class)
class EmpleadoServiceTest {

    @Mock private EmpleadoRepository empleadoRepository;
    @Mock private UsuarioRepository usuarioRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private EmpleadoMapper empleadoMapper;
    @Mock private FileStorageService fileStorageService;
    @Mock private AuditoriaService auditoriaService;

    @InjectMocks
    private EmpleadoService empleadoService;

    private Usuario usuarioFalso;
    private Empleado empleadoFalso;

    @BeforeEach
    void preparar() {
        usuarioFalso = new Usuario();
        usuarioFalso.setId(10L);
        usuarioFalso.setCorreoUsuario("vito@victorino.es");
        usuarioFalso.setRolUsuario(RolUsuario.EMPLEADO);

        empleadoFalso = new Empleado();
        empleadoFalso.setId(10L);
        empleadoFalso.setUsuario(usuarioFalso);
        empleadoFalso.setNombreEmpleado("Vito");
        empleadoFalso.setApellidosEmpleado("Corleone");
        empleadoFalso.setFotoEmpleado("/uploads/empleados/old.jpg");
        empleadoFalso.setNoMolestarEmpleado(false);
    }

    // ============================================================
    //  ALTA
    // ============================================================

    @Test
    @DisplayName("crear: correo duplicado lanza CorreoDuplicadoException")
    void crearCorreoDuplicado() {
        when(usuarioRepository.existsByCorreoUsuario("vito@victorino.es")).thenReturn(true);

        EmpleadoAdminRequest dto = new EmpleadoAdminRequest(
                "Vito", "Corleone", "600", "vito@victorino.es", "Abcdefg1");

        assertThatThrownBy(() -> empleadoService.crear(dto))
                .isInstanceOf(CorreoDuplicadoException.class);

        verify(empleadoRepository, never()).save(any());
    }

    @Test
    @DisplayName("crear ok: persiste usuario+empleado, audita y devuelve respuesta")
    void crearOk() {
        when(usuarioRepository.existsByCorreoUsuario(anyString())).thenReturn(false);
        when(passwordEncoder.encode("Abcdefg1")).thenReturn("$2a$10$hash");
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(inv -> {
            Usuario u = inv.getArgument(0);
            u.setId(20L);
            return u;
        });
        when(empleadoRepository.save(any(Empleado.class))).thenAnswer(inv -> inv.getArgument(0));
        when(empleadoMapper.aRespuesta(any(Empleado.class))).thenReturn(
                new EmpleadoAdminResponse(20L, "Marco", "Polo", "marco@v.es",
                        null, "", true, RolUsuario.EMPLEADO, false));

        EmpleadoAdminRequest dto = new EmpleadoAdminRequest(
                "Marco", "Polo", null, "marco@v.es", "Abcdefg1");

        EmpleadoAdminResponse resp = empleadoService.crear(dto);

        assertThat(resp.idEmpleado()).isEqualTo(20L);
        verify(empleadoRepository).save(any(Empleado.class));
        verify(auditoriaService).registrar(eq("CREAR_EMPLEADO"), eq("EMPLEADO"), any(), anyString());
    }

    @Test
    @DisplayName("crear: contraseña vacía lanza IllegalArgumentException")
    void crearSinPassword() {
        when(usuarioRepository.existsByCorreoUsuario(anyString())).thenReturn(false);

        EmpleadoAdminRequest dto = new EmpleadoAdminRequest(
                "Marco", "Polo", null, "marco@v.es", "");

        assertThatThrownBy(() -> empleadoService.crear(dto))
                .isInstanceOf(IllegalArgumentException.class);
    }

    // ============================================================
    //  EDICIÓN
    // ============================================================

    @Test
    @DisplayName("editar: empleado inexistente lanza EmpleadoNoEncontradoException")
    void editarNoExiste() {
        when(empleadoRepository.findActivoById(99L)).thenReturn(Optional.empty());

        EmpleadoAdminRequest dto = new EmpleadoAdminRequest(
                "X", "Y", null, "x@y.es", null);

        assertThatThrownBy(() -> empleadoService.editar(99L, dto))
                .isInstanceOf(EmpleadoNoEncontradoException.class);
    }

    @Test
    @DisplayName("editar ok: cambia nombre y conserva la pwd cuando llega vacía")
    void editarSinCambiarPwd() {
        when(empleadoRepository.findActivoById(10L)).thenReturn(Optional.of(empleadoFalso));
        when(empleadoRepository.save(any(Empleado.class))).thenAnswer(inv -> inv.getArgument(0));
        when(empleadoMapper.aRespuesta(any())).thenReturn(
                new EmpleadoAdminResponse(10L, "Vito", "Mod", "vito@victorino.es",
                        null, "/uploads/empleados/old.jpg", true, RolUsuario.EMPLEADO, false));

        EmpleadoAdminRequest dto = new EmpleadoAdminRequest(
                "Vito", "Mod", null, "vito@victorino.es", null);

        empleadoService.editar(10L, dto);

        // No se debe haber tocado la contraseña.
        verify(passwordEncoder, never()).encode(anyString());
    }

    // ============================================================
    //  BAJA LÓGICA
    // ============================================================

    @Test
    @DisplayName("darBaja: marca fecha_eliminacion_usuario y registra auditoría")
    void darBajaOk() {
        when(empleadoRepository.findActivoById(10L)).thenReturn(Optional.of(empleadoFalso));

        empleadoService.darBaja(10L);

        ArgumentCaptor<Usuario> captor = ArgumentCaptor.forClass(Usuario.class);
        verify(usuarioRepository).save(captor.capture());
        assertThat(captor.getValue().getFechaEliminacionUsuario()).isNotNull();
        verify(auditoriaService).registrar(eq("BAJA_EMPLEADO"), eq("EMPLEADO"), any(), anyString());
    }

    // ============================================================
    //  LISTADO
    // ============================================================

    @Test
    @DisplayName("listar(false): devuelve solo activos")
    void listarSoloActivos() {
        when(empleadoRepository.findAllActivos()).thenReturn(List.of(empleadoFalso));
        when(empleadoMapper.aRespuesta(any())).thenReturn(
                new EmpleadoAdminResponse(10L, "Vito", "Corleone", "vito@victorino.es",
                        null, "/uploads/empleados/old.jpg", true, RolUsuario.EMPLEADO, false));

        List<EmpleadoAdminResponse> lista = empleadoService.listar(false);

        assertThat(lista).hasSize(1);
        verify(empleadoRepository, never()).findAllOrderActivosPrimero();
    }

    @Test
    @DisplayName("listar(true): incluye activos + inactivos")
    void listarConInactivos() {
        when(empleadoRepository.findAllOrderActivosPrimero()).thenReturn(List.of(empleadoFalso));
        when(empleadoMapper.aRespuesta(any())).thenReturn(
                new EmpleadoAdminResponse(10L, "Vito", "Corleone", "vito@victorino.es",
                        null, "/uploads/empleados/old.jpg", true, RolUsuario.EMPLEADO, false));

        List<EmpleadoAdminResponse> lista = empleadoService.listar(true);

        assertThat(lista).hasSize(1);
        verify(empleadoRepository, never()).findAllActivos();
    }

    // ============================================================
    //  FOTO
    // ============================================================

    @Test
    @DisplayName("subirFoto: archivo vacío lanza FotoObligatoriaException")
    void subirFotoVacia() {
        MultipartFile vacio = mockMultipart(true);

        assertThatThrownBy(() -> empleadoService.subirFoto(10L, vacio))
                .isInstanceOf(FotoObligatoriaException.class);

        verify(fileStorageService, never()).reemplazar(any(), anyString(), anyString());
    }

    @Test
    @DisplayName("subirFoto ok: reemplaza foto antigua y actualiza la entidad")
    void subirFotoOk() {
        MultipartFile archivo = mockMultipart(false);
        when(empleadoRepository.findActivoById(10L)).thenReturn(Optional.of(empleadoFalso));
        when(fileStorageService.reemplazar(archivo, "empleados", "/uploads/empleados/old.jpg"))
                .thenReturn("/uploads/empleados/nueva.jpg");

        FotoResponse resp = empleadoService.subirFoto(10L, archivo);

        assertThat(resp.fotoUrl()).isEqualTo("/uploads/empleados/nueva.jpg");
        assertThat(empleadoFalso.getFotoEmpleado()).isEqualTo("/uploads/empleados/nueva.jpg");
        verify(empleadoRepository).save(empleadoFalso);
    }

    // Helper: crea un MultipartFile mock vacío o no.
    private MultipartFile mockMultipart(boolean vacio) {
        return new org.springframework.mock.web.MockMultipartFile(
                "archivo", "foto.jpg", "image/jpeg", vacio ? new byte[0] : "datos".getBytes());
    }

    // Importa eq() y any() para Mockito. Se importan estáticos al final para mantener la sección
    // de imports principal organizada por origen.
    private static <T> T eq(T value) { return org.mockito.ArgumentMatchers.eq(value); }
}
