package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalTime;

@Getter
@Setter
@Entity
@Table(name = "empleado")
public class Empleado {
    @Id
    @Column(name = "id_empleado", nullable = false)
    private Long id;

    @MapsId
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "id_empleado", nullable = false)
    private Usuario usuario;

    @Size(max = 100)
    @NotNull
    @Column(name = "nombre_empleado", nullable = false, length = 100)
    private String nombreEmpleado;

    @Size(max = 150)
    @NotNull
    @Column(name = "apellidos_empleado", nullable = false, length = 150)
    private String apellidosEmpleado;

    @Size(max = 255)
    @NotNull
    @Column(name = "foto_empleado", nullable = false)
    private String fotoEmpleado;

    @Column(name = "silencio_inicio_empleado")
    private LocalTime silencioInicioEmpleado;

    @Column(name = "silencio_fin_empleado")
    private LocalTime silencioFinEmpleado;

    @NotNull
    @ColumnDefault("0")
    @Column(name = "no_molestar_empleado", nullable = false)
    private Boolean noMolestarEmpleado;


}