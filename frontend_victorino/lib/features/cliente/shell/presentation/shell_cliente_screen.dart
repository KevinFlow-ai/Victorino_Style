// Shell del módulo cliente. Idéntico patrón al ShellAdminScreen pero con 4 ramas
// (Inicio, Reservar, Historial, Perfil) en lugar de 5. Mantiene la pila de cada
// pestaña vía StatefulShellRoute.indexedStack del GoRouter.
//
// Auto-refresh:
//   - Al cambiar de pestaña: invalida los providers de la pestaña destino para
//     que el cliente vea datos frescos sin tener que hacer pull-to-refresh.
//   - Al volver del background (AppLifecycleState.resumed): invalida los
//     providers de la pestaña activa.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colores.dart';
import '../../../../core/widgets_compartidos/widget_inferior_cliente.dart';
import '../../shared/application/refrescar_cliente.dart';

class ShellClienteScreen extends ConsumerStatefulWidget {
  const ShellClienteScreen({super.key, required this.navigationShell});

  // GoRouter lo inyecta automáticamente cuando se usa StatefulShellRoute.indexedStack.
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ShellClienteScreen> createState() => _ShellClienteScreenState();
}

class _ShellClienteScreenState extends ConsumerState<ShellClienteScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de background → refresca la pestaña activa.
    if (state == AppLifecycleState.resumed) {
      invalidarTabCliente(ref, widget.navigationShell.currentIndex);
    }
  }

  void _alSeleccionarPestana(int indice) {
    final esMisma = indice == widget.navigationShell.currentIndex;
    widget.navigationShell.goBranch(indice, initialLocation: esMisma);
    // Refresca la pestaña destino para que muestre datos frescos al instante.
    invalidarTabCliente(ref, indice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.navigationShell,
      bottomNavigationBar: WidgetInferiorCliente(
        indiceActual: widget.navigationShell.currentIndex,
        alSeleccionar: _alSeleccionarPestana,
      ),
    );
  }
}
