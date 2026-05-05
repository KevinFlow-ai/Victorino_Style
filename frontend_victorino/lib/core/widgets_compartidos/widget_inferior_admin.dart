// Bottom navigation del panel administrador (5 pestañas).
//
// Es un widget "tonto": recibe el índice actual y un callback. La navegación real
// se gestiona desde el ShellAdminScreen + StatefulShellRoute del GoRouter.
import 'package:flutter/material.dart';

import '../theme/app_colores.dart';

class WidgetInferiorAdmin extends StatelessWidget {
  const WidgetInferiorAdmin({
    super.key,
    required this.indiceActual,
    required this.alSeleccionar,
  });

  final int indiceActual;
  final ValueChanged<int> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    // 5 pestañas en el orden acordado: Agenda · Estadísticas · Empleados · Servicios · Negocio.
    const items = <_ItemNav>[
      _ItemNav(icon: Icons.calendar_month, label: 'Agenda'),
      _ItemNav(icon: Icons.analytics_outlined, label: 'Estadísticas'),
      _ItemNav(icon: Icons.groups_outlined, label: 'Empleados'),
      _ItemNav(icon: Icons.content_cut, label: 'Servicios'),
      _ItemNav(icon: Icons.business_center_outlined, label: 'Negocio'),
    ];

    // Pegada al borde inferior. Sin margin alrededor: ocupa todoo el ancho
    // y se funde con la parte baja del Scaffold. Respetamos el padding del
    // SafeArea (gestos / notch) sumándolo manualmente al padding inferior.
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
        // Esquinas redondeadas solo arriba: la barra se "engancha" al borde inferior.
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
                        size: 20,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
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
