package org.victorino_style.mapper;

import org.springframework.stereotype.Component;
import org.victorino_style.dto.admin.FestivoResponse;
import org.victorino_style.entity.Festivo;
import org.victorino_style.entity.enums.TipoFestivo;

// Convierte una entidad Festivo en su DTO de salida.
// Festivo.tipoFestivo se almacena como String (mapea ENUM de MySQL).
// El mapper lo traduce a TipoFestivo para que el frontend reciba el enum.

// Un "mapper" es una clase cuya responsabilidad es TRANSFORMAR datos de un tipo a otro.
// Normalmente se usa para convertir entidades de base de datos (modelos internos)
// en objetos que se devuelven al cliente (DTOs), o viceversa.
// Su objetivo es separar la lógica de negocio de la representación externa,
// manteniendo el código limpio, ordenado y fácil de mantener.

@Component // Indica a Spring que esta clase es un componente que puede inyectarse.
public class FestivoMapper {

    // Este métoddo convierte un objeto Festivo (entidad de BD)
    // en un FestivoResponse (DTO que se envía al cliente).
    public FestivoResponse aRespuesta(Festivo f) {

        // Declaramos una variable del enum TipoFestivo.
        TipoFestivo tipo;

        try {
            // Intentamos convertir el String que viene de la BD (f.getTipoFestivo())
            // al enum TipoFestivo. Ejemplo: "NACIONAL" -> TipoFestivo.NACIONAL
            //
            // valueOf lanza IllegalArgumentException si el String NO coincide
            // con ningún valor del enum (dato corrupto, error humano, etc.).
            tipo = TipoFestivo.valueOf(f.getTipoFestivo());

        } catch (IllegalArgumentException ex) {
            // Si el valor en la BD está mal escrito o no existe en el enum,
            // evitamos que la aplicación falle.
            // Asignamos un valor por defecto (NACIONAL) para mantener la respuesta estable.
            tipo = TipoFestivo.NACIONAL;
        }

        // Finalmente construimos el DTO FestivoResponse con los datos ya validados.
        return new FestivoResponse(
                f.getId(),
                f.getFechaFestivo(),
                f.getDescripcionFestivo(),
                tipo
        );
    }
}

