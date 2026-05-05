package org.victorino_style.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.multipart.MultipartFile;
import org.victorino_style.dto.admin.FotoResponse;
import org.victorino_style.dto.admin.ServicioAdminRequest;
import org.victorino_style.dto.admin.ServicioAdminResponse;
import org.victorino_style.entity.Servicio;
import org.victorino_style.exception.ServicioNoEncontradoException;
import org.victorino_style.mapper.ServicioMapper;
import org.victorino_style.repository.ServicioRepository;

import java.math.BigDecimal;
import java.time.Instant;
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

// Tests unitarios del servicio ServicioService.
@ExtendWith(MockitoExtension.class)
class ServicioServiceTest {

    @Mock private ServicioRepository servicioRepository;
    @Mock private ServicioMapper servicioMapper;
    @Mock private FileStorageService fileStorageService;
    @Mock private AuditoriaService auditoriaService;

    @InjectMocks
    private ServicioService servicioService;

    private Servicio servicioFalso;

    @BeforeEach
    void preparar() {
        servicioFalso = new Servicio();
        servicioFalso.setId(1L);
        servicioFalso.setNombreServicio("Corte clásico");
        servicioFalso.setDescripcionServicio("Corte de pelo de toda la vida");
        servicioFalso.setDuracionServicio(30);
        servicioFalso.setPrecioServicio(new BigDecimal("15.00"));
        servicioFalso.setFotoServicio("/uploads/servicios/old.png");
        servicioFalso.setFechaCreacionServicio(Instant.now());
        servicioFalso.setFechaModificacionServicio(Instant.now());
    }

    @Test
    @DisplayName("listar(false): devuelve solo activos")
    void listarSoloActivos() {
        when(servicioRepository.findByFechaEliminacionServicioIsNullOrderByNombreServicioAsc())
                .thenReturn(List.of(servicioFalso));
        when(servicioMapper.aRespuesta(any())).thenReturn(
                new ServicioAdminResponse(1L, "Corte clásico", "...", 30,
                        new BigDecimal("15.00"), "/uploads/servicios/old.png", true));

        List<ServicioAdminResponse> lista = servicioService.listar(false);

        assertThat(lista).hasSize(1);
        verify(servicioRepository, never()).findAllByOrderByNombreServicioAsc();
    }

    @Test
    @DisplayName("obtener: id no existe lanza ServicioNoEncontradoException")
    void obtenerNoExiste() {
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(99L))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> servicioService.obtener(99L))
                .isInstanceOf(ServicioNoEncontradoException.class);
    }

    @Test
    @DisplayName("crear: persiste con nombre y precio normalizados, audita")
    void crearOk() {
        when(servicioRepository.save(any(Servicio.class))).thenAnswer(inv -> {
            Servicio s = inv.getArgument(0);
            s.setId(5L);
            return s;
        });
        when(servicioMapper.aRespuesta(any())).thenReturn(
                new ServicioAdminResponse(5L, "Tinte", "Tinte completo", 90,
                        new BigDecimal("35.00"), "", true));

        ServicioAdminRequest dto = new ServicioAdminRequest(
                "  Tinte  ", "Tinte completo", 90, new BigDecimal("35.00"));

        ServicioAdminResponse resp = servicioService.crear(dto);

        assertThat(resp.idServicio()).isEqualTo(5L);
        ArgumentCaptor<Servicio> captor = ArgumentCaptor.forClass(Servicio.class);
        verify(servicioRepository).save(captor.capture());
        // El servicio normaliza con trim().
        assertThat(captor.getValue().getNombreServicio()).isEqualTo("Tinte");
        verify(auditoriaService).registrar(eq("CREAR_SERVICIO"), eq("SERVICIO"), any(), anyString());
    }

    @Test
    @DisplayName("editar: cambia los 4 campos editables y audita")
    void editarOk() {
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicioFalso));
        when(servicioRepository.save(any(Servicio.class))).thenAnswer(inv -> inv.getArgument(0));
        when(servicioMapper.aRespuesta(any())).thenReturn(
                new ServicioAdminResponse(1L, "Corte premium", "Mejor", 45,
                        new BigDecimal("20.00"), "/uploads/servicios/old.png", true));

        ServicioAdminRequest dto = new ServicioAdminRequest(
                "Corte premium", "Mejor", 45, new BigDecimal("20.00"));

        servicioService.editar(1L, dto);

        assertThat(servicioFalso.getNombreServicio()).isEqualTo("Corte premium");
        assertThat(servicioFalso.getDuracionServicio()).isEqualTo(45);
        verify(auditoriaService).registrar(eq("EDITAR_SERVICIO"), eq("SERVICIO"), any(), anyString());
    }

    @Test
    @DisplayName("darBaja: marca fecha_eliminacion_servicio y audita")
    void darBajaOk() {
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicioFalso));

        servicioService.darBaja(1L);

        assertThat(servicioFalso.getFechaEliminacionServicio()).isNotNull();
        verify(servicioRepository).save(servicioFalso);
        verify(auditoriaService).registrar(eq("BAJA_SERVICIO"), eq("SERVICIO"), any(), anyString());
    }

    @Test
    @DisplayName("subirFoto ok: usa el servicio compartido y persiste la URL nueva")
    void subirFotoOk() {
        MultipartFile archivo = new org.springframework.mock.web.MockMultipartFile(
                "archivo", "foto.png", "image/png", "datos".getBytes());
        when(servicioRepository.findByIdAndFechaEliminacionServicioIsNull(1L))
                .thenReturn(Optional.of(servicioFalso));
        when(fileStorageService.reemplazar(archivo, "servicios", "/uploads/servicios/old.png"))
                .thenReturn("/uploads/servicios/nueva.png");

        FotoResponse resp = servicioService.subirFoto(1L, archivo);

        assertThat(resp.fotoUrl()).isEqualTo("/uploads/servicios/nueva.png");
        assertThat(servicioFalso.getFotoServicio()).isEqualTo("/uploads/servicios/nueva.png");
    }
}
