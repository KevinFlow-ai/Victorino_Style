package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Festivo;

import java.time.LocalDate;
import java.util.List;

// Repositorio de festivos puntuales (días en los que la peluquería NO abre).
public interface FestivoRepository extends JpaRepository<Festivo, Long> {

    // Lista todos los festivos ordenados cronológicamente. Lo usa el panel admin y
    // el flujo de reserva del cliente (para pintar el calendario en gris).
    List<Festivo> findAllByOrderByFechaFestivoAsc();

    // Lista los festivos a partir de una fecha dada. Útil para el calendario futuro.
    List<Festivo> findByFechaFestivoGreaterThanEqualOrderByFechaFestivoAsc(LocalDate desde);

    // Comprueba si ya existe un festivo en una fecha concreta. Usa la UNIQUE de fecha_festivo.
    boolean existsByFechaFestivo(LocalDate fechaFestivo);
}
