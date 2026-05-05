package org.victorino_style.mapper;

import org.springframework.stereotype.Component;
import org.victorino_style.dto.admin.ServicioAdminResponse;
import org.victorino_style.entity.Servicio;

// Un "mapper" es una clase cuya responsabilidad es TRANSFORMAR datos de un tipo a otro.
// Normalmente se usa para convertir entidades de base de datos (modelos internos)
// en objetos que se devuelven al cliente (DTOs), o viceversa.
// Su objetivo es separar la lógica de negocio de la representación externa,
// manteniendo el código limpio, ordenado y fácil de mantener.


@Component // Spring detecta esta clase como componente inyectable.
public class ServicioMapper {

    // Este méetodo recibe un objeto Servicio (entidad de BD)
    // y construye un ServicioAdminResponse (DTO para la API).
    public ServicioAdminResponse aRespuesta(Servicio s) {

        // Se crea el DTO usando los valores de la entidad.
        // Observa el último parámetro: s.getFechaEliminacionServicio() == null
        //
        // Esto devuelve true si el servicio NO está eliminado (fecha null),
        // y false si sí está eliminado (fecha no null).
        // Es decir, convierte un dato de BD en un booleano más útil para el cliente.
        return new ServicioAdminResponse(
                s.getId(),                     // ID del servicio
                s.getNombreServicio(),         // Nombre
                s.getDescripcionServicio(),    // Descripción
                s.getDuracionServicio(),       // Duración en minutos
                s.getPrecioServicio(),         // Precio
                s.getFotoServicio(),           // URL o nombre de la foto
                s.getFechaEliminacionServicio() == null // ¿Está activo?
        );
    }
}



