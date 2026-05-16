package org.victorino_style.dto.cliente;

import java.time.LocalDate;
import java.time.LocalTime;

// Record que se incrusta en el campo "detalles" del ApiError cuando se devuelve un 409 por
// "ya tienes cita esta semana" o "ya tienes cita este mismo día". Permite al frontend
// construir un mensaje contextual ("Ya tienes cita el viernes a las 10:00") y ofrecer un
// botón "Modificar" que abre el wizard precargado con la cita existente.
public record DetalleCitaExistenteError(

        // Código de la regla violada. Valores admitidos:
        //   "CITA_MISMO_DIA"        → ya tienes otra cita activa este mismo día.
        //   "CITA_MISMA_SEMANA"     → ya tienes otra cita activa en la semana ISO (lun-dom).
        //   "CITA_MISMO_SERVICIO"   → ya tienes otra cita activa con el mismo servicio.
        // El frontend lo lee para decidir el wording exacto y si el botón "modificar" abre el wizard precargado.
        String codigo,

        // ID de la cita ya existente que bloquea la nueva reserva.
        Long idCitaExistente,

        // Fecha de la cita existente (YYYY-MM-DD).
        LocalDate fechaCitaExistente,

        // Hora de inicio de la cita existente (HH:mm:ss).
        LocalTime horaCitaExistente,

        // Nombre del servicio de la cita existente (ej. "Corte de pelo"). Permite al frontend
        // mostrar mensajes contextuales como "Ya tienes una cita de Corte de pelo el 20 de mayo".
        String nombreServicioExistente
) {
}

// ============================================================================
// DetalleCitaExistenteError
// ----------------------------------------------------------------------------
// Diagrama de uso:
//
//   CitaClienteService.reservar(...)
//          │
//          ├── valida regla "una cita activa por semana"
//          │      └── si choca → throw new CitaSemanaDuplicadaException(detalle)
//          │
//          └── valida regla "una cita por día"
//                 └── si choca → throw new CitaMismoDiaException(detalle)
//
//   GlobalExceptionHandler intercepta y construye ApiError.conDetalles(409, ..., detalle).
//   El frontend recibe:
//     {
//       "status": 409,
//       "error": "Conflict",
//       "message": "Ya tienes una cita esta semana",
//       "detalles": {
//          "codigo": "CITA_MISMA_SEMANA",
//          "idCitaExistente": 42,
//          "fechaCitaExistente": "2026-05-20",
//          "horaCitaExistente": "10:00:00"
//       }
//     }
//
// ¿POR QUÉ ESTÁ EN dto/cliente Y NO EN exception/?
// - Porque conceptualmente es un DTO de respuesta (forma parte del cuerpo JSON
//   que ve el frontend). Su consumidor es la pantalla de reserva del cliente.
// ============================================================================
