package org.victorino_style.entity.enums;

// Enumerado con los cinco tipos de festivo soportados por la peluquería.
// Se mapea como ENUM en MySQL en la columna `tipo_festivo` de la tabla `festivo`.
public enum TipoFestivo {

    // Festivo nacional (ej. 1 de enero, 25 de diciembre).
    NACIONAL,

    // Festivo autonómico (ej. 2 de mayo en la Comunidad de Madrid).
    AUTONOMICO,

    // Festivo local del municipio (ej. fiestas patronales).
    LOCAL,

    // Día cerrado por vacaciones puntuales fuera del cierre anual de agosto.
    VACACIONES,

    // Día cerrado por mantenimiento, limpieza o cualquier motivo operativo.
    MANTENIMIENTO
}

// ============================================================================
// TipoFestivo
// ----------------------------------------------------------------------------
// Este enum clasifica los días en los que la peluquería NO abre, más allá del
// cierre anual definido en la tabla `peluqueria` (cierre_anual_inicio /
// cierre_anual_fin).
//
// ¿PARA QUÉ SIRVE?
// - Se almacena en `festivo.tipo_festivo` (ENUM en MySQL).
// - Permite distinguir festivos oficiales (no editables a la ligera) de
//   cierres operativos puntuales (mantenimiento, vacaciones extra).
// - Lo usa el panel del administrador para mostrar etiquetas y filtros, y el
//   flujo de reserva del cliente para pintar el calendario en gris.
//
// REGLA DE NEGOCIO:
// - El tipo es informativo: a efectos de la disponibilidad de huecos cualquier
//   festivo bloquea el día completo, sea cual sea el tipo.
// ============================================================================
