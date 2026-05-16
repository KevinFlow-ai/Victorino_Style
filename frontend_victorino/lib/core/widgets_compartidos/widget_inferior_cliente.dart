// Bottom navigation del cliente (4 pestañas: Inicio · Reservar · Historial · Perfil).
//
// Widget "tonto": recibe el índice actual y un callback. La navegación real se
// gestiona desde el ShellClienteScreen + StatefulShellRoute del GoRouter,
// siguiendo el mismo patrón que el panel admin.
import 'package:flutter/material.dart';

import '../theme/app_colores.dart';

class WidgetInferiorCliente extends StatelessWidget {
  const WidgetInferiorCliente({
    super.key,
    required this.indiceActual,
    required this.alSeleccionar,
  });

  // Pestaña activa (0..3). El shell se lo pasa desde navigationShell.currentIndex.
  final int indiceActual;
  // Callback que invoca el shell para cambiar de rama.
  final ValueChanged<int> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    const items = <_ItemNav>[
      _ItemNav(icon: Icons.home_outlined,           label: 'Inicio'),
      _ItemNav(icon: Icons.calendar_today_outlined, label: 'Reservar'),
      _ItemNav(icon: Icons.history,                 label: 'Historial'),
      _ItemNav(icon: Icons.person_outline,          label: 'Perfil'),
    ];

    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8 + safeBottom,
        left: 6,
        right: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = indiceActual == index;
          final item = items[index];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => alSeleccionar(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentGlow : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      item.icon,
                      size: 22,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ItemNav {
  const _ItemNav({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
