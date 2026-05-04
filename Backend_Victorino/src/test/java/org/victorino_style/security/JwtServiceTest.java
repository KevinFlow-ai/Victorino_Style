package org.victorino_style.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.victorino_style.config.JwtConfig;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.RolUsuario;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

// Tests unitarios puros (sin Spring) de JwtService.
class JwtServiceTest {

    private JwtService jwtService;

    @BeforeEach
    void preparar() {
        // Clave de 256 bits en base64 generada para tests (NO se reutiliza en producción).
        JwtConfig cfg = new JwtConfig();
        cfg.setSecret("Y2xhdmVfZGVfMjU2X2JpdHNfcGFyYV90ZXN0c191bml0YXJpb3NfdmljdG9yaW5v");
        cfg.setAccessTtl(Duration.ofMinutes(15));
        cfg.setRefreshTtl(Duration.ofDays(7));
        cfg.setIssuer("victorino-test");
        jwtService = new JwtService(cfg);
    }

    private Usuario usuarioFalso() {
        Usuario u = new Usuario();
        u.setId(42L);
        u.setCorreoUsuario("test@victorino.es");
        u.setRolUsuario(RolUsuario.CLIENTE);
        return u;
    }

    @Test
    @DisplayName("Genera y valida un access token correctamente")
    void generaYValidaAccessToken() {
        String token = jwtService.generarAccessToken(usuarioFalso());

        Claims claims = jwtService.validarAccessToken(token);

        assertThat(claims.getSubject()).isEqualTo("42");
        assertThat(claims.get("rol", String.class)).isEqualTo("CLIENTE");
        assertThat(claims.get("correo", String.class)).isEqualTo("test@victorino.es");
        assertThat(claims.getIssuer()).isEqualTo("victorino-test");
    }

    @Test
    @DisplayName("Un token con firma manipulada lanza JwtException")
    void tokenManipuladoLanzaExcepcion() {
        String token = jwtService.generarAccessToken(usuarioFalso());
        // Cambiamos un carácter de la firma.
        String manipulado = token.substring(0, token.length() - 1) +
                (token.charAt(token.length() - 1) == 'a' ? 'b' : 'a');

        assertThatThrownBy(() -> jwtService.validarAccessToken(manipulado))
                .isInstanceOf(JwtException.class);
    }

    @Test
    @DisplayName("Token caducado: estaCaducado devuelve true")
    void tokenCaducado() {
        // TTL nulo → cualquier token vence al instante.
        JwtConfig cfg = new JwtConfig();
        cfg.setSecret("Y2xhdmVfZGVfMjU2X2JpdHNfcGFyYV90ZXN0c191bml0YXJpb3NfdmljdG9yaW5v");
        cfg.setAccessTtl(Duration.ofSeconds(-1));
        cfg.setRefreshTtl(Duration.ofDays(7));
        cfg.setIssuer("victorino-test");
        JwtService caducador = new JwtService(cfg);

        String token = caducador.generarAccessToken(usuarioFalso());
        assertThat(caducador.estaCaducado(token)).isTrue();
    }

    @Test
    @DisplayName("hashearRefreshToken produce 64 hex chars deterministas")
    void hashearRefresh() {
        String hash1 = jwtService.hashearRefreshToken("token-de-prueba");
        String hash2 = jwtService.hashearRefreshToken("token-de-prueba");

        assertThat(hash1).hasSize(64).matches("[0-9a-f]{64}");
        assertThat(hash1).isEqualTo(hash2);
        assertThat(jwtService.hashearRefreshToken("otro")).isNotEqualTo(hash1);
    }

    @Test
    @DisplayName("generarRefreshTokenOpaco produce valores distintos cada llamada")
    void refreshOpacoUnico() {
        String r1 = jwtService.generarRefreshTokenOpaco();
        String r2 = jwtService.generarRefreshTokenOpaco();
        assertThat(r1).isNotEqualTo(r2);
        assertThat(r1).hasSizeGreaterThan(40);
    }
}
