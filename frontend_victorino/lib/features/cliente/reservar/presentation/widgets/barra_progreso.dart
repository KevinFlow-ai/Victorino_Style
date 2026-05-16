// Barra de progreso visual del wizard. 4 segmentos: Servicio · Peluquero · Día y hora · Confirmar.
// Cada segmento se ilumina cuando el paso correspondiente está activo o ya completado.

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colores.dart';

class BarraProgreso extends StatelessWidget {
  const BarraProgreso({super.key, required this.pasoActual});

  // 0..3.
  final int pasoActual;

  @override
  Widget build(BuildContext context) {
    const etiquetas = ['Servicio', 'Peluquero', 'Día y hora', 'Confirmar'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (i) {
              final activo = i <= pasoActual;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 3 ? 0 : 4),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: activo
                          ? AppColors.primary
                          : AppColors.accentGlow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (i) {
              final activo = i == pasoActual;
              return Expanded(
                child: Text(
                  etiquetas[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: activo ? AppColors.primary : AppColors.textMuted,
                    fontWeight:
                        activo ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
