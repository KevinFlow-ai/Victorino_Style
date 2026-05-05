package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.HorarioEmpleado;

import java.util.Optional;

// Repositorio del descanso fijo diario por empleado (relación 1:1 con `empleado`).
public interface HorarioEmpleadoRepository extends JpaRepository<HorarioEmpleado, Long> {

    // Busca el descanso del empleado por su id. Devuelve Optional.empty si todavía no se ha configurado.
    Optional<HorarioEmpleado> findByIdEmpleado_Id(Long idEmpleado);
}





        // ------------------------------------------------------------------------
        // findByIdEmpleado_Id(Long idEmpleado)
        // ------------------------------------------------------------------------
        // Este métodDo busca el "HorarioEmpleado" asociado a un empleado concreto.
        //
        // ¿Qué es HorarioEmpleado?
        //   → Normalmente representa el horario laboral del empleado:
        //       - su hora de entrada
        //       - su hora de salida
        //       - su descanso
        //       - sus días libres
        //   → En este caso, el comentario indica que se usa para obtener
        //     el "descanso" del empleado.
        //
        // ¿Qué hace exactamente findByIdEmpleado_Id?
        //   → Spring Data JPA interpreta el nombre del métoddo y genera la consulta.
        //   → Navega por la relación:
        //         HorarioEmpleado → idEmpleado → id
        //     y filtra por ese ID.
        //
        // Es equivalente a escribir:
        //   SELECT h FROM HorarioEmpleado h
        //   WHERE h.idEmpleado.id = :idEmpleado
        //
        // ¿Por qué devuelve Optional?
        //   → Porque un empleado puede NO tener configurado su horario todavía.
        //     En ese caso, Optional.empty() evita NullPointerException.
        //
        // ¿Para qué sirve?
        //   → Para que el sistema pueda saber si un empleado tiene descanso configurado
        //     antes de calcular citas, disponibilidad, etc.
        //
        // Ejemplo:
        //   - Si el empleado 7 tiene un horario → devuelve Optional<HorarioEmpleado>.
        //   - Si no tiene horario → devuelve Optional.empty().
        // ------------------------------------------------------------------------