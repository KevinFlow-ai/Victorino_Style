package org.victorino_style.repository;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.enums.EstadoCita;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

// Repositorio de la entidad Cita. Concentra todas las consultas de agenda y métricas.
// Las consultas de métricas usan @Query JPQL con agregaciones para que NO se carguen
// entidades en memoria.
public interface CitaRepository extends JpaRepository<Cita, Long> {



    @Lock(LockModeType.PESSIMISTIC_WRITE)
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
            @Param("horaActual") java.time.LocalTime horaActual


            // ------------------------------------------------------------------------
            // Citas futuras de un empleado en estado CONFIRMADA, con LOCK PESIMISTA.
            // El servicio de cancelación masiva lo usa para evitar que dos transacciones
            // intenten cancelar la misma cita simultáneamente.
            // ------------------------------------------------------------------------
            // Este métodoo busca las citas FUTURAS de un empleado que estén en estado CONFIRMADA.
            // Pero lo importante aquí es el uso de @Lock(PESSIMISTIC_WRITE).

            // ------------------------------------------------------------------------
            // ¿QUÉ ES UN LOCK PESIMISTA?
            // ------------------------------------------------------------------------
            // Es un mecanismo de bloqueo a nivel de base de datos.
            //
            // Cuando una transacción ejecuta esta consulta con PESSIMISTIC_WRITE:
            //
            //   → La BD BLOQUEA las filas seleccionadas.
            //   → Ninguna otra transacción puede leerlas para escribirlas.
            //   → Evita que dos procesos modifiquen la misma cita al mismo tiempo.
            //
            // Es decir: "si yo voy a modificar estas citas, NADIE más puede tocarlas
            // hasta que yo termine". Es una forma de garantizar consistencia en
            // operaciones críticas.
            //
            // ¿Por qué se usa aquí?
            // Porque el servicio de CANCELACIÓN MASIVA podría ejecutarse en paralelo
            // (por ejemplo, dos administradores cancelando citas del mismo empleado).
            //
            // Sin este lock:
            //   - Dos transacciones podrían leer las mismas citas.
            //   - Ambas intentarían cancelarlas.
            //   - Podrías tener inconsistencias o errores de concurrencia.
            //
            // Con el lock pesimista:
            //   - La primera transacción que entra BLOQUEA las citas.
            //   - La segunda debe esperar a que la primera termine.
            //   - Se evita cancelar dos veces la misma cita.
            //
            // Es una estrategia de "mejor prevenir que curar".
            // ------------------------------------------------------------------------
    );






    // ------------------------------------------------------------------------
    // Carga una cita con LOCK pesimista por id. Útil cuando ya conoces el id y
    // quieres bloquear esa fila concreta antes de cancelarla individualmente.
    // ------------------------------------------------------------------------
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM Cita c WHERE c.id = :id")
    java.util.Optional<Cita> findByIdParaActualizar(@Param("id") Long id);





    // ------------------------------------------------------------------------
    // Citas de un empleado en una franja [desde, hasta] (sin filtro de estado).
    // Lo usa la agenda global y el cálculo de huecos disponibles del walk-in.
    // ------------------------------------------------------------------------
    List<Cita> findByIdEmpleado_IdAndFechaCitaBetweenOrderByFechaCitaAscHoraInicioCitaAsc(
            Long idEmpleado, LocalDate desde, LocalDate hasta);







    // ------------------------------------------------------------------------
    // Agenda global con filtros opcionales (todos pueden ser null salvo el rango).
    // Si idEmpleado o estado son null, no se filtra por ellos.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT c FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
             AND (:idEmpleado IS NULL OR c.idEmpleado.id = :idEmpleado)
             AND (:estado     IS NULL OR c.estadoCita    = :estado)
           ORDER BY c.fechaCita ASC, c.horaInicioCita ASC
           """)
    List<Cita> buscarAgenda(@Param("desde") LocalDate desde,
                            @Param("hasta") LocalDate hasta,
                            @Param("idEmpleado") Long idEmpleado,
                            @Param("estado") EstadoCita estado);








    // ------------------------------------------------------------------------
    // Historial completo de un cliente registrado, ordenado descendente.
    // ------------------------------------------------------------------------
    List<Cita> findByIdCliente_IdOrderByFechaCitaDescHoraInicioCitaDesc(Long idCliente);






    // ------------------------------------------------------------------------
    // Cuenta de citas en estado concreto en un rango de fechas. Usado en métricas.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT COUNT(c) FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
             AND c.estadoCita = :estado
           """)
    long contarPorEstado(@Param("desde") LocalDate desde,
                         @Param("hasta") LocalDate hasta,
                         @Param("estado") EstadoCita estado);







    // ------------------------------------------------------------------------
    // Total de citas en un rango de fechas (cualquier estado).
    // ------------------------------------------------------------------------
    @Query("""
           SELECT COUNT(c) FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
           """)
    long contarTotal(@Param("desde") LocalDate desde, @Param("hasta") LocalDate hasta);







    // ------------------------------------------------------------------------
    // Servicio más solicitado en un rango. Devuelve un Object[] con (idServicio, nombre, count).
    // El servicio de métricas se queda con la primera fila.
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
    List<Object[]> rankingServicios(@Param("desde") LocalDate desde,
                                    @Param("hasta") LocalDate hasta);






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
    List<Object[]> rankingEmpleados(@Param("desde") LocalDate desde,
                                    @Param("hasta") LocalDate hasta);









    // ------------------------------------------------------------------------
    // Distribución de citas por hora de inicio (HH:00). Útil para gráfica de franjas.
    // FUNCTION('HOUR', ...) devuelve el entero 0-23.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT FUNCTION('HOUR', c.horaInicioCita), COUNT(c)
           FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
           GROUP BY FUNCTION('HOUR', c.horaInicioCita)
           ORDER BY FUNCTION('HOUR', c.horaInicioCita) ASC
           """)
    List<Object[]> distribucionPorFranjaHoraria(@Param("desde") LocalDate desde,
                                                @Param("hasta") LocalDate hasta);







    // ------------------------------------------------------------------------
    // Distribución de citas por día de la semana. FUNCTION('DAYOFWEEK', ...)
    // devuelve 1=Domingo … 7=Sábado en MySQL. El servicio lo traduce a DayOfWeek.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT FUNCTION('DAYOFWEEK', c.fechaCita), COUNT(c)
           FROM Cita c
           WHERE c.fechaCita BETWEEN :desde AND :hasta
           GROUP BY FUNCTION('DAYOFWEEK', c.fechaCita)
           ORDER BY FUNCTION('DAYOFWEEK', c.fechaCita) ASC
           """)
    // Este métodoo calcula cuántas citas hay por cada día de la semana
// dentro de un rango de fechas. Devuelve una lista de Object[] donde:
//
//   - Object[0] = número del día de la semana (1=Domingo … 7=Sábado en MySQL)
//   - Object[1] = cantidad de citas en ese día
//
// ------------------------------------------------------------------------
// ¿QUÉ HACE FUNCTION('DAYOFWEEK', c.fechaCita)?
// ------------------------------------------------------------------------
// JPA no tiene una función estándar para obtener el día de la semana,
// así que se usa FUNCTION() para llamar directamente a la función nativa
// de la base de datos.
//
// En MySQL, DAYOFWEEK(fecha) devuelve:
//   1 = Domingo
//   2 = Lunes
//   3 = Martes
//   4 = Miércoles
//   5 = Jueves
//   6 = Viernes
//   7 = Sábado
//
// El servicio que usa este repositorio luego traduce ese número
// a java.time.DayOfWeek, que usa otro orden (MONDAY=1 … SUNDAY=7).
//
// ------------------------------------------------------------------------
// ¿QUÉ HACE LA CONSULTA COMPLETA?
// ------------------------------------------------------------------------
// 1. Selecciona el día de la semana de cada cita.
// 2. Cuenta cuántas citas hay en ese día.
// 3. Filtra solo las citas entre :desde y :hasta.
// 4. Agrupa por día de la semana.
// 5. Ordena los resultados de Domingo (1) a Sábado (7).
//
// Esto permite construir estadísticas como:
//   - "¿Qué día de la semana se reservan más citas?"
//   - "¿Cómo se distribuyen las citas a lo largo de la semana?"
// -------------------------------------------------------------------
    List<Object[]> distribucionPorDiaSemana(@Param("desde") LocalDate desde,
                                            @Param("hasta") LocalDate hasta);








    // ------------------------------------------------------------------------
    // Avisos de clientes con MUCHAS cancelaciones recientes (CANCELADA_CLIENTE).
    // Se usa en el endpoint de avisos del admin: HAVING COUNT > umbral.
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
    List<Object[]> avisosCancelacionesFrecuentes(@Param("fechaCorte") LocalDate fechaCorte,
                                                 @Param("umbral") long umbral);




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
    long contarSolapes(@Param("idEmpleado") Long idEmpleado,
                       @Param("fecha") LocalDate fecha,
                       @Param("horaInicio") java.time.LocalTime horaInicio,
                       @Param("horaFin")    java.time.LocalTime horaFin);

    // ------------------------------------------------------------------------
    // Puse citas en una ventana temporal [fechaDesde/horaDesde, fechaHasta/horaHasta)
    // con un estado concreto. Lo usa RecordatorioScheduler para buscar las citas
    // que están a ~24 h de distancia y enviar el recordatorio push.
    // También puse para soportar ventanas que cruzan medianoche (fechaDesde != fechaHasta).
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
           """)
    List<Cita> findCitasEnVentanaRecordatorio(
            @Param("fechaDesde") LocalDate fechaDesde,
            @Param("horaDesde")  LocalTime horaDesde,
            @Param("fechaHasta") LocalDate fechaHasta,
            @Param("horaHasta")  LocalTime horaHasta,
            @Param("estado")     EstadoCita estado);
}



// ------------------------------------------------------------------------
// ¿QUÉ ES UN LOCK PESIMISTA?
// ------------------------------------------------------------------------
// Es un mecanismo de bloqueo a nivel de base de datos.
//
// Cuando una transacción ejecuta esta consulta con PESSIMISTIC_WRITE:
//
//   → La BD BLOQUEA las filas seleccionadas.
//   → Ninguna otra transacción puede leerlas para escribirlas.
//   → Evita que dos procesos modifiquen la misma cita al mismo tiempo.
//
// Es decir: "si yo voy a modificar estas citas, NADIE más puede tocarlas
// hasta que yo termine". Es una forma de garantizar consistencia en
// operaciones críticas.
//
// ¿Por qué se usa aquí?
// Porque el servicio de CANCELACIÓN MASIVA podría ejecutarse en paralelo
// (por ejemplo, dos administradores cancelando citas del mismo empleado).
//
// Sin este lock:
//   - Dos transacciones podrían leer las mismas citas.
//   - Ambas intentarían cancelarlas.
//   - Podrías tener inconsistencias o errores de concurrencia.
//
// Con el lock pesimista:
//   - La primera transacción que entra BLOQUEA las citas.
//   - La segunda debe esperar a que la primera termine.
//   - Se evita cancelar dos veces la misma cita.
//
// Es una estrategia de "mejor prevenir que curar".
// ------------------------------------------------------------------------
