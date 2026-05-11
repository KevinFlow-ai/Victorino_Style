package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.victorino_style.entity.Notificacion;

import java.util.List;

// Repositorio de la bandeja de notificaciones in-app.
public interface NotificacionRepository extends JpaRepository<Notificacion, Long> {

    // Notificaciones de un usuario, ordenadas por fecha desc (las más recientes primero).
    List<Notificacion> findByIdDestinatarioNotificacion_IdOrderByFechaCreacionNotificacionDesc(Long idUsuario);

    // Notificaciones de un usuario que aún NO se entregaron como push y que el usuario NO ha leído.
    // Se usan para el "catch-up push" al iniciar sesión: si el usuario estaba offline cuando se generó
    // la notificación (o el push falló), se reenvían en cuanto inicia sesión con credenciales.
    List<Notificacion> findByIdDestinatarioNotificacion_IdAndEnviadaPushNotificacionFalseAndFechaLecturaNotificacionIsNull(Long idUsuario);

    // Resetea la bandera enviada_push a false en todas las notificaciones NO leídas del usuario.
    // Se invoca al inicio de sesión explícito (login con credenciales) ANTES de ejecutar el
    // catch-up push. Esto garantiza que notificaciones marcadas como "push enviado" durante
    // una sesión anterior (incluso si el token era válido pero el empleado no las vio) se
    // re-envíen como push en el nuevo login.
    // No afecta a notificaciones ya leídas (fechaLectura != null).
    // clearAutomatically = true → limpia la caché de la sesión JPA después del UPDATE masivo,
    // garantizando que la consulta del catch-up posterior lea valores frescos de la BD
    // en lugar de los datos en caché con el valor antiguo enviada_push=true.
    @Modifying(clearAutomatically = true)
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