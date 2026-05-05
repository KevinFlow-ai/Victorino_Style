// Sección "Horario semanal" del panel Negocio. Muestra los 7 días con sus horas
// de apertura y cierre. Cada par puede ser null = día cerrado.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../application/negocio_providers.dart';
import '../../domain/entidades/horario_peluqueria.dart';

class SeccionHorarioWidget extends ConsumerWidget {
  const SeccionHorarioWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(horarioNotifierProvider);

    return _Card(
      titulo: 'Horario semanal',
      icono: Icons.schedule,
      child: estado.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (horario) => _Editor(horario: horario),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.horario});
  final HorarioPeluqueria horario;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late TimeOfDay? _aperturaLunes,    _cierreLunes;
  late TimeOfDay? _aperturaMartes,   _cierreMartes;
  late TimeOfDay? _aperturaMiercoles,_cierreMiercoles;
  late TimeOfDay? _aperturaJueves,   _cierreJueves;
  late TimeOfDay? _aperturaViernes,  _cierreViernes;
  late TimeOfDay? _aperturaSabado,   _cierreSabado;
  late TimeOfDay? _aperturaDomingo,  _cierreDomingo;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final h = widget.horario;
    _aperturaLunes = _parse(h.aperturaLunes);     _cierreLunes = _parse(h.cierreLunes);
    _aperturaMartes = _parse(h.aperturaMartes);   _cierreMartes = _parse(h.cierreMartes);
    _aperturaMiercoles = _parse(h.aperturaMiercoles); _cierreMiercoles = _parse(h.cierreMiercoles);
    _aperturaJueves = _parse(h.aperturaJueves);   _cierreJueves = _parse(h.cierreJueves);
    _aperturaViernes = _parse(h.aperturaViernes); _cierreViernes = _parse(h.cierreViernes);
    _aperturaSabado = _parse(h.aperturaSabado);   _cierreSabado = _parse(h.cierreSabado);
    _aperturaDomingo = _parse(h.aperturaDomingo); _cierreDomingo = _parse(h.cierreDomingo);
  }

  TimeOfDay? _parse(String? hora) {
    if (hora == null || hora.isEmpty) return null;
    final p = hora.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String? _format(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dias = [
      ('Lunes',     _aperturaLunes,     _cierreLunes,
          (TimeOfDay? a) => setState(() => _aperturaLunes = a),
          (TimeOfDay? c) => setState(() => _cierreLunes = c)),
      ('Martes',    _aperturaMartes,    _cierreMartes,
          (TimeOfDay? a) => setState(() => _aperturaMartes = a),
          (TimeOfDay? c) => setState(() => _cierreMartes = c)),
      ('Miércoles', _aperturaMiercoles, _cierreMiercoles,
          (TimeOfDay? a) => setState(() => _aperturaMiercoles = a),
          (TimeOfDay? c) => setState(() => _cierreMiercoles = c)),
      ('Jueves',    _aperturaJueves,    _cierreJueves,
          (TimeOfDay? a) => setState(() => _aperturaJueves = a),
          (TimeOfDay? c) => setState(() => _cierreJueves = c)),
      ('Viernes',   _aperturaViernes,   _cierreViernes,
          (TimeOfDay? a) => setState(() => _aperturaViernes = a),
          (TimeOfDay? c) => setState(() => _cierreViernes = c)),
      ('Sábado',    _aperturaSabado,    _cierreSabado,
          (TimeOfDay? a) => setState(() => _aperturaSabado = a),
          (TimeOfDay? c) => setState(() => _cierreSabado = c)),
      ('Domingo',   _aperturaDomingo,   _cierreDomingo,
          (TimeOfDay? a) => setState(() => _aperturaDomingo = a),
          (TimeOfDay? c) => setState(() => _cierreDomingo = c)),
    ];

    return Column(
      children: [
        ...dias.map((d) => _FilaDia(
              dia: d.$1,
              apertura: d.$2,
              cierre: d.$3,
              alCambiarApertura: d.$4,
              alCambiarCierre: d.$5,
            )),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(_guardando ? 'Guardando...' : 'Guardar horario'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final actualizado = HorarioPeluqueria(
        idPeluqueria: widget.horario.idPeluqueria,
        nombre: widget.horario.nombre,
        aperturaLunes: _format(_aperturaLunes),     cierreLunes: _format(_cierreLunes),
        aperturaMartes: _format(_aperturaMartes),   cierreMartes: _format(_cierreMartes),
        aperturaMiercoles: _format(_aperturaMiercoles), cierreMiercoles: _format(_cierreMiercoles),
        aperturaJueves: _format(_aperturaJueves),   cierreJueves: _format(_cierreJueves),
        aperturaViernes: _format(_aperturaViernes), cierreViernes: _format(_cierreViernes),
        aperturaSabado: _format(_aperturaSabado),   cierreSabado: _format(_cierreSabado),
        aperturaDomingo: _format(_aperturaDomingo), cierreDomingo: _format(_cierreDomingo),
      );
      await ref.read(horarioNotifierProvider.notifier).guardar(actualizado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario guardado')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

class _FilaDia extends StatelessWidget {
  const _FilaDia({
    required this.dia,
    required this.apertura,
    required this.cierre,
    required this.alCambiarApertura,
    required this.alCambiarCierre,
  });

  final String dia;
  final TimeOfDay? apertura;
  final TimeOfDay? cierre;
  final ValueChanged<TimeOfDay?> alCambiarApertura;
  final ValueChanged<TimeOfDay?> alCambiarCierre;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(dia, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: _Selector(label: 'Apertura', valor: apertura, alCambiar: alCambiarApertura)),
          const SizedBox(width: 8),
          Expanded(child: _Selector(label: 'Cierre', valor: cierre, alCambiar: alCambiarCierre)),
        ],
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({required this.label, required this.valor, required this.alCambiar});
  final String label;
  final TimeOfDay? valor;
  final ValueChanged<TimeOfDay?> alCambiar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: valor ?? const TimeOfDay(hour: 10, minute: 0),
        );
        if (t != null) alCambiar(t);
      },
      onLongPress: () => alCambiar(null),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(width: 6),
            Text(
              valor == null
                  ? '—'
                  : '${valor!.hour.toString().padLeft(2, '0')}:${valor!.minute.toString().padLeft(2, '0')}',
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
