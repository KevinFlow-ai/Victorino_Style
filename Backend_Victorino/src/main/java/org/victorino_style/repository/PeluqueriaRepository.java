package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Peluqueria;

import java.util.Optional;

// Repositorio de la fila singleton `peluqueria`. Hay una y solo una.
public interface PeluqueriaRepository extends JpaRepository<Peluqueria, Long> {

    // Devuelve la primera (y única) fila de la tabla. Si no existe, los servicios
    // lanzan PeluqueriaNoConfiguradaException (HTTP 500).
    Optional<Peluqueria> findFirstByOrderByIdAsc();
}


        // ------------------------------------------------------------------------
        // ¿QUÉ ES UN SINGLETON EN ESTE CONTEXTO?
        // ------------------------------------------------------------------------
        // En programación, "singleton" suele significar que solo existe UNA instancia
        // de algo. Aquí se aplica el concepto a nivel de BASE DE DATOS:
        //
        //   → La tabla `peluqueria` tiene una única fila.
        //   → Esa fila contiene la configuración global del negocio:
        //       - nombre de la peluquería
        //       - dirección
        //       - teléfono
        //       - horarios generales
        //       - políticas
        //       - etc.
        //
        // Es decir, no hay varias peluquerías. Solo existe una configuración global.
        //
        // Por eso este repositorio no necesita métodos complejos: solo debe
        // recuperar la única fila existente.
        //
        // ------------------------------------------------------------------------
        // findFirstByOrderByIdAsc()
        // ------------------------------------------------------------------------
        // Este métodoo devuelve la PRIMERA fila de la tabla ordenada por ID ascendente.
        // Como solo existe una fila, siempre devuelve esa.
        //
        // Spring Data JPA interpreta el nombre del métoddo y genera la consulta:
        //
        //   SELECT p
        //   FROM Peluqueria p
        //   ORDER BY p.id ASC
        //   LIMIT 1
        //
        // ¿Por qué Optional?
        //   → Porque podría no existir ninguna fila si la BD está recién creada.
        //     En ese caso, los servicios lanzan PeluqueriaNoConfiguradaException.
        //
        // ¿Para qué sirve?
        //   → Para obtener la configuración global de la peluquería.
        //   → Todos los servicios que dependen de datos globales usan este métoodo.
        //
        // Ejemplo:
        //   - Si la tabla tiene 1 fila → devuelve Optional<Peluqueria>.
        //   - Si está vacía → Optional.empty() y el servicio lanza excepción.
        //
        // ----------------------------------------------------------------