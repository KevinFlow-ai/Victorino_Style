// Sección "Descansos fijos por empleado". Lista los empleados activos y permite
// configurar el descanso diario de cada uno.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../../empleados/application/empleados_providers.dart';
import '../../../empleados/domain/entidades/empleado.dart';
import '../../application/negocio_providers.dart';

class SeccionDescansosWidget extends ConsumerWidget {
  const SeccionDescansosWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empleados = ref.watch(empleadosAdminNotifierProvider);

    return _Card(
      titulo: 'Descansos fijos por empleado',
      icono: Icons.coffee_outlined,
      child: empleados.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (lista) {
          final activos = lista.where((e) => e.activo).toList();
          if (activos.isEmpty) return const Text('No hay empleados activos.');
          return Column(
            children: activos.map((e) => _FilaDescanso(empleado: e)).toList(),
          );
        },
      ),
    );
  }
}

class _FilaDescanso extends ConsumerStatefulWidget {
  const _FilaDescanso({required this.empleado});
  final Empleado empleado;

  @override
  ConsumerState<_FilaDescanso> createState() => _FilaDescansoState();
}

class _FilaDescansoState extends ConsumerState<_FilaDescanso> {
  TimeOfDay _hora = const TimeOfDay(hour: 14, minute: 0);
  int _minutos = 30;
  bool _guardando = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.empleado.nombreCompleto,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.access_time, size: 16),
            label: Text('${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}'),
            onPressed: () async {
              final t = await showTimePicker(context: context, initialTime: _hora);
              if (t != null) setState(() => _hora = t);
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _minutos,
            items: const [10, 15, 20, 30, 45, 60, 90, 120]
                .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                .toList(),
            onChanged: (v) => setState(() => _minutos = v ?? 30),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _guardando
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined, color: AppColors.primary),
            onPressed: _guardando ? null : _guardar,
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final hora = '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';
      await ref
          .read(actualizarDescansoProvider)
          .ejecutar(widget.empleado.id, hora, _minutos);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Descanso guardado para ${widget.empleado.nombre}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
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
            Icon(icono, color: AppColors.primary),
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
