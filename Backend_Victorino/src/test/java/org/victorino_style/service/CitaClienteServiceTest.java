package org.victorino_style.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.victorino_style.dto.cliente.CitaClienteResponse;
import org.victorino_style.dto.cliente.ModificarCitaRequest;
import org.victorino_style.dto.cliente.ReservarCitaRequest;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Cliente;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Peluqueria;
import org.victorino_style.entity.Servicio;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.entity.enums.RolUsuario;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.exception.CitaFueraDeAntelacionException;
import org.victorino_style.exception.CitaMismoDiaException;
import org.victorino_style.exception.CitaNoModificableException;
import org.victorino_style.exception.CitaSemanaDuplicadaException;
import org.victorino_style.exception.CitaServicioDuplicadoException;
import org.victorino_style.exception.CitaSolapadaException;
import org.victorino_style.exception.RecursoNoEncontradoException;
import org.victorino_style.mapper.CitaClienteMapper;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.repository.ClienteRepository;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.FestivoRepository;
import org.victorino_style.repository.HorarioEmpleadoRepository;
import org.victorino_style.repository.PeluqueriaRepository;
import org.victorino_style.repository.ServicioRepository;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

// Tests unitarios del servicio CitaClienteService. Cubren las reglas criticas:
//   - antelacion fuera de [hoy, hoy+30]
//   - mismo dia / misma semana / mismo servicio
//   - solape con cita existente
//   - cancelar / modificar (estado != CONFIRMADA, propiedad de la cita)
//   - fallback "Cualquiera" cuando el empleado preferido esta ocupado
@ExtendWith(MockitoExtension.class)
class CitaClienteServiceTest {

    @Mock private CitaRepository citaRepository;
    @Mock private ClienteRepository clienteRepository;
    @Mock private EmpleadoRepository empleadoRepository;
    @Mock private ServicioRepository servicioRepository;
    @Mock private PeluqueriaRepository peluqueriaRepository;
    @Mock private FestivoRepository festivoRepository;
    @Mock private HorarioEmpleadoRepository horarioEmpleadoRepository;
    @Mock private NotificacionService notificacionService;
    @Mock private AuditoriaService auditoriaService;
    @Mock private CitaClienteMapper mapper;

    @InjectMocks
    private CitaClienteService citaClienteService;

    // Mañana es un dia siempre futuro y dentro de los 30 dias.
    private final LocalDate manana = LocalDate.now().plusDays(1);

    private Cliente cliente;
    private Empleado empleado;
    private Servicio servicio;
    private Peluqueria peluqueria;

    @BeforeEach
    void preparar() {
        Usuario uCli = new Usuario();
        uCli.setId(100L);
        uCli.setRolUsuario(RolUsuario.CLIENTE);
        uCli.setCorreoUsuario("cliente@x.com");
        cliente = new Cliente();
        cliente.setId(100L);
        cliente.setUsuario(uCli);
        cliente.setNombreCliente("Marco");
        cliente.setApellidosCliente("Polo");
        cliente.setPushActivaCliente(true);

        Usuario uEmp = new Usuario();
        uEmp.setId(7L);
        uEmp.setRolUsuario(RolUsuario.EMPLEADO);
        uEmp.setCorreoUsuario("vito@v.es");
        empleado = new Empleado();
        empleado.setId(7L);
        empleado.setUsuario(uEmp);
        empleado.setNombreEmpleado("Vito");
        empleado.setApellidosEmpleado("Corleone");
        empleado.setFotoEmpleado("/uploads/empleados/vito.jpg");

        servicio = new Servicio();
        servicio.setId(1L);
        servicio.setNombreServicio("Corte");
        servicio.setDuracionServicio(30);
        servicio.setPrecioServicio(new BigDecimal("15.00"));
        servicio.setFotoServicio("/uploads/servicios/corte.jpg");

        peluqueria = new Peluqueria();
        peluqueria.setId(1L);
        // Apertura amplia de 9:00 a 18:00 todos los dias para simplificar.
        for (DayOfWeek d : DayOfWeek.values()) {
            switch (d) {
                case MONDAY    -> { peluqueria.setAperturaLunes(LocalTime.of(9, 0));     peluqueria.setCierreLunes(LocalTime.of(18, 0)); }
                case TUESDAY   -> { peluqueria.setAperturaMartes(LocalTime.of(9, 0));    peluqueria.setCierreMartes(LocalTime.of(18, 0)); }
                case WEDNESDAY -> { peluqueria.setAperturaMiercoles(LocalTime.of(9, 0)); peluqueria.setCierreMiercoles(LocalTime.of(18, 0)); }
                case THURSDAY  -> { peluqueria.setAperturaJueves(LocalTime.of(9, 0));    peluqueria.setCierreJueves(LocalTime.of(18, 0)); }
                case FRIDAY    -> { peluqueria.setAperturaViernes(LocalTime.of(9, 0));   peluqueria.setCierreViernes(LocalTime.of(18, 0)); }
                case SATURDAY  -> { peluqueria.setAperturaSabado(LocalTime.of(9, 0));    peluqueria.setCierreSabado(LocalTime.of(18, 0)); }
                case SUNDAY    -> { peluqueria.setAperturaDomingo(LocalTime.of(9, 0));   peluqueria.setCierreDomingo(LocalTime.of(18, 0)); }
            }
        }
    }

    // ============================================================
    //  RESERVAR — caminos felices y de error
    // ============================================================

    @Test
    @DisplayName("reservar: fecha en el pasado → 409 CitaFueraDeAntelacion")
    void reservarFechaPasada() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L)).thenReturn(Optional.of(servicio));

        ReservarCitaRequest dto = new ReservarCitaRequest(
                1L, 7L, LocalDate.now().minusDays(1), LocalTime.of(10, 0), null, false);

        assertThatThrownBy(() -> citaClienteService.reservar(100L, dto))
                .isInstanceOf(CitaFueraDeAntelacionException.class);
        verify(citaRepository, never()).save(any());
    }

    @Test
    @DisplayName("reservar: fecha > hoy+30 → 409 CitaFueraDeAntelacion")
    void reservarFechaTooFuturo() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L)).thenReturn(Optional.of(servicio));

        ReservarCitaRequest dto = new ReservarCitaRequest(
                1L, 7L, LocalDate.now().plusDays(31), LocalTime.of(10, 0), null, false);

        assertThatThrownBy(() -> citaClienteService.reservar(100L, dto))
                .isInstanceOf(CitaFueraDeAntelacionException.class);
    }

    @Test
    @DisplayName("reservar: festivo → 409 CitaSolapada (peluqueria cerrada)")
    void reservarFestivo() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L)).thenReturn(Optional.of(servicio));
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(festivoRepository.existsByFechaFestivo(manana)).thenReturn(true);

        ReservarCitaRequest dto = new ReservarCitaRequest(
                1L, 7L, manana, LocalTime.of(10, 0), null, false);

        assertThatThrownBy(() -> citaClienteService.reservar(100L, dto))
                .isInstanceOf(CitaSolapadaException.class)
                .hasMessageContaining("cerrada");
    }

    @Test
    @DisplayName("reservar: cita activa MISMO DIA → 409 CitaMismoDia con detalles")
    void reservarMismoDia() {
        Cita yaExistente = construirCitaActiva(50L, manana, LocalTime.of(15, 0), servicio);

        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L)).thenReturn(Optional.of(servicio));
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(festivoRepository.existsByFechaFestivo(manana)).thenReturn(false);
        // Citas activas en la semana → incluye una en el MISMO dia.
        when(citaRepository.findActivasClienteEnRango(eq(100L), any(), any()))
                .thenReturn(List.of(yaExistente));

        ReservarCitaRequest dto = new ReservarCitaRequest(
                1L, 7L, manana, LocalTime.of(10, 0), null, false);

        assertThatThrownBy(() -> citaClienteService.reservar(100L, dto))
                .isInstanceOf(CitaMismoDiaException.class)
                .satisfies(ex -> {
                    CitaMismoDiaException e = (CitaMismoDiaException) ex;
                    assertThat(e.getDetalle().codigo()).isEqualTo("CITA_MISMO_DIA");
                    assertThat(e.getDetalle().idCitaExistente()).isEqualTo(50L);
                });
    }

    @Test
    @DisplayName("reservar: cita activa MISMA SEMANA (otro dia) → 409 CitaSemanaDuplicada")
    void reservarMismaSemana() {
        // Una cita el dia anterior a 'manana' pero en la misma semana ISO.
        LocalDate otroDiaSemana = manana.minusDays(1);
        // Si manana es lunes, otroDiaSemana cae fuera de la semana → forzar otro setup:
        if (manana.getDayOfWeek() == DayOfWeek.MONDAY) {
            otroDiaSemana = manana.plusDays(1);
        }
        Cita semanaPrevia = construirCitaActiva(60L, otroDiaSemana, LocalTime.of(15, 0), servicio);

        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L)).thenReturn(Optional.of(servicio));
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(festivoRepository.existsByFechaFestivo(manana)).thenReturn(false);
        when(citaRepository.findActivasClienteEnRango(eq(100L), any(), any()))
                .thenReturn(List.of(semanaPrevia));

        ReservarCitaRequest dto = new ReservarCitaRequest(
                1L, 7L, manana, LocalTime.of(10, 0), null, false);

        assertThatThrownBy(() -> citaClienteService.reservar(100L, dto))
                .isInstanceOf(CitaSemanaDuplicadaException.class)
                .satisfies(ex -> {
                    CitaSemanaDuplicadaException e = (CitaSemanaDuplicadaException) ex;
                    assertThat(e.getDetalle().codigo()).isEqualTo("CITA_MISMA_SEMANA");
                });
    }

    @Test
    @DisplayName("reservar: cita activa MISMO SERVICIO en otra semana → 409 CitaServicioDuplicado")
    void reservarMismoServicio() {
        Cita otraConMismoServicio = construirCitaActiva(70L, manana.plusDays(20), LocalTime.of(10, 0), servicio);

        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L)).thenReturn(Optional.of(servicio));
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(festivoRepository.existsByFechaFestivo(manana)).thenReturn(false);
        // Sin citas en la semana, pero si una activa con el mismo servicio.
        when(citaRepository.findActivasClienteEnRango(eq(100L), any(), any())).thenReturn(List.of());
        when(citaRepository.findActivasClienteServicio(100L, 1L)).thenReturn(List.of(otraConMismoServicio));

        ReservarCitaRequest dto = new ReservarCitaRequest(
                1L, 7L, manana, LocalTime.of(10, 0), null, false);

        assertThatThrownBy(() -> citaClienteService.reservar(100L, dto))
                .isInstanceOf(CitaServicioDuplicadoException.class)
                .satisfies(ex -> {
                    CitaServicioDuplicadoException e = (CitaServicioDuplicadoException) ex;
                    assertThat(e.getDetalle().codigo()).isEqualTo("CITA_MISMO_SERVICIO");
                    assertThat(e.getDetalle().nombreServicioExistente()).isEqualTo("Corte");
                });
    }

    @Test
    @DisplayName("reservar OK: persiste, notifica al cliente y al empleado, audita")
    void reservarOk() {
        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L)).thenReturn(Optional.of(servicio));
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(festivoRepository.existsByFechaFestivo(manana)).thenReturn(false);
        when(citaRepository.findActivasClienteEnRango(eq(100L), any(), any())).thenReturn(List.of());
        when(citaRepository.findActivasClienteServicio(100L, 1L)).thenReturn(List.of());
        when(empleadoRepository.findActivoById(7L)).thenReturn(Optional.of(empleado));
        when(horarioEmpleadoRepository.findByIdEmpleado_Id(7L)).thenReturn(Optional.empty());
        when(citaRepository.findActivasEmpleadoFechaParaActualizar(7L, manana)).thenReturn(List.of());
        when(citaRepository.save(any(Cita.class))).thenAnswer(inv -> {
            Cita c = inv.getArgument(0);
            c.setId(999L);
            return c;
        });
        when(mapper.aRespuesta(any(Cita.class))).thenReturn(
                new CitaClienteResponse(999L, manana, LocalTime.of(10, 0), LocalTime.of(10, 30),
                        EstadoCita.CONFIRMADA, null, 7L, "Vito", "Corleone",
                        "/uploads/empleados/vito.jpg", 1L, "Corte", 30,
                        new BigDecimal("15.00"), "/uploads/servicios/corte.jpg"));

        ReservarCitaRequest dto = new ReservarCitaRequest(
                1L, 7L, manana, LocalTime.of(10, 0), "Sin patilla", false);

        CitaClienteResponse resp = citaClienteService.reservar(100L, dto);

        assertThat(resp.idCita()).isEqualTo(999L);
        verify(citaRepository).save(any(Cita.class));
        verify(notificacionService).crearNotificacion(eq(cliente.getUsuario()), any(Cita.class),
                eq(TipoNotificacion.CONFIRMACION_RESERVA), anyString(), anyString());
        verify(notificacionService).crearNotificacion(eq(empleado.getUsuario()), any(Cita.class),
                eq(TipoNotificacion.NUEVA_CITA_EMPLEADO), anyString(), anyString());
        verify(auditoriaService).registrar(eq("CREAR_CITA"), eq("CITA"), eq(999L), anyString());
    }

    @Test
    @DisplayName("reservar: empleado ya ocupado en esa franja → 409 CitaSolapada")
    void reservarSolape() {
        Cita ocupada = new Cita();
        ocupada.setId(800L);
        ocupada.setHoraInicioCita(LocalTime.of(10, 0));
        ocupada.setHoraFinCita(LocalTime.of(10, 30));
        ocupada.setEstadoCita(EstadoCita.CONFIRMADA);

        when(clienteRepository.findById(100L)).thenReturn(Optional.of(cliente));
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L)).thenReturn(Optional.of(servicio));
        when(peluqueriaRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.of(peluqueria));
        when(festivoRepository.existsByFechaFestivo(manana)).thenReturn(false);
        when(citaRepository.findActivasClienteEnRango(eq(100L), any(), any())).thenReturn(List.of());
        when(citaRepository.findActivasClienteServicio(100L, 1L)).thenReturn(List.of());
        when(empleadoRepository.findActivoById(7L)).thenReturn(Optional.of(empleado));
        when(horarioEmpleadoRepository.findByIdEmpleado_Id(7L)).thenReturn(Optional.empty());
        when(citaRepository.findActivasEmpleadoFechaParaActualizar(7L, manana)).thenReturn(List.of(ocupada));

        ReservarCitaRequest dto = new ReservarCitaRequest(
                1L, 7L, manana, LocalTime.of(10, 0), null, false);

        assertThatThrownBy(() -> citaClienteService.reservar(100L, dto))
                .isInstanceOf(CitaSolapadaException.class);
    }

    // ============================================================
    //  MODIFICAR
    // ============================================================

    @Test
    @DisplayName("modificar: cita inexistente → 404")
    void modificarCitaInexistente() {
        when(citaRepository.findByIdParaActualizar(404L)).thenReturn(Optional.empty());

        ModificarCitaRequest dto = new ModificarCitaRequest(
                1L, 7L, manana, LocalTime.of(11, 0), null, false);

        assertThatThrownBy(() -> citaClienteService.modificar(100L, 404L, dto))
                .isInstanceOf(RecursoNoEncontradoException.class);
    }

    @Test
    @DisplayName("modificar: cita de otro cliente → 404 (oculta existencia)")
    void modificarCitaAjena() {
        Cita ajena = construirCitaActiva(200L, manana, LocalTime.of(10, 0), servicio);
        Cliente otro = new Cliente();
        otro.setId(999L);
        ajena.setIdCliente(otro);
        when(citaRepository.findByIdParaActualizar(200L)).thenReturn(Optional.of(ajena));

        ModificarCitaRequest dto = new ModificarCitaRequest(
                1L, 7L, manana, LocalTime.of(11, 0), null, false);

        assertThatThrownBy(() -> citaClienteService.modificar(100L, 200L, dto))
                .isInstanceOf(RecursoNoEncontradoException.class);
    }

    @Test
    @DisplayName("modificar: cita ya COMPLETADA → 409 CitaNoModificable")
    void modificarCitaCompletada() {
        Cita completada = construirCitaActiva(200L, manana, LocalTime.of(10, 0), servicio);
        completada.setEstadoCita(EstadoCita.COMPLETADA);
        when(citaRepository.findByIdParaActualizar(200L)).thenReturn(Optional.of(completada));

        ModificarCitaRequest dto = new ModificarCitaRequest(
                1L, 7L, manana, LocalTime.of(11, 0), null, false);

        assertThatThrownBy(() -> citaClienteService.modificar(100L, 200L, dto))
                .isInstanceOf(CitaNoModificableException.class);
    }

    // ============================================================
    //  CANCELAR
    // ============================================================

    @Test
    @DisplayName("cancelar: cita propia CONFIRMADA → estado CANCELADA_CLIENTE + notifica empleado")
    void cancelarOk() {
        Cita propia = construirCitaActiva(300L, manana, LocalTime.of(10, 0), servicio);
        when(citaRepository.findByIdParaActualizar(300L)).thenReturn(Optional.of(propia));
        when(citaRepository.save(any(Cita.class))).thenAnswer(inv -> inv.getArgument(0));

        citaClienteService.cancelar(100L, 300L);

        assertThat(propia.getEstadoCita()).isEqualTo(EstadoCita.CANCELADA_CLIENTE);
        verify(notificacionService).crearNotificacion(
                eq(empleado.getUsuario()), eq(propia),
                eq(TipoNotificacion.CANCELACION_CLIENTE), anyString(), anyString());
        verify(auditoriaService).registrar(eq("CANCELAR_CITA"), eq("CITA"), eq(300L), anyString());
    }

    @Test
    @DisplayName("cancelar: cita ya cancelada → 409 CitaNoModificable")
    void cancelarYaTerminada() {
        Cita ya = construirCitaActiva(301L, manana, LocalTime.of(10, 0), servicio);
        ya.setEstadoCita(EstadoCita.CANCELADA_CLIENTE);
        when(citaRepository.findByIdParaActualizar(301L)).thenReturn(Optional.of(ya));

        assertThatThrownBy(() -> citaClienteService.cancelar(100L, 301L))
                .isInstanceOf(CitaNoModificableException.class);
    }

    // ============================================================
    //  Helpers
    // ============================================================

    private Cita construirCitaActiva(Long id, LocalDate fecha, LocalTime horaInicio, Servicio servicio) {
        Cita c = new Cita();
        c.setId(id);
        c.setIdCliente(cliente);
        c.setIdEmpleado(empleado);
        c.setIdServicio(servicio);
        c.setFechaCita(fecha);
        c.setHoraInicioCita(horaInicio);
        c.setHoraFinCita(horaInicio.plusMinutes(30));
        c.setEstadoCita(EstadoCita.CONFIRMADA);
        return c;
    }
}
