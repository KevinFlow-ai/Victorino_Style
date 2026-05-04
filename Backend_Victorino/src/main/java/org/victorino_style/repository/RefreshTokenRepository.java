package org.victorino_style.repository;


import org.springframework.data.jpa.repository.JpaRepository; // Importa JpaRepository para operaciones CRUD automáticas.

import org.springframework.data.jpa.repository.Modifying; // @Modifying permite ejecutar UPDATE o DELETE.

import org.springframework.data.jpa.repository.Query; // @Query permite definir consultas JPQL personalizadas.

import org.springframework.data.repository.query.Param; // @Param permite pasar parámetros a la consulta JPQL.

import org.victorino_style.entity.RefreshToken; // Entidad RefreshToken.

import java.time.Instant;
import java.util.Optional;

// Repositorio de los refresh tokens. Solo se guarda el SHA-256 hex del valor real.
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    // ------------------------------------------------------------------------
    // Busca un refresh token activo por su hash SHA-256.
    // Se usa en:
    // - /auth/refresh → para validar el refresh token.
    // - /auth/logout → para revocar un token concreto.
    //
    // La condición "revocadoRefreshTokenFalse" asegura que solo se devuelven
    // tokens que NO han sido revocados.
    // ------------------------------------------------------------------------
    Optional<RefreshToken> findByHashRefreshTokenAndRevocadoRefreshTokenFalse(String hashRefreshToken);






    // ------------------------------------------------------------------------
    // Revoca todos los refresh tokens de un usuario.
    // Uso futuro: cierre total de sesión en todos los dispositivos.
    //
    // UPDATE RefreshToken rt
    // SET rt.revocadoRefreshToken = true
    // WHERE rt.idUsuario.id = :idUsuario AND rt.revocadoRefreshToken = false
    //
    // Devuelve el número de filas afectadas.
    // ------------------------------------------------------------------------
    @Modifying
    @Query("UPDATE RefreshToken rt SET rt.revocadoRefreshToken = true " +
            "WHERE rt.idUsuario.id = :idUsuario AND rt.revocadoRefreshToken = false")
    int revocarTodosPorUsuario(@Param("idUsuario") Long idUsuario);







    // ------------------------------------------------------------------------
    // Borra todos los refresh tokens que ya han caducado.
    // Se usa desde un scheduler (tarea programada) para limpiar la tabla.
    //
    // DELETE FROM RefreshToken rt
    // WHERE rt.fechaCaducidadRefreshToken < :ahora
    //
    // Devuelve el número de filas eliminadas.
    // ------------------------------------------------------------------------
    @Modifying
    @Query("DELETE FROM RefreshToken rt WHERE rt.fechaCaducidadRefreshToken < :ahora")
    int borrarCaducados(@Param("ahora") Instant ahora);
}


    // ============================================================================
    // RefreshTokenRepository
    // ----------------------------------------------------------------------------
    // Este repositorio gestiona la persistencia de los **refresh tokens** en la base
    // de datos. Cada refresh token se almacena en forma de **hash SHA‑256**, nunca
    // en texto plano, para mayor seguridad.
    //
    // ¿POR QUÉ EXISTE ESTE REPOSITORIO?
    // - Permite validar refresh tokens durante /auth/refresh.
    // - Permite revocar tokens durante /auth/logout.
    // - Permite limpiar tokens caducados mediante un scheduler.
    //
    // FUNCIONES PRINCIPALES:
    // 1. Buscar un refresh token activo por su hash.
    // 2. Revocar todos los tokens de un usuario (cierre total de sesión).
    // 3. Eliminar tokens caducados.
    //
    // ANOTACIONES IMPORTANTES:
    // - Extiende JpaRepository → CRUD completo sin escribir código.
    // - @Modifying → indica que la consulta modifica datos (UPDATE/DELETE).
    // - @Query → define consultas JPQL personalizadas.
    // ============================================================================
