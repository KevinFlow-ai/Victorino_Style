package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.victorino_style.entity.enums.EstadoCita;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;

// Entidad principal del dominio: representa una cita reservada en la peluquería.
// Sigue la convención del proyecto: PK con sufijo del nombre de tabla, columnas con sufijo y
// soft-validation a nivel de Bean Validation.
@Getter
@Setter
@Entity
@Table(name = "cita")
public class Cita { // Clave primaria autoincremental de la tabla `cita`.


    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cita", nullable = false)
    private Long id;

    // Cliente registrado dueño de la cita. Excluyente con `idClienteInvitado` (XOR a nivel de BD).
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cliente")
    private Cliente idCliente;

    // Cliente sin cuenta (walk-in). Excluyente con `idCliente`.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cliente_invitado")
    private ClienteInvitado idClienteInvitado;

    // Empleado que atenderá la cita. Obligatorio.
    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_empleado", nullable = false)
    private Empleado idEmpleado;

    // Servicio reservado. Su `duracionServicio` define `horaFinCita = horaInicioCita + duracion`.
    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_servicio", nullable = false)
    private Servicio idServicio;

    // Día concreto de la cita (sin hora).
    @NotNull
    @Column(name = "fecha_cita", nullable = false)
    private LocalDate fechaCita;

    // Hora de inicio (HH:mm:ss). El servicio comprueba que entre dentro del horario de apertura.
    @NotNull
    @Column(name = "hora_inicio_cita", nullable = false)
    private LocalTime horaInicioCita;

    // Hora de fin calculada como inicio + duracion del servicio. Se persiste para acelerar consultas.
    @NotNull
    @Column(name = "hora_fin_cita", nullable = false)
    private LocalTime horaFinCita;

    // Estado de la cita. Se mapea como ENUM type-safe con MySQL ENUM.
    // El valor por defecto que aplica MySQL al insertar es CONFIRMADA.
    @NotNull
    @Enumerated(EnumType.STRING)
    @ColumnDefault("'CONFIRMADA'")
    @Column(name = "estado_cita", nullable = false,
            columnDefinition = "ENUM('CONFIRMADA','EN_PROCESO','COMPLETADA','CANCELADA_CLIENTE','CANCELADA_PELUQUERIA','NO_PRESENTADO')")
    private EstadoCita estadoCita;

    // Nota opcional que el cliente o empleado deja para la cita (≤ 350 caracteres).
    @Size(max = 350)
    @Column(name = "nota_cita", length = 350)
    private String notaCita;

    // Sello de creación (lo asigna MySQL con CURRENT_TIMESTAMP(6)).
    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_creacion_cita", nullable = false)
    private Instant fechaCreacionCita;

    // Sello de última modificación.
    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_modificacion_cita", nullable = false)
    private Instant fechaModificacionCita;

    // Versión optimista. Sirve como fallback al PESSIMISTIC_WRITE: si dos transacciones
    // modifican la misma cita simultáneamente, Hibernate lanza OptimisticLockException
    // en la segunda y el servicio reintenta o devuelve 409.
    @Version
    @ColumnDefault("0")
    @Column(name = "version_cita", nullable = false)
    private Long versionCita;
}

// ============================================================================
// Cita
// ----------------------------------------------------------------------------
// Entidad central del sistema. Cada fila representa una reserva concreta:
// quién, cuándo, con qué empleado y qué servicio.
//
// REGLAS DE INTEGRIDAD QUE GARANTIZA LA BD:
// - XOR cliente / cliente_invitado: exactamente uno de los dos debe estar
//   informado (CHECK en `schema.sql`).
// - hora_fin_cita > hora_inicio_cita.
// - Índices en (id_empleado, fecha_cita) y (id_cliente, fecha_cita) para que
//   las consultas de agenda y de huecos disponibles sean rápidas.
//
// REGLAS DE NEGOCIO QUE GARANTIZAN LOS SERVICIOS:
// - 1 cita por cliente y día (salvo override de admin / empleado en walk-in).
// - Reserva con antelación máxima de 30 días desde hoy.
// - Solo el estado CONFIRMADA es modificable.
// - Modificación con bloqueo pesimista (`SELECT ... FOR UPDATE`).
//
// SOBRE @Version:
// - Es un mecanismo de control de concurrencia OPTIMISTA. Hibernate compara
//   el número de versión al hacer UPDATE; si no coincide, lanza
//   OptimisticLockException.
// - Lo usamos como cinturón de seguridad ADICIONAL al lock pesimista del
//   repositorio para escenarios donde el lock no se puede aplicar (por
//   ejemplo, listados sin lock que terminan en escritura).
// ============================================================================
