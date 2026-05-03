package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;

@Getter
@Setter
@Entity
@Table(name = "cita")
public class Cita {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cita", nullable = false)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cliente")
    private Cliente idCliente;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cliente_invitado")
    private ClienteInvitado idClienteInvitado;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_empleado", nullable = false)
    private Empleado idEmpleado;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_servicio", nullable = false)
    private Servicio idServicio;

    @NotNull
    @Column(name = "fecha_cita", nullable = false)
    private LocalDate fechaCita;

    @NotNull
    @Column(name = "hora_inicio_cita", nullable = false)
    private LocalTime horaInicioCita;

    @NotNull
    @Column(name = "hora_fin_cita", nullable = false)
    private LocalTime horaFinCita;

    @NotNull
    @ColumnDefault("'CONFIRMADA'")
    @Lob
    @Column(name = "estado_cita", nullable = false)
    private String estadoCita;

    @Size(max = 350)
    @Column(name = "nota_cita", length = 350)
    private String notaCita;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_creacion_cita", nullable = false)
    private Instant fechaCreacionCita;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_modificacion_cita", nullable = false)
    private Instant fechaModificacionCita;


}