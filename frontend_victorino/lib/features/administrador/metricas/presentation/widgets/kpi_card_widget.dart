
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colores.dart';

// ============================================================================
// EXPLICACIÓN PARA UN NOVATO TOTAL (TODOo VA EN COMENTARIOS)
// ============================================================================
//
// Este archivo define un "widget". Un widget es simplemente una pieza visual
// de la pantalla en Flutter. Piensa en él como una tarjeta, un botón, un texto,
// una imagen… cualquier cosa que se ve en la app.
//
// Este widget en particular se llama **KpiCardWidget**.
// Su función es mostrar una tarjeta pequeña con:
//
//   - un icono
//   - un número o valor importante (por ejemplo: "120 citas")
//   - un título que explica qué es ese número (por ejemplo: "Citas del mes")
//
// KPI significa "indicador clave de rendimiento", pero no necesitas saber eso.
// Solo imagina que es una tarjeta que muestra un dato importante.



// ============================================================================
// DEFINICIÓN DEL WIDGET
// ============================================================================
//
// Este widget es "StatelessWidget", lo que significa que NO cambia por sí solo.
// Solo muestra lo que le pasas.
//
// Tiene 4 parámetros:
//
//   - titulo → texto pequeño que explica el dato
//   - valor  → el número o dato principal
//   - icono  → un icono que representa el dato
//   - color  → color del icono y fondo decorativo (opcional)
//
// Ejemplo mental:
//   KpiCardWidget(
//     titulo: "Citas completadas",
//     valor: "87%",
//     icono: Icons.check,
//   )
//
class KpiCardWidget extends StatelessWidget {
  const KpiCardWidget({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.color = AppColors.primary, // color por defecto
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // ==========================================================================
    // CONTENEDOR PRINCIPAL
    // ==========================================================================
    //
    // Aquí creamos la tarjeta visual:
    // - padding → espacio interno
    // - color de fondo
    // - bordes redondeados
    // - sombra suave
    //
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      // ==========================================================================
      // CONTENIDO DE LA TARJETA
      // ==========================================================================
      //
      // Usamos una columna (vertical) con:
      //   1. Icono dentro de un cuadrito
      //   2. Espacio
      //   3. Valor grande
      //   4. Título pequeño
      //
      // mainAxisSize.min → hace que la tarjeta sea compacta
      //
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------------------------
          // ICONO
          // ----------------------------------------------------------------------
          //
          // El icono va dentro de un pequeño recuadro con fondo suave.
          //
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 16),
          ),

          const SizedBox(height: 8),

          // ----------------------------------------------------------------------
          // VALOR PRINCIPAL
          // ----------------------------------------------------------------------
          //
          // Texto grande y en negrita.
          // maxLines y ellipsis evitan que se desborde si es muy largo.
          //
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),

          // ----------------------------------------------------------------------
          // TÍTULO
          // ----------------------------------------------------------------------
          //
          // Texto pequeño y con color tenue.
          //
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
