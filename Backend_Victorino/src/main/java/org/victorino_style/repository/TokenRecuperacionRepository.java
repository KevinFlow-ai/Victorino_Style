package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.victorino_style.entity.TokenRecuperacion;
import org.victorino_style.entity.Usuario;

import java.util.Optional;

public interface TokenRecuperacionRepository extends JpaRepository<TokenRecuperacion, Long> {

    @Modifying
    @Query("""
            update TokenRecuperacion token
            set token.usadoTokenRecuperacion = true
            where token.idUsuario = :usuario
              and token.usadoTokenRecuperacion = false
            """)
    void marcarTokensActivosComoUsados(Usuario usuario);

    Optional<TokenRecuperacion> findByIdUsuarioAndCodigoTokenRecuperacionAndUsadoTokenRecuperacionFalse(
            Usuario usuario,
            String codigoTokenRecuperacion
    );
}