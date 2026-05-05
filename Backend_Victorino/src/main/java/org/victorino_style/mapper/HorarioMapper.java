package org.victorino_style.mapper;

import org.springframework.stereotype.Component;
import org.victorino_style.dto.admin.CierreAnualResponse;
import org.victorino_style.dto.admin.DescansoResponse;
import org.victorino_style.dto.admin.HorarioPeluqueriaResponse;
import org.victorino_style.entity.HorarioEmpleado;
import org.victorino_style.entity.Peluqueria;


// Un "mapper" es una clase cuya responsabilidad es TRANSFORMAR datos de un tipo a otro.
// Normalmente se usa para convertir entidades de base de datos (modelos internos)
// en objetos que se devuelven al cliente (DTOs), o viceversa.
// Su objetivo es separar la lógica de negocio de la representación externa,
// manteniendo el código limpio, ordenado y fácil de mantener.

// Conversiones entre las entidades de configuración de la peluquería y sus DTOs de salida.
@Component
public class HorarioMapper {

    // Peluqueria → HorarioPeluqueriaResponse: extrae las 14 columnas semanales.
    public HorarioPeluqueriaResponse aRespuestaHorario(Peluqueria p) {
        return new HorarioPeluqueriaResponse(
                p.getId(),
                p.getNombrePeluqueria(),
                p.getAperturaLunes(), p.getCierreLunes(),
                p.getAperturaMartes(), p.getCierreMartes(),
                p.getAperturaMiercoles(), p.getCierreMiercoles(),
                p.getAperturaJueves(), p.getCierreJueves(),
                p.getAperturaViernes(), p.getCierreViernes(),
                p.getAperturaSabado(), p.getCierreSabado(),
                p.getAperturaDomingo(), p.getCierreDomingo()
        );
    }

    // Peluqueria → CierreAnualResponse: solo el periodo de vacaciones.
    public CierreAnualResponse aRespuestaCierreAnual(Peluqueria p) {
        return new CierreAnualResponse(p.getCierreAnualInicio(), p.getCierreAnualFin());
    }

    // HorarioEmpleado → DescansoResponse, incluyendo el nombre del empleado.
    public DescansoResponse aRespuestaDescanso(HorarioEmpleado he) {
        var emp = he.getIdEmpleado();
        return new DescansoResponse(
                emp.getId(),
                emp.getNombreEmpleado() + " " + emp.getApellidosEmpleado(),
                he.getDescansoInicioHorario(),
                he.getDescansoDuracionHorario()
        );
    }
}
