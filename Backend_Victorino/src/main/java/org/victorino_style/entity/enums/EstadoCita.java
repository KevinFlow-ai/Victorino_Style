package org.victorino_style.entity.enums;

// Enumerado con los seis estados posibles de una cita.
// Se mapea como ENUM en MySQL para garantizar integridad referencial.
public enum EstadoCita {

    // Cita reservada y todavía no atendida. Único estado modificable y cancelable.
    CONFIRMADA,

    // Cita en marcha (la hora de inicio ya pasó pero la hora fin todavía no).
    EN_PROCESO,

    // Cita finalizada con éxito (la hora fin ya pasó y nadie la canceló).
    COMPLETADA,

    // Cita cancelada por el cliente desde su app.
    CANCELADA_CLIENTE,

    // Cita cancelada por la peluquería (admin u operación masiva por baja de empleado).
    CANCELADA_PELUQUERIA,

    // Cita en la que el cliente no se presentó. Solo el empleado puede marcar este estado.
    NO_PRESENTADO
}

// ============================================================================
// EstadoCita
// ----------------------------------------------------------------------------
// Este enum define los **seis estados** que puede tener una cita en el ciclo
// de vida del negocio Victorino Style.
//
// ¿PARA QUÉ SIRVE ESTE ENUM?
// - Se mapea con la columna `estado_cita` (ENUM) de la tabla `cita`.
// - Lo usan tanto los servicios de reserva, cancelación y agenda como los
//   schedulers que avanzan automáticamente CONFIRMADA → EN_PROCESO → COMPLETADA
//   en función de la hora actual.
// - Es la única vía type-safe para transitar entre estados desde Java.
//
// TRANSICIONES VÁLIDAS:
//   CONFIRMADA  → EN_PROCESO        (automático, al llegar la hora_inicio)
//   EN_PROCESO  → COMPLETADA        (automático, al llegar la hora_fin)
//   CONFIRMADA  → CANCELADA_CLIENTE     (acción del cliente)
//   CONFIRMADA  → CANCELADA_PELUQUERIA  (acción del admin / cancelación masiva)
//   CONFIRMADA  → NO_PRESENTADO     (acción del empleado)
//
// ESTADOS TERMINALES (no se pueden modificar):
//   COMPLETADA, CANCELADA_CLIENTE, CANCELADA_PELUQUERIA, NO_PRESENTADO
//
// Solo CONFIRMADA es modificable: cambiar día/hora, servicio o nota.
// ============================================================================
