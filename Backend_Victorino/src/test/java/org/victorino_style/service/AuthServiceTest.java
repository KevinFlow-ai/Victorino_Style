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
import org.victorino_style.dto.auth.AuthResponse;
import org.victorino_style.dto.auth.LoginRequest;
import org.victorino_style.dto.auth.RefreshResponse;
import org.victorino_style.dto.auth.RegistroRequest;
import org.victorino_style.entity.Cliente;
import org.victorino_style.entity.RefreshToken;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.RolUsuario;
import org.victorino_style.exception.CorreoDuplicadoException;
import org.victorino_style.exception.CredencialesInvalidasException;
import org.victorino_style.exception.TokenInvalidoException;
import org.victorino_style.mapper.UsuarioMapper;
import org.victorino_style.repository.ClienteRepository;
import org.victorino_style.repository.RefreshTokenRepository;
import org.victorino_style.repository.UsuarioRepository;
import org.victorino_style.security.JwtService;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

// Tests unitarios de AuthService con Mockito.
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock private UsuarioRepository usuarioRepository;
    @Mock private ClienteRepository clienteRepository;
    @Mock private RefreshTokenRepository refreshTokenRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtService jwtService;
    @Mock private UsuarioMapper usuarioMapper;

    @InjectMocks
    private AuthService authService;

    private Usuario usuarioFalso;

    @BeforeEach
    void preparar() {
        usuarioFalso = new Usuario();
        usuarioFalso.setId(7L);
        usuarioFalso.setCorreoUsuario("ana@victorino.es");
        usuarioFalso.setContrasenaUsuario("$2a$10$hashbcryptfake");
        usuarioFalso.setRolUsuario(RolUsuario.CLIENTE);
    }

    // ---------- registro ----------

    @Test
    @DisplayName("registro: correo duplicado lanza CorreoDuplicadoException")
    void registroCorreoDuplicado() {
        when(usuarioRepository.existsByCorreoUsuario("ana@victorino.es")).thenReturn(true);

        RegistroRequest dto = new RegistroRequest(
                "Ana", "García", null, "ana@victorino.es", "Abcdefg1");

        assertThatThrownBy(() -> authService.registrarCliente(dto))
                .isInstanceOf(CorreoDuplicadoException.class);

        verify(usuarioRepository, never()).save(any());
        verify(clienteRepository, never()).save(any());
    }

    @Test
    @DisplayName("registro ok: persiste usuario, cliente y refresh, devuelve tokens")
    void registroOk() {
        when(usuarioRepository.existsByCorreoUsuario(anyString())).thenReturn(false);
        when(passwordEncoder.encode("Abcdefg1")).thenReturn("$2a$10$hashfake");
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(inv -> {
            Usuario u = inv.getArgument(0);
            u.setId(7L);
            return u;
        });
        when(jwtService.generarAccessToken(any())).thenReturn("access-jwt");
        when(jwtService.generarRefreshTokenOpaco()).thenReturn("refresh-plano");
        when(jwtService.hashearRefreshToken("refresh-plano")).thenReturn("hash64");
        when(jwtService.calcularCaducidadRefresh()).thenReturn(Instant.now().plusSeconds(3600));
        when(usuarioMapper.aAuthResponse(any(), any(), any())).thenReturn(
                new AuthResponse("access-jwt", "refresh-plano", RolUsuario.CLIENTE, 7L, "Ana García", null));

        RegistroRequest dto = new RegistroRequest(
                "Ana", "García", "600111222", "ana@victorino.es", "Abcdefg1");

        AuthResponse resp = authService.registrarCliente(dto);

        assertThat(resp.accessToken()).isEqualTo("access-jwt");
        assertThat(resp.refreshToken()).isEqualTo("refresh-plano");
        assertThat(resp.rol()).isEqualTo(RolUsuario.CLIENTE);
        verify(clienteRepository).save(any(Cliente.class));
        verify(refreshTokenRepository).save(any(RefreshToken.class));
    }

    // ---------- login ----------

    @Test
    @DisplayName("login: correo no existe → CredencialesInvalidasException")
    void loginCorreoNoExiste() {
        when(usuarioRepository.findByCorreoUsuarioAndFechaEliminacionUsuarioIsNull("x@y.es"))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.iniciarSesion(new LoginRequest("x@y.es", "Abcdefg1")))
                .isInstanceOf(CredencialesInvalidasException.class);
    }

    @Test
    @DisplayName("login: pwd incorrecta → CredencialesInvalidasException")
    void loginPwdIncorrecta() {
        when(usuarioRepository.findByCorreoUsuarioAndFechaEliminacionUsuarioIsNull("ana@victorino.es"))
                .thenReturn(Optional.of(usuarioFalso));
        when(passwordEncoder.matches("malo", usuarioFalso.getContrasenaUsuario())).thenReturn(false);

        assertThatThrownBy(() ->
                authService.iniciarSesion(new LoginRequest("ana@victorino.es", "malo")))
                .isInstanceOf(CredencialesInvalidasException.class);

        verify(refreshTokenRepository, never()).save(any());
    }

    @Test
    @DisplayName("login ok: devuelve tokens y persiste hash del refresh")
    void loginOk() {
        when(usuarioRepository.findByCorreoUsuarioAndFechaEliminacionUsuarioIsNull("ana@victorino.es"))
                .thenReturn(Optional.of(usuarioFalso));
        when(passwordEncoder.matches("Abcdefg1", usuarioFalso.getContrasenaUsuario())).thenReturn(true);
        when(jwtService.generarAccessToken(usuarioFalso)).thenReturn("access");
        when(jwtService.generarRefreshTokenOpaco()).thenReturn("refresh");
        when(jwtService.hashearRefreshToken("refresh")).thenReturn("hash64");
        when(jwtService.calcularCaducidadRefresh()).thenReturn(Instant.now().plusSeconds(60));
        when(usuarioMapper.aAuthResponse(usuarioFalso, "access", "refresh"))
                .thenReturn(new AuthResponse("access", "refresh", RolUsuario.CLIENTE, 7L, "Ana", null));

        AuthResponse resp = authService.iniciarSesion(new LoginRequest("ana@victorino.es", "Abcdefg1"));

        assertThat(resp.accessToken()).isEqualTo("access");
        ArgumentCaptor<RefreshToken> captor = ArgumentCaptor.forClass(RefreshToken.class);
        verify(refreshTokenRepository).save(captor.capture());
        assertThat(captor.getValue().getHashRefreshToken()).isEqualTo("hash64");
        assertThat(captor.getValue().getRevocadoRefreshToken()).isFalse();
    }

    // ---------- refresh ----------

    @Test
    @DisplayName("refresh: token revocado/inexistente lanza TokenInvalidoException")
    void refreshTokenInexistente() {
        when(jwtService.hashearRefreshToken("rf")).thenReturn("hash");
        when(refreshTokenRepository.findByHashRefreshTokenAndRevocadoRefreshTokenFalse("hash"))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.refrescar("rf"))
                .isInstanceOf(TokenInvalidoException.class);
    }

    @Test
    @DisplayName("refresh: caducado lanza TokenInvalidoException")
    void refreshCaducado() {
        RefreshToken rt = new RefreshToken();
        rt.setIdUsuario(usuarioFalso);
        rt.setRevocadoRefreshToken(false);
        rt.setFechaCaducidadRefreshToken(Instant.now().minusSeconds(1));

        when(jwtService.hashearRefreshToken("rf")).thenReturn("hash");
        when(refreshTokenRepository.findByHashRefreshTokenAndRevocadoRefreshTokenFalse("hash"))
                .thenReturn(Optional.of(rt));

        assertThatThrownBy(() -> authService.refrescar("rf"))
                .isInstanceOf(TokenInvalidoException.class);
    }

    @Test
    @DisplayName("refresh ok: devuelve nuevo access manteniendo el refresh")
    void refreshOk() {
        RefreshToken rt = new RefreshToken();
        rt.setIdUsuario(usuarioFalso);
        rt.setRevocadoRefreshToken(false);
        rt.setFechaCaducidadRefreshToken(Instant.now().plusSeconds(3600));

        when(jwtService.hashearRefreshToken("rf")).thenReturn("hash");
        when(refreshTokenRepository.findByHashRefreshTokenAndRevocadoRefreshTokenFalse("hash"))
                .thenReturn(Optional.of(rt));
        when(jwtService.generarAccessToken(usuarioFalso)).thenReturn("new-access");

        RefreshResponse resp = authService.refrescar("rf");

        assertThat(resp.accessToken()).isEqualTo("new-access");
    }

    // ---------- logout ----------

    @Test
    @DisplayName("logout: marca el refresh como revocado")
    void logoutMarcaRevocado() {
        RefreshToken rt = new RefreshToken();
        rt.setIdUsuario(usuarioFalso);
        rt.setRevocadoRefreshToken(false);

        when(jwtService.hashearRefreshToken("rf")).thenReturn("hash");
        when(refreshTokenRepository.findByHashRefreshTokenAndRevocadoRefreshTokenFalse("hash"))
                .thenReturn(Optional.of(rt));

        authService.cerrarSesion("rf");

        assertThat(rt.getRevocadoRefreshToken()).isTrue();
        verify(refreshTokenRepository, times(1)).save(rt);
    }

    @Test
    @DisplayName("logout idempotente: si el refresh no existe, no truena")
    void logoutIdempotente() {
        when(jwtService.hashearRefreshToken("rf")).thenReturn("hash");
        when(refreshTokenRepository.findByHashRefreshTokenAndRevocadoRefreshTokenFalse("hash"))
                .thenReturn(Optional.empty());

        authService.cerrarSesion("rf");

        verify(refreshTokenRepository, never()).save(any());
    }
}
