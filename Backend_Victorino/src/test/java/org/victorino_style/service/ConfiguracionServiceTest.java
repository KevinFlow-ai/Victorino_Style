package org.victorino_style.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.victorino_style.dto.admin.CierreAnualRequest;
import org.victorino_style.dto.admin.DescansoRequest;
import org.victorino_style.dto.admin.FestivoRequest;
import org.victorino_style.dto.admin.HorarioPeluqueriaRequest;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Festivo;
import org.victorino_style.entity.HorarioEmpleado;
import org.victorino_style.entity.Peluqueria;
import org.victorino_style.entity.enums.TipoFestivo;
import org.victorino_style.exception.EmpleadoNoEncontradoException;
import org.victorino_style.exception.FestivoDuplicadoException;
import org.victorino_style.exception.PeluqueriaNoConfiguradaException;
import org.victorino_style.mapper.FestivoMapper;
import org.victorino_style.mapper.HorarioMapper;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.FestivoRepository;
import org.victorino_style.repository.HorarioEmpleadoRepository;
import org.victorino_style.repository.PeluqueriaRepository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

// Tests del servicio ConfiguracionService.
// Cubren horario semanal, descanso por empleado, festivos y cierre anual.
@ExtendWith(MockitoExtension.class)
class ConfiguracionServiceTest {

    @Mock private PeluqueriaRepository peluqueriaRepository;
    @Mock private HorarioEmpleadoRepository horarioEmpleadoRepository;
    @Mock private EmpleadoRepository empleadoRepository;
    @Mock private FestivoRepository festivoRepository;
    @Mock private HorarioMapper horarioMapper;
    @Mock private FestivoMapper festivoMapper;
    @Mock private AuditoriaService auditoriaService;

    @InjectMocks
    private ConfiguracionService configuracionService;

    private Peluqueria peluqueriaFalsa;
    private Empleado empleadoFalso;

    @BeforeEach
    void preparar() {
        peluqueriaFalsa = new Peluqueria();
        peluqueriaFalsa.setId(1L);
        peluqueriaFalsa.setNombrePeluqueria("Victorino Style");
        peluqueriaFalsa.setAperturaLunes(LocalTime.of(10, 0));
        peluqueriaFalsa.setCierreLunes(LocalTime.of(20, 0));

        empleadoFalso = new Empleado();
        empleadoFalso.setId(7L);
        empleadoFalso.setNombreEmpleado("Vito");
        empleadoFalso.setApellidosEmpleado("Corleone");
    }

    // ============================================================
    //  HORARIO SEMANAL
    // ============================================================

    @Test
    @DisplayName("obtenerHorario: peluquería no configurada → 500")
    void obtenerHorarioPeluqueriaNoConfigurada() {
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.empty());

        assertThatThrownBy(() -> configuracionService.obtenerHorario())
                .isInstanceOf(PeluqueriaNoConfiguradaException.class);
    }

    @Test
    @DisplayName("actualizarHorario: persiste y audita")
    void actualizarHorarioOk() {
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueriaFalsa));
        when(peluqueriaRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        HorarioPeluqueriaRequest dto = new HorarioPeluqueriaRequest(
                LocalTime.of(9, 0), LocalTime.of(19, 0),
                LocalTime.of(9, 0), LocalTime.of(19, 0),
                LocalTime.of(9, 0), LocalTime.of(19, 0),
                LocalTime.of(9, 0), LocalTime.of(19, 0),
                LocalTime.of(9, 0), LocalTime.of(19, 0),
                LocalTime.of(10, 0), LocalTime.of(14, 0),
                null, null);

        configuracionService.actualizarHorario(dto);

        ArgumentCaptor<Peluqueria> captor = ArgumentCaptor.forClass(Peluqueria.class);
        verify(peluqueriaRepository).save(captor.capture());
        assertThat(captor.getValue().getAperturaLunes()).isEqualTo(LocalTime.of(9, 0));
        assertThat(captor.getValue().getCierreSabado()).isEqualTo(LocalTime.of(14, 0));
        assertThat(captor.getValue().getAperturaDomingo()).isNull();
        verify(auditoriaService).registrar(eq("EDITAR_HORARIO"), eq("PELUQUERIA"), any(), anyString());
    }

    // ============================================================
    //  DESCANSO POR EMPLEADO
    // ============================================================

    @Test
    @DisplayName("actualizarDescanso: empleado inexistente lanza 404")
    void actualizarDescansoEmpleadoNoExiste() {
        when(empleadoRepository.findActivoById(99L)).thenReturn(Optional.empty());

        DescansoRequest dto = new DescansoRequest(LocalTime.of(11, 0), 30);

        assertThatThrownBy(() -> configuracionService.actualizarDescanso(99L, dto))
                .isInstanceOf(EmpleadoNoEncontradoException.class);
    }

    @Test
    @DisplayName("actualizarDescanso: crea fila si no existía y audita")
    void actualizarDescansoCrea() {
        when(empleadoRepository.findActivoById(7L)).thenReturn(Optional.of(empleadoFalso));
        when(horarioEmpleadoRepository.findByIdEmpleado_Id(7L)).thenReturn(Optional.empty());
        when(horarioEmpleadoRepository.save(any())).thenAnswer(inv -> {
            HorarioEmpleado he = inv.getArgument(0);
            he.setId(50L);
            return he;
        });

        DescansoRequest dto = new DescansoRequest(LocalTime.of(14, 0), 45);

        configuracionService.actualizarDescanso(7L, dto);

        ArgumentCaptor<HorarioEmpleado> captor = ArgumentCaptor.forClass(HorarioEmpleado.class);
        verify(horarioEmpleadoRepository).save(captor.capture());
        assertThat(captor.getValue().getDescansoInicioHorario()).isEqualTo(LocalTime.of(14, 0));
        assertThat(captor.getValue().getDescansoDuracionHorario()).isEqualTo(45);
        verify(auditoriaService).registrar(eq("EDITAR_DESCANSO"), eq("HORARIO_EMPLEADO"), any(), anyString());
    }

    // ============================================================
    //  FESTIVOS
    // ============================================================

    @Test
    @DisplayName("crearFestivo: fecha duplicada lanza FestivoDuplicadoException")
    void crearFestivoDuplicado() {
        LocalDate fecha = LocalDate.of(2026, 5, 1);
        when(festivoRepository.existsByFechaFestivo(fecha)).thenReturn(true);

        FestivoRequest dto = new FestivoRequest(fecha, "Día del Trabajo", TipoFestivo.NACIONAL);

        assertThatThrownBy(() -> configuracionService.crearFestivo(dto))
                .isInstanceOf(FestivoDuplicadoException.class);

        verify(festivoRepository, never()).save(any());
    }

    @Test
    @DisplayName("crearFestivo ok: persiste y audita")
    void crearFestivoOk() {
        LocalDate fecha = LocalDate.of(2026, 12, 25);
        when(festivoRepository.existsByFechaFestivo(fecha)).thenReturn(false);
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueriaFalsa));
        when(festivoRepository.save(any())).thenAnswer(inv -> {
            Festivo f = inv.getArgument(0);
            f.setId(33L);
            return f;
        });

        FestivoRequest dto = new FestivoRequest(fecha, "Navidad", TipoFestivo.NACIONAL);
        configuracionService.crearFestivo(dto);

        ArgumentCaptor<Festivo> captor = ArgumentCaptor.forClass(Festivo.class);
        verify(festivoRepository).save(captor.capture());
        assertThat(captor.getValue().getFechaFestivo()).isEqualTo(fecha);
        assertThat(captor.getValue().getTipoFestivo()).isEqualTo("NACIONAL");
        verify(auditoriaService).registrar(eq("CREAR_FESTIVO"), eq("FESTIVO"), any(), anyString());
    }

    // ============================================================
    //  CIERRE ANUAL
    // ============================================================

    @Test
    @DisplayName("actualizarCierreAnual: fechas invertidas lanza IllegalArgumentException")
    void cierreAnualFechasInvertidas() {
        CierreAnualRequest dto = new CierreAnualRequest(
                LocalDate.of(2026, 8, 31), LocalDate.of(2026, 8, 1));

        assertThatThrownBy(() -> configuracionService.actualizarCierreAnual(dto))
                .isInstanceOf(IllegalArgumentException.class);

        verify(peluqueriaRepository, never()).save(any());
    }

    @Test
    @DisplayName("actualizarCierreAnual ok: aplica fechas, persiste y audita")
    void cierreAnualOk() {
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueriaFalsa));
        when(peluqueriaRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CierreAnualRequest dto = new CierreAnualRequest(
                LocalDate.of(2026, 8, 1), LocalDate.of(2026, 8, 31));

        configuracionService.actualizarCierreAnual(dto);

        ArgumentCaptor<Peluqueria> captor = ArgumentCaptor.forClass(Peluqueria.class);
        verify(peluqueriaRepository).save(captor.capture());
        assertThat(captor.getValue().getCierreAnualInicio()).isEqualTo(LocalDate.of(2026, 8, 1));
        assertThat(captor.getValue().getCierreAnualFin()).isEqualTo(LocalDate.of(2026, 8, 31));
        verify(auditoriaService).registrar(eq("EDITAR_CIERRE_ANUAL"), eq("PELUQUERIA"), any(), anyString());
    }
}
