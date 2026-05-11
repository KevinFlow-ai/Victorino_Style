package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.entity.DeviceTokenFcm;
import java.util.Optional;

import java.util.List;

// Repositorio de tokens FCM por dispositivo. Cada usuario puede tener varios.
public interface DeviceTokenFcmRepository extends JpaRepository<DeviceTokenFcm, Long> {

    // Tokens FCM activos de un usuario. Los consulta NotificacionService al enviar push.
    List<DeviceTokenFcm> findByIdUsuario_Id(Long idUsuario);

    Optional<DeviceTokenFcm> findByTokenFcm(String tokenFcm);

    // Esto lo que hace es eliminar un token concreto de la base de datos. FirebaseService lo llama cuando FCM
    // responde UNREGISTERED o INVALID_ARGUMENT (que basicamente es token caducado o inválido).
    @Modifying
    @Transactional
    void deleteByTokenFcm(String tokenFcm);

    // Elimina TODOS los tokens FCM de un usuario. Se llama cuando cierra sesión para que
    // el siguiente login registre un token fresco y el catch-up push funcione correctamente.
    // Sin este borrado, las notificaciones creadas mientras la sesión estaba cerrada se
    // marcarían 'enviada_push=true' de forma optimista al encontrar el token viejo,
    // bloqueando el mecanismo de catch-up.
    @Modifying
    @Transactional
    void deleteByIdUsuario_Id(Long idUsuario);
}





    // Este métodoo devuelve todos los tokens FCM (Firebase Cloud Messaging)
    // asociados a un usuario concreto.
    //
    // ------------------------------------------------------------------------
    // ¿QUÉ ES findByIdUsuario_Id?
    // ------------------------------------------------------------------------
    // Spring Data JPA interpreta el nombre del métodoo y genera automáticamente
    // la consulta. En este caso:
    //
    //   findByIdUsuario_Id(Long idUsuario)
    //
    // significa:
    //   "Busca todos los DeviceTokenFcm donde el campo idUsuario.id sea igual
    //    al valor pasado como parámetro".
    //
    // Es decir, navega por la relación:
    //   DeviceTokenFcm → idUsuario → id
    //
    // y filtra por ese ID.
    //
    // ------------------------------------------------------------------------
    // ¿PARA QUÉ SIRVE?
    // ------------------------------------------------------------------------
    // NotificacionService lo usa cuando necesita enviar notificaciones push.
    // Un usuario puede tener varios dispositivos (móvil personal, tablet, etc.),
    // y cada uno tiene un token FCM distinto.
    //
    // Este métodoo recupera todos los tokens activos del usuario para enviar
    // la notificación a todos sus dispositivos.
    //
    // Ejemplo:
    //   Usuario 5 tiene 3 dispositivos → devuelve 3 DeviceTokenFcm.
    //
    // ------------------------------------------------------------------------