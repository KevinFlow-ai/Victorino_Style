package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
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
import java.util.Locale;

// Servicio principal de autenticación.
// Toda la lógica de negocio (validar credenciales, crear usuarios, manejar refresh)
// vive aquí. El controller solo orquesta y serializa.
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final ClienteRepository clienteRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final UsuarioMapper usuarioMapper;

    // ============================================================
    //  REGISTRO DE CLIENTE
    // ============================================================
    // Crea Usuario(rol=CLIENTE) + Cliente en una única transacción.
    // Tras la creación devuelve los tokens para que la app deje al cliente logueado.
    @Transactional
    public AuthResponse registrarCliente(RegistroRequest dto) {
        // Normalizamos el correo a minúsculas para evitar duplicados por mayúsculas.
        String correo = dto.correo().trim().toLowerCase(Locale.ROOT);

        // 409 si ya existe.
        if (usuarioRepository.existsByCorreoUsuario(correo)) {
            log.info("Intento de registro con correo duplicado: {}", correo);
            throw new CorreoDuplicadoException(correo);
        }

        // 1) Insertar fila en `usuario` con BCrypt.
        Usuario usuario = new Usuario();
        usuario.setCorreoUsuario(correo);
        usuario.setContrasenaUsuario(passwordEncoder.encode(dto.password()));
        usuario.setRolUsuario(RolUsuario.CLIENTE);
        Instant ahora = Instant.now();
        usuario.setFechaCreacionUsuario(ahora);
        usuario.setFechaModificacionUsuario(ahora);
        usuario = usuarioRepository.save(usuario);

        // 2) Insertar fila en `cliente` con shared PK (id_cliente == id_usuario).
        Cliente cliente = new Cliente();
        cliente.setUsuario(usuario);
        cliente.setNombreCliente(dto.nombre().trim());
        cliente.setApellidosCliente(dto.apellidos().trim());
        cliente.setTelefonoCliente(dto.telefono() != null && !dto.telefono().isBlank() ? dto.telefono().trim() : null);
        cliente.setFotoCliente(null);
        cliente.setPushActivaCliente(true);
        clienteRepository.save(cliente);

        log.info("Cliente registrado correctamente: idUsuario={}, correo={}", usuario.getId(), correo);

        // 3) Generar tokens y persistir hash del refresh.
        return generarRespuestaConTokens(usuario);
    }

    // ============================================================
    //  LOGIN COMPARTIDO
    // ============================================================
    // El mismo endpoint sirve para los 3 roles. El backend decide a qué home
    // redirigir devolviendo el rol; el cliente Flutter usa eso para navegar.
    @Transactional
    public AuthResponse iniciarSesion(LoginRequest dto) {
        String correo = dto.correo().trim().toLowerCase(Locale.ROOT);

        // findByCorreoUsuarioAndFechaEliminacionUsuarioIsNull: ignora cuentas borradas.
        Usuario usuario = usuarioRepository
                .findByCorreoUsuarioAndFechaEliminacionUsuarioIsNull(correo)
                .orElseThrow(() -> {
                    // OWASP: mismo mensaje y mismo tiempo aprox. tanto si el correo no existe
                    // como si la pwd es incorrecta. Aquí ya es genérico.
                    log.info("Login fallido: correo no registrado");
                    return new CredencialesInvalidasException();
                });

        // BCrypt.matches devuelve false si no coincide. NO lanza excepción.
        if (!passwordEncoder.matches(dto.password(), usuario.getContrasenaUsuario())) {
            log.info("Login fallido: pwd incorrecta para correo={}", correo);
            throw new CredencialesInvalidasException();
        }

        log.info("Login correcto: idUsuario={}, rol={}", usuario.getId(), usuario.getRolUsuario());
        return generarRespuestaConTokens(usuario);
    }

    // ============================================================
    //  REFRESH (renovación silenciosa del access token)
    // ============================================================
    // El refresh recibido se hashea con SHA-256 y se busca en BD.
    // No se rota: se devuelve un access nuevo con el mismo refresh.
    @Transactional(readOnly = true)
    public RefreshResponse refrescar(String refreshTokenPlano) {
        String hash = jwtService.hashearRefreshToken(refreshTokenPlano);

        RefreshToken registro = refreshTokenRepository
                .findByHashRefreshTokenAndRevocadoRefreshTokenFalse(hash)
                .orElseThrow(() -> new TokenInvalidoException("Refresh token inválido"));

        if (registro.getFechaCaducidadRefreshToken().isBefore(Instant.now())) {
            throw new TokenInvalidoException("Refresh token caducado");
        }

        Usuario usuario = registro.getIdUsuario();
        // Si el usuario fue eliminado entre tanto, lo tratamos como token inválido.
        if (usuario.getFechaEliminacionUsuario() != null) {
            throw new TokenInvalidoException("Cuenta no disponible");
        }

        String nuevoAccess = jwtService.generarAccessToken(usuario);
        return new RefreshResponse(nuevoAccess);
    }

    // ============================================================
    //  LOGOUT
    // ============================================================
    // Marca el refresh recibido como revocado. Idempotente: si no existe o ya está
    // revocado, no se rompe (devuelve sin error porque la sesión ya no es válida).
    @Transactional
    public void cerrarSesion(String refreshTokenPlano) {
        String hash = jwtService.hashearRefreshToken(refreshTokenPlano);

        refreshTokenRepository
                .findByHashRefreshTokenAndRevocadoRefreshTokenFalse(hash)
                .ifPresent(rt -> {
                    rt.setRevocadoRefreshToken(true);
                    refreshTokenRepository.save(rt);
                    log.info("Refresh revocado: idRefreshToken={}", rt.getId());
                });
    }

    // ============================================================
    //  Helper privado para emitir tokens y persistir el hash del refresh
    // ============================================================
    private AuthResponse generarRespuestaConTokens(Usuario usuario) {
        String accessToken = jwtService.generarAccessToken(usuario);
        String refreshTokenPlano = jwtService.generarRefreshTokenOpaco();

        // Solo el hash SHA-256 del refresh se guarda en BD.
        RefreshToken registro = new RefreshToken();
        registro.setIdUsuario(usuario);
        registro.setHashRefreshToken(jwtService.hashearRefreshToken(refreshTokenPlano));
        registro.setFechaEmisionRefreshToken(Instant.now());
        registro.setFechaCaducidadRefreshToken(jwtService.calcularCaducidadRefresh());
        registro.setRevocadoRefreshToken(false);
        refreshTokenRepository.save(registro);

        return usuarioMapper.aAuthResponse(usuario, accessToken, refreshTokenPlano);
    }
}
