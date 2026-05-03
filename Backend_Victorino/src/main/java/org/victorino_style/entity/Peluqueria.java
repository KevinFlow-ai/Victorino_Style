package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalTime;

@Getter
@Setter
@Entity
@Table(name = "peluqueria")
public class Peluqueria {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_peluqueria", nullable = false)
    private Long id;

    @Size(max = 180)
    @NotNull
    @Column(name = "nombre_peluqueria", nullable = false, length = 180)
    private String nombrePeluqueria;

    @Column(name = "apertura_lunes")
    private LocalTime aperturaLunes;

    @Column(name = "cierre_lunes")
    private LocalTime cierreLunes;

    @Column(name = "apertura_martes")
    private LocalTime aperturaMartes;

    @Column(name = "cierre_martes")
    private LocalTime cierreMartes;

    @Column(name = "apertura_miercoles")
    private LocalTime aperturaMiercoles;

    @Column(name = "cierre_miercoles")
    private LocalTime cierreMiercoles;

    @Column(name = "apertura_jueves")
    private LocalTime aperturaJueves;

    @Column(name = "cierre_jueves")
    private LocalTime cierreJueves;

    @Column(name = "apertura_viernes")
    private LocalTime aperturaViernes;

    @Column(name = "cierre_viernes")
    private LocalTime cierreViernes;

    @Column(name = "apertura_sabado")
    private LocalTime aperturaSabado;

    @Column(name = "cierre_sabado")
    private LocalTime cierreSabado;

    @Column(name = "apertura_domingo")
    private LocalTime aperturaDomingo;

    @Column(name = "cierre_domingo")
    private LocalTime cierreDomingo;

    @Column(name = "cierre_anual_inicio")
    private LocalDate cierreAnualInicio;

    @Column(name = "cierre_anual_fin")
    private LocalDate cierreAnualFin;


}