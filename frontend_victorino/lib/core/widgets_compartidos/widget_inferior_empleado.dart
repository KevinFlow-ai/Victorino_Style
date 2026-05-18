import 'package:flutter/material.dart';

import '../../features/empleado/agenda/presentation/agenda_empleado_screen.dart';
import '../../features/empleado/perfil/presentation/perfil_empleado_screen.dart';
import '../theme/app_colores.dart';

class WidgetInferiorEmpleado extends StatefulWidget {
  const WidgetInferiorEmpleado({super.key});

  @override
  State<WidgetInferiorEmpleado> createState() =>
      _WidgetInferiorEmpleadoState();
}

class _WidgetInferiorEmpleadoState
    extends State<WidgetInferiorEmpleado> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    AgendaEmpleadoScreen(),
    PerfilEmpleadoScreen(),
  ];

  static const List<_ItemNav> items = [
    _ItemNav(
      icon: Icons.calendar_month,
      label: 'Agenda',
    ),
    _ItemNav(
      icon: Icons.person_outline,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          top: 8,
          bottom: 8 + safeBottom,
          left: 6,
          right: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,

          // Solo redondeado arriba para fusionarse
          // con el borde inferior del Scaffold
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),

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
            final isSelected = selectedIndex == index;
            final item = items[index];

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentGlow
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
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
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ItemNav {
  const _ItemNav({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}