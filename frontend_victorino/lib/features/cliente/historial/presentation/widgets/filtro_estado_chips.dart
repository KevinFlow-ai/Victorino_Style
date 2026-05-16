// Fila de chips para filtrar el historial por estado.

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../../shared/domain/entidades/estado_cita.dart';

class FiltroEstadoChips extends StatelessWidget {
  const FiltroEstadoChips({
    super.key,
    required this.actual,
    required this.onCambiar,
  });

  final EstadoCita? actual;
  final ValueChanged<EstadoCita?> onCambiar;

  @override
  Widget build(BuildContext context) {
    // El filtro "Todas" se representa con valor null.
    final opciones = <_Opcion>[
      const _Opcion(null, 'Todas'),
      _Opcion(EstadoCita.confirmada, 'Confirmadas'),
      _Opcion(EstadoCita.completada, 'Completadas'),
      _Opcion(EstadoCita.canceladaCliente, 'Canceladas'),
      _Opcion(EstadoCita.noPresentado, 'No acudiste'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: opciones.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final o = opciones[i];
          final activo = actual == o.valor;
          return ChoiceChip(
            label: Text(o.etiqueta),
            selected: activo,
            onSelected: (_) => onCambiar(o.valor),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.accentGlow,
            labelStyle: TextStyle(
              color: activo ? Colors.white : AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }
}

class _Opcion {
  const _Opcion(this.valor, this.etiqueta);
  final EstadoCita? valor;
  final String etiqueta;
}
