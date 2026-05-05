// Sección "Cierre anual" del panel Negocio.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../application/negocio_providers.dart';

class SeccionCierreAnualWidget extends ConsumerStatefulWidget {
  const SeccionCierreAnualWidget({super.key});

  @override
  ConsumerState<SeccionCierreAnualWidget> createState() => _SeccionCierreAnualWidgetState();
}

class _SeccionCierreAnualWidgetState extends ConsumerState<SeccionCierreAnualWidget> {
  DateTime? _inicio;
  DateTime? _fin;
  bool _inicializado = false;
  bool _guardando = false;

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(cierreAnualNotifierProvider);

    return _Card(
      titulo: 'Cierre anual',
      icono: Icons.beach_access_outlined,
      child: estado.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (cierre) {
          if (!_inicializado) {
            _inicio = cierre.fechaInicio == null ? null : DateTime.parse(cierre.fechaInicio!);
            _fin = cierre.fechaFin == null ? null : DateTime.parse(cierre.fechaFin!);
            _inicializado = true;
          }
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _Campo(label: 'Inicio', valor: _inicio, alElegir: (d) => setState(() => _inicio = d))),
                  const SizedBox(width: 12),
                  Expanded(child: _Campo(label: 'Fin', valor: _fin, alElegir: (d) => setState(() => _fin = d))),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar cierre anual'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final inicioStr = _inicio == null ? null : DateFormat('yyyy-MM-dd').format(_inicio!);
      final finStr = _fin == null ? null : DateFormat('yyyy-MM-dd').format(_fin!);
      await ref.read(cierreAnualNotifierProvider.notifier).guardar(inicioStr, finStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cierre anual guardado')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

class _Campo extends StatelessWidget {
  const _Campo({required this.label, required this.valor, required this.alElegir});
  final String label;
  final DateTime? valor;
  final ValueChanged<DateTime?> alElegir;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: valor ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (d != null) alElegir(d);
      },
      onLongPress: () => alElegir(null),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(
              valor == null ? 'Sin fecha' : DateFormat.yMMMd('es').format(valor!),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
