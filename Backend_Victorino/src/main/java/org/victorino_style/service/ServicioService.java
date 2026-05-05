package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.victorino_style.dto.admin.FotoResponse;
import org.victorino_style.dto.admin.ServicioAdminRequest;
import org.victorino_style.dto.admin.ServicioAdminResponse;
import org.victorino_style.entity.Servicio;
import org.victorino_style.exception.FotoObligatoriaException;
import org.victorino_style.exception.ServicioNoEncontradoException;
import org.victorino_style.mapper.ServicioMapper;
import org.victorino_style.repository.ServicioRepository;

import java.time.Instant;
import java.util.List;

// Servicio del dominio SERVICIO (catálogo de la peluquería) para el panel admin.
@Slf4j
@Service // Marca la clase como un "servicio" dentro de la arquitectura de la aplicación.
@RequiredArgsConstructor
public class ServicioService {

    private final ServicioRepository servicioRepository;
    private final ServicioMapper servicioMapper;
    private final FileStorageService fileStorageService;
    private final AuditoriaService auditoriaService;

    private static final String CARPETA_FOTOS = "servicios";

    // ------------------------------------------------------------------------
    // Lista de servicios. Si incluirInactivos=true, devuelve activos + inactivos.
    // ------------------------------------------------------------------------
    @Transactional(readOnly = true)
    public List<ServicioAdminResponse> listar(boolean incluirInactivos) {
        List<Servicio> servicios = incluirInactivos
                ? servicioRepository.findAllByOrderByNombreServicioAsc()
                : servicioRepository.findByFechaEliminacionServicioIsNullOrderByNombreServicioAsc();
        return servicios.stream().map(servicioMapper::aRespuesta).toList();
    }

    // ------------------------------------------------------------------------
    // Detalle de un servicio activo.
    // ------------------------------------------------------------------------
    @Transactional(readOnly = true)
    public ServicioAdminResponse obtener(Long id) {
        Servicio s = servicioRepository.findByIdAndFechaEliminacionServicioIsNull(id)
                .orElseThrow(() -> new ServicioNoEncontradoException(id));
        return servicioMapper.aRespuesta(s);
    }

    // ------------------------------------------------------------------------
    // Alta. Foto se sube en endpoint separado tras crear.
    // ------------------------------------------------------------------------
    @Transactional
    public ServicioAdminResponse crear(ServicioAdminRequest dto) {
        Servicio s = new Servicio();
        copiarCampos(dto, s);
        s.setFotoServicio(""); // se rellena con POST /admin/servicios/{id}/foto
        Instant ahora = Instant.now();
        s.setFechaCreacionServicio(ahora);
        s.setFechaModificacionServicio(ahora);
        s = servicioRepository.save(s);

        auditoriaService.registrar("CREAR_SERVICIO", "SERVICIO", s.getId(),
                "Alta de servicio: " + dto.nombre());
        log.info("Servicio creado: id={}, nombre={}", s.getId(), dto.nombre());
        return servicioMapper.aRespuesta(s);
    }

    // ------------------------------------------------------------------------
    // Edición. Cambia los 4 campos del DTO. La foto se mantiene; para sustituirla
    // se usa el endpoint dedicado.
    // ------------------------------------------------------------------------
    @Transactional
    public ServicioAdminResponse editar(Long id, ServicioAdminRequest dto) {
        Servicio s = servicioRepository.findByIdAndFechaEliminacionServicioIsNull(id)
                .orElseThrow(() -> new ServicioNoEncontradoException(id));
        copiarCampos(dto, s);
        s.setFechaModificacionServicio(Instant.now());
        s = servicioRepository.save(s);

        auditoriaService.registrar("EDITAR_SERVICIO", "SERVICIO", s.getId(),
                "Edición de servicio: " + dto.nombre());
        return servicioMapper.aRespuesta(s);
    }

    // ------------------------------------------------------------------------
    // Baja lógica: marca fecha_eliminacion_servicio.
    // ------------------------------------------------------------------------
    @Transactional
    public void darBaja(Long id) {
        Servicio s = servicioRepository.findByIdAndFechaEliminacionServicioIsNull(id)
                .orElseThrow(() -> new ServicioNoEncontradoException(id));
        Instant ahora = Instant.now();
        s.setFechaEliminacionServicio(ahora);
        s.setFechaModificacionServicio(ahora);
        servicioRepository.save(s);

        auditoriaService.registrar("BAJA_SERVICIO", "SERVICIO", s.getId(),
                "Baja lógica del servicio " + s.getNombreServicio());
    }

    // ------------------------------------------------------------------------
    // Subida de foto. Endpoint multipart.
    // ------------------------------------------------------------------------
    @Transactional
    public FotoResponse subirFoto(Long id, MultipartFile archivo) {
        if (archivo == null || archivo.isEmpty()) throw new FotoObligatoriaException();

        Servicio s = servicioRepository.findByIdAndFechaEliminacionServicioIsNull(id)
                .orElseThrow(() -> new ServicioNoEncontradoException(id));
        String fotoAnterior = s.getFotoServicio();
        String url = fileStorageService.reemplazar(archivo, CARPETA_FOTOS, fotoAnterior);
        s.setFotoServicio(url);
        s.setFechaModificacionServicio(Instant.now());
        servicioRepository.save(s);

        auditoriaService.registrar("SUBIR_FOTO_SERVICIO", "SERVICIO", s.getId(),
                "Foto actualizada para servicio " + s.getNombreServicio());
        return new FotoResponse(url);
    }

    // Aplica los 4 campos editables del DTO a la entidad.
    private void copiarCampos(ServicioAdminRequest dto, Servicio s) {
        s.setNombreServicio(dto.nombre().trim());
        s.setDescripcionServicio(dto.descripcion());
        s.setDuracionServicio(dto.duracionMinutos());
        s.setPrecioServicio(dto.precio());
    }
}
