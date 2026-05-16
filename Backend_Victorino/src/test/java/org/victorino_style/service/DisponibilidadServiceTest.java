package org.victorino_style.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.victorino_style.dto.cliente.HuecoDisponibleResponse;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.HorarioEmpleado;
import org.victorino_style.entity.Peluqueria;
import org.victorino_style.entity.Servicio;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.exception.ServicioNoEncontradoException;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.FestivoRepository;
import org.victorino_style.repository.HorarioEmpleadoRepository;
import org.victorino_style.repository.PeluqueriaRepository;
import org.victorino_style.repository.ServicioRepository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

// Tests unitarios del motor de calculo de huecos disponibles. Cubre:
//   - festivo / cierre anual → lista vacia
//   - dia sin horario configurado → lista vacia
//   - empleado concreto con descanso → huecos correctos
//   - solape con cita existente → ese slot desaparece
//   - modo "Cualquiera" → asigna empleado de menor carga
//   - modo edicion (idCitaExcluir) → la propia cita NO bloquea
@ExtendWith(MockitoExtension.class)
class DisponibilidadServiceTest {

    @Mock private ServicioRepository servicioRepository;
    @Mock private EmpleadoRepository empleadoRepository;
    @Mock private PeluqueriaRepository peluqueriaRepository;
    @Mock private FestivoRepository festivoRepository;
    @Mock private HorarioEmpleadoRepository horarioEmpleadoRepository;
    @Mock private CitaRepository citaRepository;

    @InjectMocks
    private DisponibilidadService disponibilidadService;

    private Servicio servicio30Min;
    private Empleado empleado1;
    private Empleado empleado2;
    private Peluqueria peluqueria;

    // Fecha fija de prueba: viernes 22 de mayo 2026 (cualquier futuro abierto).
    private static final LocalDate FECHA = LocalDate.of(2026, 5, 22);

    @BeforeEach
    void preparar() {
        servicio30Min = new Servicio();
        servicio30Min.setId(1L);
        servicio30Min.setNombreServicio("Corte");
        servicio30Min.setDuracionServicio(30);

        Usuario u1 = new Usuario(); u1.setId(10L);
        empleado1 = new Empleado();
        empleado1.setId(10L);
        empleado1.setUsuario(u1);
        empleado1.setNombreEmpleado("Marco");
        empleado1.setApellidosEmpleado("Polo");
        empleado1.setFotoEmpleado("/uploads/empleados/marco.jpg");

        Usuario u2 = new Usuario(); u2.setId(11L);
        empleado2 = new Empleado();
        empleado2.setId(11L);
        empleado2.setUsuario(u2);
        empleado2.setNombreEmpleado("Elena");
        empleado2.setApellidosEmpleado("Ferrante");
        empleado2.setFotoEmpleado("/uploads/empleados/elena.jpg");

        peluqueria = new Peluqueria();
        peluqueria.setId(1L);
        // Horario viernes 10:00-13:00 → 6 slots de 30 min.
        peluqueria.setAperturaViernes(LocalTime.of(10, 0));
        peluqueria.setCierreViernes(LocalTime.of(13, 0));
    }

    @Test
    @DisplayName("servicio inexistente → 404")
    void servicioNoExiste() {
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> disponibilidadService.calcularHuecos(99L, FECHA, null, null))
                .isInstanceOf(ServicioNoEncontradoException.class);
    }

    @Test
    @DisplayName("dia festivo → lista vacia")
    void festivo() {
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicio30Min));
        when(festivoRepository.existsByFechaFestivo(FECHA)).thenReturn(true);

        List<HuecoDisponibleResponse> huecos = disponibilidadService.calcularHuecos(1L, FECHA, null, null);
        assertThat(huecos).isEmpty();
    }

    @Test
    @DisplayName("dia dentro de cierre anual → lista vacia")
    void cierreAnual() {
        peluqueria.setCierreAnualInicio(LocalDate.of(2026, 5, 1));
        peluqueria.setCierreAnualFin(LocalDate.of(2026, 5, 31));

        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicio30Min));
        when(festivoRepository.existsByFechaFestivo(FECHA)).thenReturn(false);
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));

        List<HuecoDisponibleResponse> huecos = disponibilidadService.calcularHuecos(1L, FECHA, null, null);
        assertThat(huecos).isEmpty();
    }

    @Test
    @DisplayName("dia sin horario (por ejemplo domingo cerrado) → lista vacia")
    void diaSinHorario() {
        // Domingo cerrado: apertura/cierre null.
        peluqueria.setAperturaDomingo(null);
        peluqueria.setCierreDomingo(null);

        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicio30Min));
        when(festivoRepository.existsByFechaFestivo(any())).thenReturn(false);
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));

        LocalDate domingo = LocalDate.of(2026, 5, 24);
        List<HuecoDisponibleResponse> huecos = disponibilidadService.calcularHuecos(1L, domingo, null, null);
        assertThat(huecos).isEmpty();
    }

    @Test
    @DisplayName("empleado concreto sin conflictos: genera 6 huecos de 30 min entre 10:00 y 13:00")
    void empleadoConcretoSinConflictos() {
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicio30Min));
        when(festivoRepository.existsByFechaFestivo(any())).thenReturn(false);
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(empleadoRepository.findActivoById(10L)).thenReturn(Optional.of(empleado1));
        when(horarioEmpleadoRepository.findByIdEmpleado_Id(10L)).thenReturn(Optional.empty());
        when(citaRepository.findActivasEmpleadoFecha(10L, FECHA)).thenReturn(List.of());

        List<HuecoDisponibleResponse> huecos = disponibilidadService.calcularHuecos(1L, FECHA, 10L, null);

        assertThat(huecos).hasSize(6);
        assertThat(huecos.get(0).horaInicio()).isEqualTo(LocalTime.of(10, 0));
        assertThat(huecos.get(0).horaFin()).isEqualTo(LocalTime.of(10, 30));
        assertThat(huecos.get(5).horaInicio()).isEqualTo(LocalTime.of(12, 30));
        assertThat(huecos.get(5).horaFin()).isEqualTo(LocalTime.of(13, 0));
        assertThat(huecos.get(0).idEmpleado()).isEqualTo(10L);
        assertThat(huecos.get(0).nombreEmpleado()).isEqualTo("Marco");
    }

    @Test
    @DisplayName("empleado con descanso 11:00-11:30: ese slot desaparece")
    void empleadoConDescanso() {
        HorarioEmpleado descanso = new HorarioEmpleado();
        descanso.setDescansoInicioHorario(LocalTime.of(11, 0));
        descanso.setDescansoDuracionHorario(30);

        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicio30Min));
        when(festivoRepository.existsByFechaFestivo(any())).thenReturn(false);
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(empleadoRepository.findActivoById(10L)).thenReturn(Optional.of(empleado1));
        when(horarioEmpleadoRepository.findByIdEmpleado_Id(10L)).thenReturn(Optional.of(descanso));
        when(citaRepository.findActivasEmpleadoFecha(10L, FECHA)).thenReturn(List.of());

        List<HuecoDisponibleResponse> huecos = disponibilidadService.calcularHuecos(1L, FECHA, 10L, null);

        // De 6 slots queda fuera 11:00-11:30 → 5 huecos.
        assertThat(huecos).hasSize(5);
        assertThat(huecos.stream().anyMatch(h -> h.horaInicio().equals(LocalTime.of(11, 0)))).isFalse();
    }

    @Test
    @DisplayName("empleado con cita existente 11:30-12:00: ese slot desaparece")
    void empleadoConCitaExistente() {
        Cita citaExistente = new Cita();
        citaExistente.setId(500L);
        citaExistente.setHoraInicioCita(LocalTime.of(11, 30));
        citaExistente.setHoraFinCita(LocalTime.of(12, 0));
        citaExistente.setEstadoCita(EstadoCita.CONFIRMADA);

        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicio30Min));
        when(festivoRepository.existsByFechaFestivo(any())).thenReturn(false);
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(empleadoRepository.findActivoById(10L)).thenReturn(Optional.of(empleado1));
        when(horarioEmpleadoRepository.findByIdEmpleado_Id(10L)).thenReturn(Optional.empty());
        when(citaRepository.findActivasEmpleadoFecha(10L, FECHA)).thenReturn(List.of(citaExistente));

        List<HuecoDisponibleResponse> huecos = disponibilidadService.calcularHuecos(1L, FECHA, 10L, null);

        assertThat(huecos).hasSize(5);
        assertThat(huecos.stream().anyMatch(h -> h.horaInicio().equals(LocalTime.of(11, 30)))).isFalse();
    }

    @Test
    @DisplayName("modo edicion: la propia cita NO bloquea su franja original")
    void modoEdicionExcluyePropia() {
        Cita propia = new Cita();
        propia.setId(777L);
        propia.setHoraInicioCita(LocalTime.of(11, 30));
        propia.setHoraFinCita(LocalTime.of(12, 0));
        propia.setEstadoCita(EstadoCita.CONFIRMADA);

        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicio30Min));
        when(festivoRepository.existsByFechaFestivo(any())).thenReturn(false);
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(empleadoRepository.findActivoById(10L)).thenReturn(Optional.of(empleado1));
        when(horarioEmpleadoRepository.findByIdEmpleado_Id(10L)).thenReturn(Optional.empty());
        when(citaRepository.findActivasEmpleadoFecha(10L, FECHA)).thenReturn(List.of(propia));

        List<HuecoDisponibleResponse> huecos = disponibilidadService.calcularHuecos(1L, FECHA, 10L, 777L);

        // Como excluimos la propia, los 6 huecos deben estar disponibles.
        assertThat(huecos).hasSize(6);
        assertThat(huecos.stream().anyMatch(h -> h.horaInicio().equals(LocalTime.of(11, 30)))).isTrue();
    }

    @Test
    @DisplayName("modo 'Cualquiera': asigna empleado de MENOR carga ese dia")
    void modoCualquieraAsignaMenorCarga() {
        // Empleado1 tiene 2 citas ese dia (cargado), Empleado2 esta libre. Ambos pueden cubrir el slot 10:00-10:30.
        // Asignacion esperada: empleado2 (menor carga).
        Cita carga1 = new Cita();
        carga1.setId(900L);
        carga1.setHoraInicioCita(LocalTime.of(12, 0));
        carga1.setHoraFinCita(LocalTime.of(12, 30));
        carga1.setEstadoCita(EstadoCita.CONFIRMADA);
        Cita carga2 = new Cita();
        carga2.setId(901L);
        carga2.setHoraInicioCita(LocalTime.of(12, 30));
        carga2.setHoraFinCita(LocalTime.of(13, 0));
        carga2.setEstadoCita(EstadoCita.CONFIRMADA);

        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicio30Min));
        when(festivoRepository.existsByFechaFestivo(any())).thenReturn(false);
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(empleadoRepository.findAllActivos()).thenReturn(List.of(empleado1, empleado2));
        when(horarioEmpleadoRepository.findByIdEmpleado_Id(10L)).thenReturn(Optional.empty());
        when(horarioEmpleadoRepository.findByIdEmpleado_Id(11L)).thenReturn(Optional.empty());
        when(citaRepository.findActivasEmpleadoFecha(10L, FECHA)).thenReturn(List.of(carga1, carga2));
        when(citaRepository.findActivasEmpleadoFecha(11L, FECHA)).thenReturn(List.of());

        List<HuecoDisponibleResponse> huecos = disponibilidadService.calcularHuecos(1L, FECHA, null, null);

        // El slot 10:00 lo cubren ambos, pero empleado2 tiene menor carga → debe asignarse a el.
        HuecoDisponibleResponse primero = huecos.get(0);
        assertThat(primero.horaInicio()).isEqualTo(LocalTime.of(10, 0));
        assertThat(primero.idEmpleado()).isEqualTo(11L);
        assertThat(primero.nombreEmpleado()).isEqualTo("Elena");
    }

    @Test
    @DisplayName("modo 'Cualquiera' sin empleados activos → lista vacia")
    void modoCualquieraSinEmpleados() {
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicio30Min));
        when(festivoRepository.existsByFechaFestivo(any())).thenReturn(false);
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(empleadoRepository.findAllActivos()).thenReturn(List.of());

        List<HuecoDisponibleResponse> huecos = disponibilidadService.calcularHuecos(1L, FECHA, null, null);
        assertThat(huecos).isEmpty();
    }
}
