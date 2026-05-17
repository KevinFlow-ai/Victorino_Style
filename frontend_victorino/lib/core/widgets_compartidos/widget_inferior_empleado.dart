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

class _WidgetInferiorEmpleadoState extends State<WidgetInferiorEmpleado> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    AgendaEmpleadoScreen(),
    PerfilEmpleadoScreen(),
  ];

  final List<IconData> icons = [
    Icons.calendar_today,
    Icons.person,
  ];

  final List<String> labels = [
    "Agenda",
    "Perfil",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final isSelected = selectedIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accentGlow
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icons[index],
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
