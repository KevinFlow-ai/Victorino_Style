package org.victorino_style.repository;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.enums.EstadoCita;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

// Repositorio de la entidad Cita. Concentra todas las consultas de agenda y métricas.
// Las consultas de métricas usan @Query JPQL con agregaciones para que NO se carguen
// entidades en memoria.
public interface CitaRepository extends JpaRepository<Cita, Long> {

    // ------------------------------------------------------------------------
    // Citas futuras de un empleado en estado CONFIRMADA.
    // Sin @Lock: esta consulta solo carga las citas para iterar. El lock real se aplica
    // cita a cita dentro de cancelarUnaCita() mediante findByIdParaActualizar().
    // ------------------------------------------------------------------------
    @Query("""
           SELECT c FROM Cita c
           WHERE c.idEmpleado.id = :idEmpleado
             AND c.estadoCita = org.victorino_style.entity.enums.EstadoCita.CONFIRMADA
             AND (c.fechaCita > :hoy
                  OR (c.fechaCita = :hoy AND c.horaInicioCita > :horaActual))
           """)
    List<Cita> findCitasFuturasParaCancelar(
            @Param("idEmpleado") Long idEmpleado,
            @Param("hoy") LocalDate hoy,
            @Param("horaActual") LocalTime horaActual
    );

    // ------------------------------------------------------------------------
    // Carga una cita con LOCK pesimista por id. Útil cuando ya conoces el id y
    // quieres bloquear esa fila concreta antes de cancelarla individualmente.
    // ------------------------------------------------------------------------
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM Cita c WHERE c.id = :id")
    Optional<Cita> findByIdParaActualizar(@Param("id") Long id);

    // ------------------------------------------------------------------------
    // Citas de un empleado en una franja [desde, hasta] (sin filtro de estado).
    // Lo usa la agenda global y el cálculo de huecos disponibles del walk-in.
    // ------------------------------------------------------------------------
    List<Cita> findByIdEmpleado_IdAndFechaCitaBetweenOrderByFechaCitaAscHoraInicioCitaAsc(
            Long idEmpleado,
            LocalDate desde,
            LocalDate hasta
    );

    // ------------------------------------------------------------------------
    // Agenda global con filtros opcionales (todos pueden ser null salvo el rango).
    // Si idEmpleado o estado son null, no se filtra por ellos.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT c FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
             AND (:idEmpleado IS NULL OR c.idEmpleado.id = :idEmpleado)
             AND (:estado IS NULL OR c.estadoCita = :estado)
           ORDER BY c.fechaCita ASC, c.horaInicioCita ASC
           """)
    List<Cita> buscarAgenda(
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta,
            @Param("idEmpleado") Long idEmpleado,
            @Param("estado") EstadoCita estado
    );

    // ... existing code ...
    // ------------------------------------------------------------------------
    // Historial completo de un cliente registrado, ordenado descendente.
    // ------------------------------------------------------------------------
    List<Cita> findByIdCliente_IdOrderByFechaCitaDescHoraInicioCitaDesc(Long idCliente);

    // ------------------------------------------------------------------------
    // Historial de un cliente registrado filtrado por empleado, ordenado descendente.
    // ------------------------------------------------------------------------
    List<Cita> findByIdCliente_IdAndIdEmpleado_IdOrderByFechaCitaDescHoraInicioCitaDesc(
            Long idCliente,
            Long idEmpleado
    );

    // ------------------------------------------------------------------------
    // Cuenta citas de un empleado por estado.
    // Este método lo usa CitaService.obtenerResumenPerfil().
    // ------------------------------------------------------------------------
    long countByIdEmpleado_IdAndEstadoCita(Long idEmpleado, EstadoCita estadoCita);

    // ------------------------------------------------------------------------
    // Cuenta de citas en estado concreto en un rango de fechas. Usado en métricas.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT COUNT(c) FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
             AND c.estadoCita = :estado
           """)
    long contarPorEstado(
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta,
            @Param("estado") EstadoCita estado
    );

    // ------------------------------------------------------------------------
    // Total de citas en un rango de fechas (cualquier estado).
    // ------------------------------------------------------------------------
    @Query("""
           SELECT COUNT(c) FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
           """)
    long contarTotal(
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta
    );

    // ------------------------------------------------------------------------
    // Servicio más solicitado en un rango.
    // Devuelve un Object[] con (idServicio, nombre, count).
    // ------------------------------------------------------------------------
    @Query("""
           SELECT c.idServicio.id, c.idServicio.nombreServicio, COUNT(c)
           FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
             AND c.estadoCita <> org.victorino_style.entity.enums.EstadoCita.CANCELADA_CLIENTE
             AND c.estadoCita <> org.victorino_style.entity.enums.EstadoCita.CANCELADA_PELUQUERIA
           GROUP BY c.idServicio.id, c.idServicio.nombreServicio
           ORDER BY COUNT(c) DESC
           """)
    List<Object[]> rankingServicios(
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta
    );

    // ------------------------------------------------------------------------
    // Empleado más reservado en un rango (no cuenta canceladas).
    // ------------------------------------------------------------------------
    @Query("""
           SELECT c.idEmpleado.id, c.idEmpleado.nombreEmpleado, c.idEmpleado.apellidosEmpleado, COUNT(c)
           FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
             AND c.estadoCita <> org.victorino_style.entity.enums.EstadoCita.CANCELADA_CLIENTE
             AND c.estadoCita <> org.victorino_style.entity.enums.EstadoCita.CANCELADA_PELUQUERIA
           GROUP BY c.idEmpleado.id, c.idEmpleado.nombreEmpleado, c.idEmpleado.apellidosEmpleado
           ORDER BY COUNT(c) DESC
           """)
    List<Object[]> rankingEmpleados(
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta
    );

    // ------------------------------------------------------------------------
    // Distribución de citas por hora de inicio (HH:00).
    // FUNCTION('HOUR', ...) devuelve el entero 0-23.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT FUNCTION('HOUR', c.horaInicioCita), COUNT(c)
           FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
           GROUP BY FUNCTION('HOUR', c.horaInicioCita)
           ORDER BY FUNCTION('HOUR', c.horaInicioCita) ASC
           """)
    List<Object[]> distribucionPorFranjaHoraria(
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta
    );

    // ------------------------------------------------------------------------
    // Distribución de citas por día de la semana.
    // FUNCTION('DAYOFWEEK', ...) devuelve 1=Domingo … 7=Sábado en MySQL.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT FUNCTION('DAYOFWEEK', c.fechaCita), COUNT(c)
           FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
           GROUP BY FUNCTION('DAYOFWEEK', c.fechaCita)
           ORDER BY FUNCTION('DAYOFWEEK', c.fechaCita) ASC
           """)
    List<Object[]> distribucionPorDiaSemana(
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta
    );

    // ------------------------------------------------------------------------
    // Avisos de clientes con MUCHAS cancelaciones recientes (CANCELADA_CLIENTE).
    // Devuelve filas con (idCliente, nombreCliente, apellidosCliente, correo, count).
    // ------------------------------------------------------------------------
    @Query("""
           SELECT c.idCliente.id,
                  c.idCliente.nombreCliente,
                  c.idCliente.apellidosCliente,
                  c.idCliente.usuario.correoUsuario,
                  COUNT(c)
           FROM Cita c
           WHERE c.estadoCita = org.victorino_style.entity.enums.EstadoCita.CANCELADA_CLIENTE
             AND c.fechaCita >= :fechaCorte
             AND c.idCliente IS NOT NULL
           GROUP BY c.idCliente.id,
                    c.idCliente.nombreCliente,
                    c.idCliente.apellidosCliente,
                    c.idCliente.usuario.correoUsuario
           HAVING COUNT(c) > :umbral
           ORDER BY COUNT(c) DESC
           """)
    List<Object[]> avisosCancelacionesFrecuentes(
            @Param("fechaCorte") LocalDate fechaCorte,
            @Param("umbral") long umbral
    );

    // ------------------------------------------------------------------------
    // Comprueba si una franja [horaInicio, horaFin) solapa con alguna cita activa
    // del empleado en la fecha indicada. Usado por walk-in para validar.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT COUNT(c) FROM Cita c
           WHERE c.idEmpleado.id = :idEmpleado
             AND c.fechaCita = :fecha
             AND c.estadoCita IN (
                 org.victorino_style.entity.enums.EstadoCita.CONFIRMADA,
                 org.victorino_style.entity.enums.EstadoCita.EN_PROCESO
             )
             AND NOT (c.horaFinCita <= :horaInicio OR c.horaInicioCita >= :horaFin)
           """)
    long contarSolapes(
            @Param("idEmpleado") Long idEmpleado,
            @Param("fecha") LocalDate fecha,
            @Param("horaInicio") LocalTime horaInicio,
            @Param("horaFin") LocalTime horaFin
    );

    // ------------------------------------------------------------------------
    // Queries para NotificacionPendienteScheduler.
    // Detectan citas cuyo estado cambió directamente en la BD y que aún no tienen
    // la notificación correspondiente.
    // ------------------------------------------------------------------------

    @Query("""
           SELECT c FROM Cita c
           JOIN FETCH c.idEmpleado e
           JOIN FETCH e.usuario
           WHERE c.estadoCita = org.victorino_style.entity.enums.EstadoCita.CANCELADA_CLIENTE
             AND c.fechaCita >= :corte
             AND NOT EXISTS (
                 SELECT n FROM Notificacion n
                 WHERE n.idCitaRelacionadaNotificacion.id = c.id
                   AND n.tipoNotificacion = 'CANCELACION_CLIENTE'
                   AND n.idDestinatarioNotificacion.id = e.usuario.id
             )
           """)
    List<Cita> findCanceladasClienteSinNotifEmpleado(@Param("corte") LocalDate corte);

    @Query("""
           SELECT c FROM Cita c
           JOIN FETCH c.idCliente cl
           JOIN FETCH cl.usuario
           WHERE c.estadoCita = org.victorino_style.entity.enums.EstadoCita.CANCELADA_PELUQUERIA
             AND c.idCliente IS NOT NULL
             AND c.fechaCita >= :corte
             AND NOT EXISTS (
                 SELECT n FROM Notificacion n
                 WHERE n.idCitaRelacionadaNotificacion.id = c.id
                   AND n.tipoNotificacion = 'CANCELACION_PELUQUERIA'
                   AND n.idDestinatarioNotificacion.id = cl.usuario.id
             )
           """)
    List<Cita> findCanceladasPeluqueriaSinNotifCliente(@Param("corte") LocalDate corte);

    @Query("""
           SELECT c FROM Cita c
           JOIN FETCH c.idCliente cl
           JOIN FETCH cl.usuario
           JOIN FETCH c.idEmpleado
           WHERE c.estadoCita IN (
               org.victorino_style.entity.enums.EstadoCita.CONFIRMADA,
               org.victorino_style.entity.enums.EstadoCita.EN_PROCESO,
               org.victorino_style.entity.enums.EstadoCita.COMPLETADA
           )
             AND c.idCliente IS NOT NULL
             AND c.fechaCita >= :corte
             AND NOT EXISTS (
                 SELECT n FROM Notificacion n
                 WHERE n.idCitaRelacionadaNotificacion.id = c.id
                   AND n.tipoNotificacion = 'CONFIRMACION_RESERVA'
                   AND n.idDestinatarioNotificacion.id = cl.usuario.id
             )
           """)
    List<Cita> findConfirmadasClienteSinNotifReserva(@Param("corte") LocalDate corte);

    // ------------------------------------------------------------------------
    // Queries para el módulo CLIENTE.
    // ------------------------------------------------------------------------

    @Query("""
           SELECT c FROM Cita c
           WHERE c.idCliente.id = :idCliente
             AND c.fechaCita BETWEEN :desde AND :hasta
             AND c.estadoCita IN (
                 org.victorino_style.entity.enums.EstadoCita.CONFIRMADA,
                 org.victorino_style.entity.enums.EstadoCita.EN_PROCESO
             )
           ORDER BY c.fechaCita ASC, c.horaInicioCita ASC
           """)
    List<Cita> findActivasClienteEnRango(
            @Param("idCliente") Long idCliente,
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta
    );

    @Query("""
           SELECT c FROM Cita c
           WHERE c.idCliente.id = :idCliente
             AND c.idServicio.id = :idServicio
             AND c.estadoCita IN (
                 org.victorino_style.entity.enums.EstadoCita.CONFIRMADA,
                 org.victorino_style.entity.enums.EstadoCita.EN_PROCESO
             )
           ORDER BY c.fechaCita ASC, c.horaInicioCita ASC
           """)
    List<Cita> findActivasClienteServicio(
            @Param("idCliente") Long idCliente,
            @Param("idServicio") Long idServicio
    );

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
           SELECT c FROM Cita c
           WHERE c.idEmpleado.id = :idEmpleado
             AND c.fechaCita = :fecha
             AND c.estadoCita IN (
                 org.victorino_style.entity.enums.EstadoCita.CONFIRMADA,
                 org.victorino_style.entity.enums.EstadoCita.EN_PROCESO
             )
           """)
    List<Cita> findActivasEmpleadoFechaParaActualizar(
            @Param("idEmpleado") Long idEmpleado,
            @Param("fecha") LocalDate fecha
    );

    @Query("""
           SELECT c FROM Cita c
           WHERE c.idEmpleado.id = :idEmpleado
             AND c.fechaCita = :fecha
             AND c.estadoCita IN (
                 org.victorino_style.entity.enums.EstadoCita.CONFIRMADA,
                 org.victorino_style.entity.enums.EstadoCita.EN_PROCESO
             )
           ORDER BY c.horaInicioCita ASC
           """)
    List<Cita> findActivasEmpleadoFecha(
            @Param("idEmpleado") Long idEmpleado,
            @Param("fecha") LocalDate fecha
    );

    @Query("""
           SELECT c FROM Cita c
           WHERE c.idCliente.id = :idCliente
             AND (:estado IS NULL OR c.estadoCita = :estado)
           ORDER BY c.fechaCita DESC, c.horaInicioCita DESC
           """)
    List<Cita> findCitasCliente(
            @Param("idCliente") Long idCliente,
            @Param("estado") EstadoCita estado
    );

    @Query("""
           SELECT c FROM Cita c
           WHERE c.idCliente.id = :idCliente
             AND c.estadoCita = org.victorino_style.entity.enums.EstadoCita.CONFIRMADA
             AND (c.fechaCita > :hoy
                  OR (c.fechaCita = :hoy AND c.horaInicioCita > :horaActual))
           """)
    List<Cita> findFuturasConfirmadasCliente(
            @Param("idCliente") Long idCliente,
            @Param("hoy") LocalDate hoy,
            @Param("horaActual") LocalTime horaActual
    );

    // ------------------------------------------------------------------------
    // Citas en una ventana temporal [fechaDesde/horaDesde, fechaHasta/horaHasta)
    // con un estado concreto. Lo usa RecordatorioScheduler.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT c FROM Cita c
             JOIN FETCH c.idCliente cl
             JOIN FETCH cl.usuario
             JOIN FETCH c.idEmpleado
           WHERE c.estadoCita = :estado
             AND (
               (c.fechaCita = :fechaDesde AND c.fechaCita = :fechaHasta
                AND c.horaInicioCita >= :horaDesde AND c.horaInicioCita < :horaHasta)
               OR
               (c.fechaCita = :fechaDesde AND c.fechaCita <> :fechaHasta
                AND c.horaInicioCita >= :horaDesde)
               OR
               (c.fechaCita = :fechaHasta AND c.fechaCita <> :fechaDesde
                AND c.horaInicioCita < :horaHasta)
             )
             AND NOT EXISTS (
               SELECT n FROM Notificacion n
               WHERE n.idCitaRelacionadaNotificacion.id = c.id
                 AND n.tipoNotificacion = 'RECORDATORIO_24H'
                 AND n.idDestinatarioNotificacion.id = cl.usuario.id
             )
           """)
    List<Cita> findCitasEnVentanaRecordatorio(
            @Param("fechaDesde") LocalDate fechaDesde,
            @Param("horaDesde") LocalTime horaDesde,
            @Param("fechaHasta") LocalDate fechaHasta,
            @Param("horaHasta") LocalTime horaHasta,
            @Param("estado") EstadoCita estado
    );

    // ------------------------------------------------------------------------
    // Transiciones automáticas de estado (CompletadaScheduler).
    //
    // Las citas avanzan automáticamente con el reloj:
    //   CONFIRMADA  → EN_PROCESO   cuando llega hora_inicio
    //   EN_PROCESO  → COMPLETADA   cuando pasa hora_fin
    //
    // Los bulk UPDATE saltan el control de @Version, por lo que incrementamos
    // version_cita manualmente para que cualquier transacción concurrente que
    // tenga la cita cargada falle con OptimisticLockException al guardar.
    // ------------------------------------------------------------------------

    // Pasa a COMPLETADA cualquier cita CONFIRMADA o EN_PROCESO cuyo hora_fin
    // ya haya quedado en el pasado. El scheduler la invoca antes que la de
    // EN_PROCESO para evitar doble salto en una misma ejecución.
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
           UPDATE Cita c
              SET c.estadoCita = org.victorino_style.entity.enums.EstadoCita.COMPLETADA,
                  c.fechaModificacionCita = :ahora,
                  c.versionCita = c.versionCita + 1
            WHERE c.estadoCita IN (
                    org.victorino_style.entity.enums.EstadoCita.CONFIRMADA,
                    org.victorino_style.entity.enums.EstadoCita.EN_PROCESO
                  )
              AND (
                    c.fechaCita < :hoy
                    OR (c.fechaCita = :hoy AND c.horaFinCita <= :horaActual)
                  )
           """)
    int marcarComoCompletadas(
            @Param("hoy") LocalDate hoy,
            @Param("horaActual") LocalTime horaActual,
            @Param("ahora") Instant ahora
    );

    // Pasa a EN_PROCESO las citas CONFIRMADA cuyo hora_inicio ya pasó pero
    // hora_fin sigue en el futuro (es decir, están ahora mismo en curso).
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
           UPDATE Cita c
              SET c.estadoCita = org.victorino_style.entity.enums.EstadoCita.EN_PROCESO,
                  c.fechaModificacionCita = :ahora,
                  c.versionCita = c.versionCita + 1
            WHERE c.estadoCita = org.victorino_style.entity.enums.EstadoCita.CONFIRMADA
              AND c.fechaCita = :hoy
              AND c.horaInicioCita <= :horaActual
              AND c.horaFinCita > :horaActual
           """)
    int marcarComoEnProceso(
            @Param("hoy") LocalDate hoy,
            @Param("horaActual") LocalTime horaActual,
            @Param("ahora") Instant ahora
    );
}