package org.victorino_style.exception;

import org.victorino_style.dto.cliente.DetalleCitaExistenteError;

// Lanzada cuando un cliente intenta reservar una cita y ya tiene otra cita ACTIVA
// (CONFIRMADA o EN_PROCESO) con el MISMO servicio, sin importar la fecha.
// Por ejemplo: ya tiene un corte el 20 de mayo y trata de reservar otro corte para
// el 15 de junio → bloqueado. Solo podrá reservar otro del mismo servicio cuando el
// anterior pase a COMPLETADA o se cancele.
// Se traduce a HTTP 409 Conflict con detalles enriquecidos (incluye nombre del servicio).
public class CitaServicioDuplicadoException extends RuntimeException {

    // Detalle estructurado de la cita ya existente con el mismo servicio.
    private final DetalleCitaExistenteError detalle;

    public CitaServicioDuplicadoException(DetalleCitaExistenteError detalle) {
        super("Ya tienes una cita activa con este mismo servicio");
        this.detalle = detalle;
    }

    public DetalleCitaExistenteError getDetalle() {
        return detalle;
    }
}

// ============================================================================
// CitaServicioDuplicadoException
// ----------------------------------------------------------------------------
// Aplica la regla de las 3 reglas combinadas: además de "1 cita por día" y
// "1 cita por semana", el cliente no puede tener DOS citas activas del mismo
// servicio simultáneamente.
//
// ESTA REGLA EVITA reservas duplicadas accidentales del mismo servicio en
// fechas distintas: el cliente debe completar (o cancelar) su cita actual de
// corte antes de reservar otra de corte.
//
// JERARQUÍA DE VALIDACIÓN en CitaClienteService.reservar():
//   1) Antelación (hoy ≤ fecha ≤ hoy+30).
//   2) Día abierto (no festivo, no cierre anual).
//   3) Mismo día → CitaMismoDiaException.
//   4) Misma semana → CitaSemanaDuplicadaException.
//   5) Mismo servicio → CitaServicioDuplicadoException.
//   6) Solape horario / fuera de horario → CitaSolapadaException.
//   7) @Version → 409 si concurrencia pisa.
//
// El frontend recibe el primer 409 que se dispare y muestra el mensaje
// contextual usando "codigo" del campo detalles.
// ============================================================================
