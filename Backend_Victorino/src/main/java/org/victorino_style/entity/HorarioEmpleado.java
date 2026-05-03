package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalTime;

@Getter
@Setter
@Entity
@Table(name = "horario_empleado")
public class HorarioEmpleado {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_horario_empleado", nullable = false)
    private Long id;

    @NotNull
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "id_empleado", nullable = false)
    private Empleado idEmpleado;

    @NotNull
    @Column(name = "descanso_inicio_horario", nullable = false)
    private LocalTime descansoInicioHorario;

    @ColumnDefault("'30'")
    @Column(name = "descanso_duracion_horario", columnDefinition = "smallint UNSIGNED not null")
    private Integer descansoDuracionHorario;


}