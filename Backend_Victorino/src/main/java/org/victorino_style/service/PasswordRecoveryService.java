package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.entity.TokenRecuperacion;
import org.victorino_style.entity.Usuario;
import org.victorino_style.repository.TokenRecuperacionRepository;
import org.victorino_style.repository.UsuarioRepository;

import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Locale;

@Slf4j
@Service
@RequiredArgsConstructor
public class PasswordRecoveryService {

    private static final int MINUTOS_CADUCIDAD = 15;

    private final UsuarioRepository usuarioRepository;
    private final TokenRecuperacionRepository tokenRecuperacionRepository;
    private final PasswordEncoder passwordEncoder;
    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public String crearCodigoRecuperacion(String correoRecibido) {
        String correo = normalizarCorreo(correoRecibido);
        Usuario usuario = buscarUsuarioActivoPorCorreo(correo);

        tokenRecuperacionRepository.marcarTokensActivosComoUsados(usuario);

        String codigo = generarCodigoNumerico();

        Instant ahora = Instant.now();

        TokenRecuperacion token = new TokenRecuperacion();
        token.setIdUsuario(usuario);
        token.setCodigoTokenRecuperacion(codigo);
        token.setFechaEmisionTokenRecuperacion(ahora);
        token.setFechaCaducidadTokenRecuperacion(ahora.plus(MINUTOS_CADUCIDAD, ChronoUnit.MINUTES));
        token.setUsadoTokenRecuperacion(false);

        tokenRecuperacionRepository.save(token);

        log.info("Código de recuperación generado para usuario id={}", usuario.getId());

        return codigo;
    }

    @Transactional(readOnly = true)
    public boolean verificarCodigo(String correoRecibido, String codigo) {
        String correo = normalizarCorreo(correoRecibido);
        Usuario usuario = buscarUsuarioActivoPorCorreo(correo);

        return tokenRecuperacionRepository
                .findByIdUsuarioAndCodigoTokenRecuperacionAndUsadoTokenRecuperacionFalse(usuario, codigo)
                .filter(TokenRecuperacion::estaDisponible)
                .isPresent();
    }

    @Transactional
    public void cambiarPassword(String correoRecibido, String codigo, String nuevaPassword) {
        String correo = normalizarCorreo(correoRecibido);
        Usuario usuario = buscarUsuarioActivoPorCorreo(correo);

        TokenRecuperacion token = tokenRecuperacionRepository
                .findByIdUsuarioAndCodigoTokenRecuperacionAndUsadoTokenRecuperacionFalse(usuario, codigo)
                .filter(TokenRecuperacion::estaDisponible)
                .orElseThrow(() -> new IllegalArgumentException("Código inválido o caducado"));

        usuario.setContrasenaUsuario(passwordEncoder.encode(nuevaPassword));
        usuario.setFechaModificacionUsuario(Instant.now());
        usuarioRepository.save(usuario);

        token.marcarComoUsado();
        tokenRecuperacionRepository.save(token);

        log.info("Contraseña actualizada correctamente para usuario id={}", usuario.getId());
    }

    private String generarCodigoNumerico() {
        return String.format("%06d", secureRandom.nextInt(1_000_000));
    }

    private Usuario buscarUsuarioActivoPorCorreo(String correo) {
        return usuarioRepository.findByCorreoUsuarioAndFechaEliminacionUsuarioIsNull(correo)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));
    }

    private String normalizarCorreo(String correo) {
        return correo.trim().toLowerCase(Locale.ROOT);
    }
}