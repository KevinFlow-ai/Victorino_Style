// Gráfica de líneas con la distribución de citas por franja horaria.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../domain/entidades/metricas_resumen.dart';

class GraficaFranjasWidget extends StatelessWidget {
  const GraficaFranjasWidget({super.key, required this.datos});
  final List<DistribucionFranja> datos;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) {
      return _contenedor(
        child: const SizedBox(
          height: 180,
          child: Center(child: Text('Sin datos en el rango seleccionado')),
        ),
      );
    }
    final puntos = <FlSpot>[];
    for (final d in datos) {
      final hora = double.parse(d.horaInicio.split(':')[0]);
      puntos.add(FlSpot(hora, d.citas.toDouble()));
    }
    final maxY = datos.map((d) => d.citas).reduce((a, b) => a > b ? a : b);

    return _contenedor(
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minX: puntos.first.x,
            maxX: puntos.last.x,
            minY: 0,
            maxY: (maxY == 0 ? 1 : maxY * 1.2).toDouble(),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: (maxY == 0 ? 1 : maxY / 2).toDouble()),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  getTitlesWidget: (v, _) =>
                      Padding(padding: const EdgeInsets.only(top: 8), child: Text('${v.toInt()}h', style: const TextStyle(fontSize: 11))),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: AppColors.secondary, // color de la linea del grafico
                barWidth: 3, // grosor de la linea del grafico
                spots: puntos,
                belowBarData: BarAreaData(show: true, color: AppColors.accentGlow), // relleno de la barra
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenedor({required Widget child}) {
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
          const Text('Citas por franja horaria',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
