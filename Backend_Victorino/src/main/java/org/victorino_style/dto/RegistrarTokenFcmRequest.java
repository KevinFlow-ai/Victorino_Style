package org.victorino_style.dto;
public record RegistrarTokenFcmRequest(
        Long idUsuario,
        String tokenFcm,
        String plataformaFcm,     // "android" o "ios"
        Boolean esLoginExplicito  // true = login con credenciales, false = restauracion de sesion
) {}
