// Sección "Cancelación masiva" del panel Negocio.
// Selecciona un empleado y dispara la cancelación de todas sus citas futuras.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../../empleados/application/empleados_providers.dart';
import '../../../empleados/domain/entidades/empleado.dart';
import '../../../empleados/presentation/widgets/dialogo_cancelacion_masiva.dart';

class SeccionCancelacionMasivaWidget extends ConsumerStatefulWidget {
  const SeccionCancelacionMasivaWidget({super.key});

  @override
  ConsumerState<SeccionCancelacionMasivaWidget> createState() => _SeccionCancelacionMasivaWidgetState();
}

class _SeccionCancelacionMasivaWidgetState extends ConsumerState<SeccionCancelacionMasivaWidget> {
  Empleado? _seleccionado;
  bool _ejecutando = false;

  @override
  Widget build(BuildContext context) {
    final empleados = ref.watch(empleadosAdminNotifierProvider);

    return _Card(
      titulo: 'Incidencias de plantilla',
      icono: Icons.warning_amber_rounded,
      child: empleados.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (lista) {
          final activos = lista.where((e) => e.activo).toList();
          // Resincronizar la selección con la lista actual por id.
          // El provider puede recargar y crear nuevos objetos Empleado en memoria;
          // si comparamos por referencia (==), el valor antiguo no se encuentra
          // en los items nuevos y el dropdown explota con un assertion error.
          final seleccionadoActual = _seleccionado == null
              ? null
              : activos.where((e) => e.id == _seleccionado!.id).firstOrNull;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cancela en bloque las citas futuras de un empleado por baja médica, '
                    'ausencia imprevista o baja definitiva. Los clientes serán notificados '
                    'automáticamente.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<Empleado>(
                initialValue: seleccionadoActual,
                decoration: InputDecoration(
                  labelText: 'Empleado afectado',
                  labelStyle: const TextStyle(fontSize: 16), // ← más grande
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: activos
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.nombreCompleto)))
                    .toList(),
                onChanged: (v) => setState(() => _seleccionado = v),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: seleccionadoActual == null || _ejecutando ? null : _ejecutar,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(_ejecutando ? 'Cancelando...' : 'Cancelar todas las citas futuras'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _ejecutar() async {
    final emp = _seleccionado!;
    final ok = await mostrarDialogoCancelacionMasiva(context, emp.nombreCompleto);
    if (ok != true) return;
    setState(() => _ejecutando = true);
    try {
      final resumen = await ref.read(cancelarCitasMasivoProvider).ejecutar(emp.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${resumen.citasCanceladas} citas canceladas. '
            '${resumen.clientesNotificados} clientes notificados. '
            '${resumen.citasOmitidas} omitidas.',
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _ejecutando = false);
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.titulo, required this.icono, required this.child});
  final String titulo;
  final IconData icono;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
          Row(children: [
            Icon(icono, color: AppColors.error),
            const SizedBox(width: 8),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
