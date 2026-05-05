// Gráfica de barras horizontal con el conteo de citas por estados de las citas
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colores.dart';

class GraficaEstadosWidget extends StatelessWidget {
  const GraficaEstadosWidget({
    super.key,
    required this.completadas,
    required this.canceladas,
    required this.noPresentado,
  });

  final int completadas;
  final int canceladas;
  final int noPresentado;

  @override
  Widget build(BuildContext context) {
    final barras = [
      _Barra('Completadas', completadas, Colors.green),
      _Barra('Canceladas', canceladas, AppColors.error),
      _Barra('No present.', noPresentado, Colors.orange),
    ];
    final maxY = barras.map((b) => b.valor).fold<int>(0, (p, v) => v > p ? v : p);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Citas por estado de las citas',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: (maxY == 0 ? 1 : maxY * 1.2).toDouble(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= barras.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(barras[i].etiqueta, style: const TextStyle(fontSize: 11)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  barras.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: barras[i].valor.toDouble(),
                        color: barras[i].color,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Barra {
  const _Barra(this.etiqueta, this.valor, this.color);
  final String etiqueta;
  final int valor;
  final Color color;
}
