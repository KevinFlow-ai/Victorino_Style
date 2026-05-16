package org.victorino_style.mapper;

import org.springframework.stereotype.Component;
import org.victorino_style.dto.cliente.EmpleadoPublicoResponse;
import org.victorino_style.dto.cliente.ServicioPublicoResponse;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Servicio;

// Mapper unico para los DTOs ligeros del catalogo publico: GET /servicios y GET /empleados.
// Devuelve solo los campos que el cliente necesita ver para reservar; oculta correos,
// telefonos, configuracion de silencio, fechas de auditoria y demas.
@Component
public class CatalogoMapper {

    // Convierte un Servicio en su DTO publico ligero.
    public ServicioPublicoResponse aRespuestaServicio(Servicio s) {
        return new ServicioPublicoResponse(
                s.getId(),
                s.getNombreServicio(),
                s.getDescripcionServicio(),
                s.getDuracionServicio(),
                s.getPrecioServicio(),
                s.getFotoServicio()
        );
    }

    // Convierte un Empleado en su DTO publico ligero.
    public EmpleadoPublicoResponse aRespuestaEmpleado(Empleado e) {
        return new EmpleadoPublicoResponse(
                e.getId(),
                e.getNombreEmpleado(),
                e.getApellidosEmpleado(),
                e.getFotoEmpleado()
        );
    }
}

// ============================================================================
// CatalogoMapper
// ----------------------------------------------------------------------------
// Componente Spring que convierte entidades de catalogo (Servicio y Empleado)
// en sus DTOs ligeros pensados para el cliente final.
//
// ¿POR QUE UN MAPPER PROPIO Y NO REUSAR LOS MAPPERS DEL ADMIN?
//   Los mappers del admin (ServicioMapper, EmpleadoMapper) devuelven mucha
//   informacion sensible o irrelevante para el cliente:
//     - ServicioAdminResponse: fechas de auditoria, flag activo.
//     - EmpleadoAdminResponse: correo, telefono, rol, descanso, etc.
//
//   El cliente solo necesita lo justo para decidir si reservar o no. Por eso
//   estos DTOs son mas pequeños y este mapper los construye al vuelo.
//
// CONSUMIDORES:
//   - CatalogoController.listarServicios()
//   - CatalogoController.listarEmpleados()
// ============================================================================
