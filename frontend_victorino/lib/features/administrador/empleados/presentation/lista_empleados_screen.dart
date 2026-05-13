// Lista de empleados del panel admin. Inspirada en `Gestion_de_empleados_admin.png`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colores.dart';
import '../application/empleados_providers.dart';
import '../domain/entidades/empleado.dart';
import '../../../../core/widgets_compartidos/campana_notificaciones_widget.dart';
import 'widgets/dialogo_cancelacion_masiva.dart';
import 'widgets/empleado_card.dart';

class ListaEmpleadosScreen extends ConsumerStatefulWidget {
  const ListaEmpleadosScreen({super.key});

  @override
  ConsumerState<ListaEmpleadosScreen> createState() => _ListaEmpleadosScreenState();
}

class _ListaEmpleadosScreenState extends ConsumerState<ListaEmpleadosScreen> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(empleadosAdminNotifierProvider);
    final notifier = ref.read(empleadosAdminNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Empleados',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textMain)),
        // actions: const [CampanaNotificacionesWidget()], ************ NOTIFICACIONES ICONO ICONO NOTI

      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await context.push('/admin/empleados/nuevo');
          await notifier.recargar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e is Failure ? e.mensaje : 'No se pudieron cargar los empleados',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (lista) => _Cuerpo(
          empleados: lista,
          busqueda: _busqueda,
          incluirInactivos: notifier.incluirInactivos,
          alCambiarBusqueda: (s) => setState(() => _busqueda = s),
          alAlternarInactivos: notifier.alternarInactivos,
        ),
      ),
    );
  }
}

class _Cuerpo extends ConsumerWidget {
  const _Cuerpo({
    required this.empleados,
    required this.busqueda,
    required this.incluirInactivos,
    required this.alCambiarBusqueda,
    required this.alAlternarInactivos,
  });

  final List<Empleado> empleados;
  final String busqueda;
  final bool incluirInactivos;
  final ValueChanged<String> alCambiarBusqueda;
  final ValueChanged<bool> alAlternarInactivos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtrados = empleados.where((e) {
      if (busqueda.trim().isEmpty) return true;
      final s = busqueda.toLowerCase();
      return e.nombreCompleto.toLowerCase().contains(s)
          || e.correo.toLowerCase().contains(s);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(empleadosAdminNotifierProvider.notifier).recargar(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KPI total.
          _KpiCard(total: empleados.length),
          const SizedBox(height: 16),
          // Búsqueda.
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar por nombre',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: alCambiarBusqueda,
          ),
          const SizedBox(height: 8),
          // Toggle incluir inactivos.
          Row(
            children: [
              Switch(
                value: incluirInactivos,
                activeThumbColor: AppColors.primary,
                onChanged: alAlternarInactivos,
              ),
              const Text('Mostrar también empleados dados de baja'),
            ],
          ),
          const SizedBox(height: 8),
          if (filtrados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Sin empleados que coincidan.')),
            )
          else
            ...filtrados.map((e) => EmpleadoCard(
                  empleado: e,
                  alEditar: () async {
                    await context.push('/admin/empleados/${e.id}/editar');
                    await ref.read(empleadosAdminNotifierProvider.notifier).recargar();
                  },
                  alDarBaja: () async {
                    final ok = await mostrarDialogoCancelacionMasiva(context, e.nombreCompleto);
                    if (ok != true || !context.mounted) return;
                    try {
                      await ref.read(darBajaEmpleadoProvider).ejecutar(e.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${e.nombreCompleto} dado de baja')),
                        );
                      }
                      await ref.read(empleadosAdminNotifierProvider.notifier).recargar();
                    } catch (err) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo dar de baja: $err')),
                        );
                      }
                    }
                  },
                )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$total',
                  style: GoogleFonts.poppins(
                      fontSize: 26, fontWeight: FontWeight.bold, height: 1.1)),
              Text('Empleados totales',
                  style: GoogleFonts.roboto(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
