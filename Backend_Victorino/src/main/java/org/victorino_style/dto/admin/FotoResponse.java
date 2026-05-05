package org.victorino_style.dto.admin;

// DTO de salida tras subir una foto vía endpoint multipart.
// Lo devuelven POST /admin/empleados/{id}/foto y POST /admin/servicios/{id}/foto.
public record FotoResponse(

        // Ruta relativa dentro del servidor (ej. "/uploads/empleados/abc123.jpg").
        // El frontend la concatena con la base de la API para descargarla.
        String fotoUrl
) {
}

// ============================================================================
// FotoResponse
// ----------------------------------------------------------------------------
// Respuesta minimalista de los endpoints de subida de foto.
//
// ¿PARA QUÉ SIRVE?
// - Tras subir la foto el cliente Flutter reemplaza la imagen mostrada
//   por la nueva URL devuelta.
//
// FORMATO DE LA URL:
// - Siempre empieza por "/uploads/<carpeta>/".
// - El servidor expone esa ruta como recurso estático
//   (spring.web.resources.static-locations=file:uploads/).
// - El frontend la concatena con la baseUrl de Dio
//   (ej. http://10.0.2.2:8080/api/v1) o sirve el dominio público en
//   producción.
// ============================================================================


/*
    ¿Qué hace public record FotoResponse(String fotoUrl)?
    Este record representa la respuesta que el backend envía al frontend
    cuando se necesita devolver información sobre una foto.

    ¿Qué contiene?
    Solo un campo:
    fotoUrl: la ruta relativa donde está almacenada la imagen en el servidor.

    ¿Para qué sirve?
    El backend no devuelve la imagen directamente.

    Devuelve la ruta donde está guardada.

    El frontend construye la URL completa, por ejemplo:
 */