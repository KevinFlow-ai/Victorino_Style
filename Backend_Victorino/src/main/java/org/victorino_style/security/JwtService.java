package org.victorino_style.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.victorino_style.config.JwtConfig;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.RolUsuario;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

// Servicio responsable de TODO lo relacionado con JWT y refresh tokens (cripto, no persistencia).
// - Genera access tokens firmados con HS256.
// - Genera refresh tokens opacos (32 bytes random base64) y los hashea con SHA-256.
// - Valida los tokens y extrae los claims.
@Slf4j
@Service
@RequiredArgsConstructor
public class JwtService {

    // Configuración inyectada con las propiedades victorino.jwt.*
    private final JwtConfig jwtConfig;

    // Generador criptográficamente seguro para los refresh tokens.
    private final SecureRandom secureRandom = new SecureRandom();

    // Construye la clave secreta a partir del valor base64 del properties.
    // Se calcula en cada llamada porque JwtConfig solo se lee una vez al arrancar.
    private SecretKey obtenerClave() {
        // Decodifica el secreto base64 → bytes raw.
        byte[] bytesClave = Base64.getDecoder().decode(jwtConfig.getSecret());
        // Construye la HMAC-SHA-key. jjwt valida internamente la longitud mínima.
        return Keys.hmacShaKeyFor(bytesClave);
    }



    // ------------------------------------------------------------------------
    // Genera un access token JWT con:
    //   - subject = id del usuario
    //   - claim "rol" = CLIENTE / EMPLEADO / ADMINISTRADOR
    //   - claim "correo" = correo del usuario
    //   - issuer, issuedAt, expiration
    //
    // Este token permite autorizar peticiones sin consultar BD.
    // ------------------------------------------------------------------------
    public String generarAccessToken(Usuario usuario) {
        Instant ahora = Instant.now();
        Instant expira = ahora.plus(jwtConfig.getAccessTtl());

        return Jwts.builder()
                // El subject del JWT es el id del usuario en formato String.
                .subject(String.valueOf(usuario.getId()))
                // El rol va como claim para que SecurityContext sepa qué authorities asignar.
                .claim("rol", usuario.getRolUsuario().name())
                // El correo es útil para logs y auditoría, no contiene información sensible.
                .claim("correo", usuario.getCorreoUsuario())
                .issuer(jwtConfig.getIssuer())
                .issuedAt(java.util.Date.from(ahora))
                .expiration(java.util.Date.from(expira))
                .signWith(obtenerClave(), Jwts.SIG.HS256)
                .compact();
    }




    // ------------------------------------------------------------------------
    // Valida un access token:
    //   - Firma correcta
    //   - Issuer correcto
    //   - No caducado
    //
    // Si algo falla → JwtException (capturada por el filtro).
    // ------------------------------------------------------------------------
    public Claims validarAccessToken(String token) {
        return Jwts.parser()
                .verifyWith(obtenerClave())
                .requireIssuer(jwtConfig.getIssuer())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    // Atajo para extraer únicamente el id de usuario desde un access token ya validado.
    public Long extraerIdUsuario(String token) {
        Claims claims = validarAccessToken(token);
        return Long.valueOf(claims.getSubject());
    }

    // Atajo para extraer el rol desde un access token ya validado.
    public RolUsuario extraerRol(String token) {
        Claims claims = validarAccessToken(token);
        return RolUsuario.valueOf(claims.get("rol", String.class));
    }

    // Genera un refresh token "opaco": 32 bytes aleatorios codificados en base64 url-safe.
    // No es un JWT — es solo un identificador imposible de adivinar que se valida contra BD.
    public String generarRefreshTokenOpaco() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    // Calcula el SHA-256 hex (64 caracteres) del valor del refresh token.
    // En BD solo se guarda este hash, nunca el valor original. Si alguien filtra la tabla,
    // los refresh siguen siendo inservibles para autenticarse.
    public String hashearRefreshToken(String refreshTokenPlano) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(refreshTokenPlano.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            // SHA-256 viene de fábrica en cualquier JVM; este catch es defensivo.
            log.error("No se pudo cargar el algoritmo SHA-256", e);
            throw new IllegalStateException("Algoritmo SHA-256 no disponible", e);
        }
    }


    // ------------------------------------------------------------------------
    // Calcula la fecha de caducidad del refresh token según el TTL configurado.
    // ------------------------------------------------------------------------
    public Instant calcularCaducidadRefresh() {
        return Instant.now().plus(jwtConfig.getRefreshTtl());
    }



    // ------------------------------------------------------------------------
    // Comprueba si un access token está caducado.
    // Si la firma es inválida o el token es ilegible → se considera caducado.
    // Útil para tests y para refresh.
    public boolean estaCaducado(String token) {
        try {
            return validarAccessToken(token).getExpiration().toInstant().isBefore(Instant.now());
        } catch (JwtException e) {
            // Si la firma falla o el token es ilegible, lo tratamos como caducado/inválido.
            return true;
        }
    }
}




    // ============================================================================
    // JwtService
    // ----------------------------------------------------------------------------
    // Este servicio encapsula TODA la lógica criptográfica relacionada con:
    //
    //  ✔ Generación de access tokens (JWT firmados con HS256)
    //  ✔ Validación de access tokens (firma, issuer, expiración)
    //  ✔ Generación de refresh tokens opacos (32 bytes aleatorios base64-url)
    //  ✔ Hash SHA‑256 de refresh tokens para guardarlos de forma segura en BD
    //  ✔ Cálculo de fechas de expiración
    //
    // NO maneja persistencia: eso lo hace RefreshTokenRepository.
    // Este servicio solo se encarga de la parte criptográfica y de construcción
    // de tokens.
    // ============================================================================
