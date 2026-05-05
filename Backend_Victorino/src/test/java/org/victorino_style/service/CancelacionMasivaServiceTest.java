package org.victorino_style.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.victorino_style.dto.admin.CancelacionMasivaResponse;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Cliente;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.exception.EmpleadoNoEncontradoException;
import org.victorino_style.exception.NoCitasFuturasCancelablesException;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.repository.EmpleadoRepository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

// Tests del servicio CancelacionMasivaService.
// Es el flujo más crítico: REQUIRES_NEW por cita, notificación por cliente, deduplicación.
@ExtendWith(MockitoExtension.class)
class CancelacionMasivaServiceTest {

    @Mock private CitaRepository citaRepository;
    @Mock private EmpleadoRepository empleadoRepository;
    @Mock private NotificacionService notificacionService;
    @Mock private AuditoriaService auditoriaService;

    @InjectMocks
    private CancelacionMasivaService cancelacionMasivaService;

    private Empleado empleadoFalso;
    private Usuario usuarioEmpleado;

    @BeforeEach
    void preparar() {
        usuarioEmpleado = new Usuario();
        usuarioEmpleado.setId(7L);
        usuarioEmpleado.setCorreoUsuario("vito@victorino.es");

        empleadoFalso = new Empleado();
        empleadoFalso.setId(7L);
        empleadoFalso.setUsuario(usuarioEmpleado);
        empleadoFalso.setNombreEmpleado("Vito");
        empleadoFalso.setApellidosEmpleado("Corleone");
    }

    @Test
    @DisplayName("empleado inexistente lanza 404")
    void empleadoNoExiste() {
        when(empleadoRepository.findActivoById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> cancelacionMasivaService.cancelarFuturasDelEmpleado(99L))
                .isInstanceOf(EmpleadoNoEncontradoException.class);
    }

    @Test
    @DisplayName("sin citas futuras CONFIRMADAS lanza NoCitasFuturasCancelablesException")
    void sinCitasFuturas() {
        when(empleadoRepository.findActivoById(7L)).thenReturn(Optional.of(empleadoFalso));
        when(citaRepository.findCitasFuturasParaCancelar(eq(7L), any(LocalDate.class), any(LocalTime.class)))
                .thenReturn(List.of());

        assertThatThrownBy(() -> cancelacionMasivaService.cancelarFuturasDelEmpleado(7L))
                .isInstanceOf(NoCitasFuturasCancelablesException.class);

        verify(citaRepository, never()).save(any());
        verify(notificacionService, never()).crearNotificacion(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("ok: cancela 2 citas, notifica a 2 clientes únicos y registra auditoría")
    void cancelaYNotifica() {
        Cita c1 = construirCita(101L, 200L, "Marco");
        Cita c2 = construirCita(102L, 201L, "Elena");

        when(empleadoRepository.findActivoById(7L)).thenReturn(Optional.of(empleadoFalso));
        when(citaRepository.findCitasFuturasParaCancelar(eq(7L), any(), any()))
                .thenReturn(List.of(c1, c2));
        when(citaRepository.findByIdParaActualizar(101L)).thenReturn(Optional.of(c1));
        when(citaRepository.findByIdParaActualizar(102L)).thenReturn(Optional.of(c2));
        when(citaRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CancelacionMasivaResponse resp = cancelacionMasivaService.cancelarFuturasDelEmpleado(7L);

        assertThat(resp.citasCanceladas()).isEqualTo(2);
        assertThat(resp.clientesNotificados()).isEqualTo(2);
        assertThat(resp.citasOmitidas()).isZero();
        assertThat(c1.getEstadoCita()).isEqualTo(EstadoCita.CANCELADA_PELUQUERIA);
        assertThat(c2.getEstadoCita()).isEqualTo(EstadoCita.CANCELADA_PELUQUERIA);

        verify(notificacionService, times(2))
                .crearNotificacion(any(Usuario.class), any(Cita.class),
                        eq(TipoNotificacion.CANCELACION_PELUQUERIA), anyString(), anyString());

        verify(auditoriaService).registrar(eq("CANCELACION_MASIVA"), eq("EMPLEADO"), eq(7L), anyString());
    }

    @Test
    @DisplayName("una cita ya no es CONFIRMADA: se omite, el resto se cancela")
    void unaOmitidaPorEstadoTerminal() {
        Cita c1 = construirCita(101L, 200L, "Marco");
        Cita c2 = construirCita(102L, 201L, "Elena");
        c2.setEstadoCita(EstadoCita.COMPLETADA); // ya no es CONFIRMADA → debe omitirse

        when(empleadoRepository.findActivoById(7L)).thenReturn(Optional.of(empleadoFalso));
        when(citaRepository.findCitasFuturasParaCancelar(eq(7L), any(), any()))
                .thenReturn(List.of(c1, c2));
        when(citaRepository.findByIdParaActualizar(101L)).thenReturn(Optional.of(c1));
        when(citaRepository.findByIdParaActualizar(102L)).thenReturn(Optional.of(c2));
        when(citaRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CancelacionMasivaResponse resp = cancelacionMasivaService.cancelarFuturasDelEmpleado(7L);

        assertThat(resp.citasCanceladas()).isEqualTo(1);
        assertThat(resp.citasOmitidas()).isEqualTo(1);
        verify(notificacionService, times(1))
                .crearNotificacion(any(), any(), any(), anyString(), anyString());
    }

    @Test
    @DisplayName("cita walk-in (sin cliente registrado) no añade al contador de notificados")
    void walkInNoNotifica() {
        Cita c1 = construirCita(101L, 200L, "Marco");
        Cita walkIn = new Cita();
        walkIn.setId(102L);
        walkIn.setIdEmpleado(empleadoFalso);
        walkIn.setEstadoCita(EstadoCita.CONFIRMADA);
        walkIn.setFechaCita(LocalDate.now().plusDays(2));
        walkIn.setHoraInicioCita(LocalTime.of(11, 0));
        walkIn.setHoraFinCita(LocalTime.of(11, 30));
        // NO se le asigna idCliente: simula walk-in invitado.

        when(empleadoRepository.findActivoById(7L)).thenReturn(Optional.of(empleadoFalso));
        when(citaRepository.findCitasFuturasParaCancelar(eq(7L), any(), any()))
                .thenReturn(List.of(c1, walkIn));
        when(citaRepository.findByIdParaActualizar(101L)).thenReturn(Optional.of(c1));
        when(citaRepository.findByIdParaActualizar(102L)).thenReturn(Optional.of(walkIn));
        when(citaRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CancelacionMasivaResponse resp = cancelacionMasivaService.cancelarFuturasDelEmpleado(7L);

        assertThat(resp.citasCanceladas()).isEqualTo(2);
        assertThat(resp.clientesNotificados()).isEqualTo(1); // solo el cliente registrado
        verify(notificacionService, times(1))
                .crearNotificacion(any(), any(), any(), anyString(), anyString());
    }

    @Test
    @DisplayName("dos citas del mismo cliente: solo cuenta como 1 cliente notificado")
    void mismoClienteDosVeces() {
        Cita c1 = construirCita(101L, 200L, "Marco");
        Cita c2 = construirCita(102L, 200L, "Marco"); // mismo cliente id 200

        when(empleadoRepository.findActivoById(7L)).thenReturn(Optional.of(empleadoFalso));
        when(citaRepository.findCitasFuturasParaCancelar(eq(7L), any(), any()))
                .thenReturn(List.of(c1, c2));
        when(citaRepository.findByIdParaActualizar(anyLong())).thenAnswer(inv -> {
            Long id = inv.getArgument(0);
            return Optional.of(id == 101L ? c1 : c2);
        });
        when(citaRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CancelacionMasivaResponse resp = cancelacionMasivaService.cancelarFuturasDelEmpleado(7L);

        assertThat(resp.citasCanceladas()).isEqualTo(2);
        assertThat(resp.clientesNotificados()).isEqualTo(1);
    }

    // Helper: crea una cita CONFIRMADA con el cliente indicado.
    private Cita construirCita(Long idCita, Long idCliente, String nombreCliente) {
        Usuario u = new Usuario();
        u.setId(idCliente);
        u.setCorreoUsuario(nombreCliente.toLowerCase() + "@x.com");

        Cliente cliente = new Cliente();
        cliente.setId(idCliente);
        cliente.setUsuario(u);
        cliente.setNombreCliente(nombreCliente);
        cliente.setApellidosCliente("Apellido");

        Cita c = new Cita();
        c.setId(idCita);
        c.setIdEmpleado(empleadoFalso);
        c.setIdCliente(cliente);
        c.setEstadoCita(EstadoCita.CONFIRMADA);
        c.setFechaCita(LocalDate.now().plusDays(1));
        c.setHoraInicioCita(LocalTime.of(10, 0));
        c.setHoraFinCita(LocalTime.of(10, 30));
        return c;
    }
}
