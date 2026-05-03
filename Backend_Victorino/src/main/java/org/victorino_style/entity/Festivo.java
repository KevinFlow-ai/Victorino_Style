package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDate;

@Getter
@Setter
@Entity
@Table(name = "festivo")
public class Festivo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_festivo", nullable = false)
    private Long id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "id_peluqueria", nullable = false)
    private Peluqueria idPeluqueria;

    @NotNull
    @Column(name = "fecha_festivo", nullable = false)
    private LocalDate fechaFestivo;

    @Size(max = 150)
    @NotNull
    @Column(name = "descripcion_festivo", nullable = false, length = 150)
    private String descripcionFestivo;

    @NotNull
    @Lob
    @Column(name = "tipo_festivo", nullable = false)
    private String tipoFestivo;


}