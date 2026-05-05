// Sección "Festivos puntuales".
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../application/negocio_providers.dart';
import '../../domain/entidades/horario_peluqueria.dart';

class SeccionFestivosWidget extends ConsumerWidget {
  const SeccionFestivosWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(festivosNotifierProvider);

    return _Card(
      titulo: 'Festivos y días cerrados',
      icono: Icons.event_busy_outlined,
      child: estado.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (lista) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Aún no hay festivos registrados.'),
              )
            else
              ...lista.map((f) => _Fila(festivo: f)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _abrirDialogoNuevo(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Añadir festivo'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirDialogoNuevo(BuildContext context, WidgetRef ref) async {
    DateTime? fecha;
    final descripcion = TextEditingController();
    var tipo = TipoFestivo.local;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Nuevo festivo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(fecha == null ? 'Selecciona una fecha' : DateFormat.yMMMd('es').format(fecha!)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final f = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (f != null) setSt(() => fecha = f);
                },
              ),
              TextField(
                controller: descripcion,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              DropdownButton<TipoFestivo>(
                value: tipo,
                isExpanded: true,
                onChanged: (v) => setSt(() => tipo = v ?? TipoFestivo.local),
                items: TipoFestivo.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(_etiqueta(t))))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (resultado != true || fecha == null || descripcion.text.trim().isEmpty) return;
    try {
      final iso = DateFormat('yyyy-MM-dd').format(fecha!);
      await ref.read(crearFestivoProvider).ejecutar(iso, descripcion.text.trim(), tipo);
      await ref.read(festivosNotifierProvider.notifier).recargar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Festivo creado')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _etiqueta(TipoFestivo t) => switch (t) {
        TipoFestivo.nacional => 'Nacional',
        TipoFestivo.autonomico => 'Autonómico',
        TipoFestivo.local => 'Local',
        TipoFestivo.vacaciones => 'Vacaciones',
        TipoFestivo.mantenimiento => 'Mantenimiento',
      };
}

class _Fila extends ConsumerWidget {
  const _Fila({required this.festivo});
  final Festivo festivo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = DateFormat.yMMMd('es').format(DateTime.parse(festivo.fecha));
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_busy, color: AppColors.error),
      title: Text(festivo.descripcion),
      subtitle: Text('$fecha · ${festivo.tipo.name.toUpperCase()}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: AppColors.error),
        onPressed: () async {
          await ref.read(eliminarFestivoProvider).ejecutar(festivo.id);
          await ref.read(festivosNotifierProvider.notifier).recargar();
        },
      ),
    );
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
