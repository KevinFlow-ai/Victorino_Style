package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Notificacion;
import java.util.List;

// NOTI
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;


// Repositorio de la bandeja de notificaciones in-app.
public interface NotificacionRepository extends JpaRepository<Notificacion, Long> {

    // Notificaciones de un usuario, ordenadas por fecha desc (las más recientes primero).
    List<Notificacion> findByIdDestinatarioNotificacion_IdOrderByFechaCreacionNotificacionDesc(Long idUsuario);

    // Notificaciones de un usuario que aun NO se entregaron como push y que el usuario NO ha leido.
    // Se usan para el "catch-up push" al iniciar sesion.
    List<Notificacion> findByIdDestinatarioNotificacion_IdAndEnviadaPushNotificacionFalseAndFechaLecturaNotificacionIsNull(Long idUsuario);

    // Resetea la bandera enviada_push a false en todas las notificaciones NO leidas del usuario.
    // Se invoca al inicio de sesion explicito (login con credenciales) ANTES de ejecutar el
    // catch-up push. clearAutomatically = true limpia la cache de la sesion JPA despues del
    // UPDATE masivo, garantizando que la consulta del catch-up posterior lea valores frescos.
    @Modifying(clearAutomatically = true)
    @Transactional
    @Query("UPDATE Notificacion n SET n.enviadaPushNotificacion = false " +
            "WHERE n.idDestinatarioNotificacion.id = :idUsuario " +
            "AND n.fechaLecturaNotificacion IS NULL")
    void resetEnviadaPushParaNoLeidas(@Param("idUsuario") Long idUsuario);
}



// ------------------------------------------------------------------------
        // findByIdDestinatarioNotificacion_IdOrderByFechaCreacionNotificacionDesc
        // ------------------------------------------------------------------------
        // Este métodoo devuelve TODAS las notificaciones dirigidas a un usuario
        // concreto (idUsuario), ordenadas desde la más reciente a la más antigua.
        //
        // ¿Cómo funciona?
        // Spring Data JPA interpreta el nombre del métodoo y genera automáticamente
        // la consulta. El nombre se puede leer así:
        //
        //   findBy → "Busca por"
        //   IdDestinatarioNotificacion → campo que referencia al usuario destinatario
        //   _Id → específicamente el ID de ese usuario
        //   OrderByFechaCreacionNotificacionDesc → ordena por fecha de creación DESC
        //
        // Es equivalente a escribir manualmente:
        //
        //   SELECT n
        //   FROM Notificacion n
        //   WHERE n.idDestinatarioNotificacion.id = :idUsuario
        //   ORDER BY n.fechaCreacionNotificacion DESC
        //
        // ¿Para qué sirve?
        //   → Para mostrar la bandeja de notificaciones in-app del usuario.
        //   → Las más recientes aparecen primero, como en cualquier sistema moderno.
        //
        // ¿Qué devuelve?
        //   → Una lista de Notificacion.
        //   → Si el usuario no tiene notificaciones, devuelve una lista vacía.
        //
        // ------------------------------------------------------------------------