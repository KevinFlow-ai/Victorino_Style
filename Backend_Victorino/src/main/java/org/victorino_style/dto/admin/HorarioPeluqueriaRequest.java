package org.victorino_style.dto.admin;

import java.time.LocalTime;

// DTO de entrada para configurar el horario semanal de la peluquería.
// Cada par (apertura, cierre) puede ser null para indicar que ese día está cerrado.
// Lo recibe HorarioAdminController en PUT /admin/horario.
public record HorarioPeluqueriaRequest(

        // Lunes: apertura y cierre. Si ambos son null el lunes está cerrado.
        LocalTime aperturaLunes,
        LocalTime cierreLunes,

        // Martes.
        LocalTime aperturaMartes,
        LocalTime cierreMartes,

        // Miércoles.
        LocalTime aperturaMiercoles,
        LocalTime cierreMiercoles,

        // Jueves.
        LocalTime aperturaJueves,
        LocalTime cierreJueves,

        // Viernes.
        LocalTime aperturaViernes,
        LocalTime cierreViernes,

        // Sábado.
        LocalTime aperturaSabado,
        LocalTime cierreSabado,

        // Domingo.
        LocalTime aperturaDomingo,
        LocalTime cierreDomingo
) {
}

// ============================================================================
// HorarioPeluqueriaRequest
// ----------------------------------------------------------------------------
// Define el horario semanal de la peluquería: apertura y cierre por cada día.
//
// ¿PARA QUÉ SIRVE?
// - Endpoint PUT /admin/horario.
// - HorarioAdminService valida que (apertura, cierre) sean coherentes:
//      * O ambos null  (día cerrado)
//      * O ambos rellenos con cierre > apertura
//   y persiste la fila singleton de la tabla `peluqueria`.
//
// REGLA DE NEGOCIO:
// - Cualquier hueco fuera del horario de apertura se considera no reservable.
// - El cliente verá el calendario con esos huecos en gris al reservar.
// ============================================================================


// Este record representa el objeto que el FRONTEND envía al BACKEND
// cuando quiere ACTUALIZAR o CONFIGURAR el horario de la peluquería.
//
// Es un *Request*, es decir: datos que ENTRAN al servidor.
// El backend NO devuelve este objeto, solo lo recibe.
//
// Cada día de la semana tiene dos campos:
//   - aperturaXxx  → hora en la que se abre
//   - cierreXxx    → hora en la que se cierra
//
// Si apertura y cierre son null → ese día está CERRADO.
//
// Ejemplo de JSON que enviaría el frontend:
//
// {
//   "aperturaLunes": "09:00",
//   "cierreLunes": "14:00",
//   "aperturaMartes": "09:00",
//   "cierreMartes": "14:00",
//   ...
// }
//
// Este record es INMUTABLE (como todos los records de Java).
// Sirve únicamente para transportar datos de entrada.