package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;

import java.math.BigDecimal;
import java.time.Instant;

@Getter
@Setter
@Entity
@Table(name = "servicio")
public class Servicio {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_servicio", nullable = false)
    private Long id;

    @Size(max = 150)
    @NotNull
    @Column(name = "nombre_servicio", nullable = false, length = 150)
    private String nombreServicio;

    @Size(max = 500)
    @Column(name = "descripcion_servicio", length = 500)
    private String descripcionServicio;

    @Column(name = "duracion_servicio", columnDefinition = "smallint UNSIGNED not null")
    private Integer duracionServicio;

    @NotNull
    @Column(name = "precio_servicio", nullable = false, precision = 10, scale = 2)
    private BigDecimal precioServicio;

    @Size(max = 255)
    @NotNull
    @Column(name = "foto_servicio", nullable = false)
    private String fotoServicio;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_creacion_servicio", nullable = false)
    private Instant fechaCreacionServicio;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_modificacion_servicio", nullable = false)
    private Instant fechaModificacionServicio;

    @Column(name = "fecha_eliminacion_servicio")
    private Instant fechaEliminacionServicio;


}