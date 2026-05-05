package org.victorino_style.dto.admin;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

// DTO de entrada para crear o editar un servicio del catálogo.
// Lo usa el administrador en POST /admin/servicios y PUT /admin/servicios/{id}.
// La foto NO va aquí: se sube por separado vía POST /admin/servicios/{id}/foto.
public record ServicioAdminRequest(

        // Nombre comercial del servicio. Obligatorio, máx. 150 caracteres (igual que la columna).
        @NotBlank(message = "El nombre del servicio es obligatorio")
        @Size(max = 150, message = "El nombre no puede superar los 150 caracteres")
        String nombre,

        // Descripción opcional. Máx. 500 caracteres.
        @Size(max = 500, message = "La descripción no puede superar los 500 caracteres")
        String descripcion,

        // Duración del servicio en minutos. Define `hora_fin = hora_inicio + duracion`.
        // Mínimo 5 minutos, máximo 480 (8 horas) según validación del schema.sql.
        @NotNull(message = "La duración es obligatoria")
        @Min(value = 5, message = "La duración mínima es de 5 minutos")
        @Max(value = 120, message = "La duración máxima es de 120 minutos (2 horas)")
        Integer duracionMinutos,

        // Precio en euros. Obligatorio, mínimo 0.01 € (no se permiten servicios gratuitos).
        @NotNull(message = "El precio es obligatorio")
        @DecimalMin(value = "0.01", message = "El precio mínimo es 0.01 €")
        BigDecimal precio
) {
}

// ============================================================================
// ServicioAdminRequest
// ----------------------------------------------------------------------------
// DTO que el administrador envía para dar de alta o editar un servicio del
// catálogo de la peluquería.
//
// ¿PARA QUÉ SIRVE?
// - Endpoint POST /admin/servicios crea un servicio nuevo a partir de este DTO.
// - Endpoint PUT  /admin/servicios/{id} edita los campos.
// - ServicioAdminService traduce el DTO a una fila de `servicio` y, tras
//   guardar, exige que se suba la foto vía endpoint dedicado para cumplir la
//   regla de "foto obligatoria".
//
// CAMPO duracionMinutos (CRÍTICO):
// - Es el campo más sensible del catálogo. El sistema calcula
//   `hora_fin = hora_inicio + duracionMinutos` al reservar.
// - Cambiar la duración de un servicio NO afecta a citas ya reservadas
//   (su hora_fin ya está persistida), pero sí a las nuevas.
//
// CAMPO precio:
// - Se transporta como BigDecimal para evitar problemas de precisión
//   (FLOAT/DOUBLE están prohibidos en el proyecto). Se mapea a
//   `DECIMAL(10,2)` en MySQL.
// ============================================================================
