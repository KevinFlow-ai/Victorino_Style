package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.entity.DeviceTokenFcm;

import java.util.List;
import java.util.Optional;

// Repositorio de tokens FCM por dispositivo. Cada usuario puede tener varios.
public interface DeviceTokenFcmRepository extends JpaRepository<DeviceTokenFcm, Long> {

    // Tokens FCM activos de un usuario. Los consulta NotificacionService al enviar push.
    List<DeviceTokenFcm> findByIdUsuario_Id(Long idUsuario);

    // Busca un token FCM concreto (para detectar si ya existe antes de crear uno nuevo).
    Optional<DeviceTokenFcm> findByTokenFcm(String tokenFcm);

    // Elimina un token concreto de la base de datos. FirebaseService lo llama cuando FCM
    // responde UNREGISTERED o INVALID_ARGUMENT (token caducado o invalido).
    @Modifying
    @Transactional
    void deleteByTokenFcm(String tokenFcm);

    // Elimina TODOS los tokens FCM de un usuario. Se llama cuando cierra sesion para que
    // el siguiente login registre un token fresco y el catch-up push funcione correctamente.
    // Sin este borrado, las notificaciones creadas mientras la sesion estaba cerrada se
    // marcarian 'enviada_push=true' de forma optimista al encontrar el token viejo,
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