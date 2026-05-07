// Sección "Descansos fijos por empleado". Lista los empleados activos y permite
// configurar el descanso diario de cada uno.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../../empleados/application/empleados_providers.dart';
import '../../../empleados/domain/entidades/empleado.dart';
import '../../application/negocio_providers.dart';
import '../../domain/entidades/horario_peluqueria.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal (necesita ser StatefulWidget para rastrear descansos guardados)
// ─────────────────────────────────────────────────────────────────────────────

class SeccionDescansosWidget extends ConsumerStatefulWidget {
  const SeccionDescansosWidget({super.key});

  @override
  ConsumerState<SeccionDescansosWidget> createState() =>
      _SeccionDescansosWidgetState();
}

class _SeccionDescansosWidgetState
    extends ConsumerState<SeccionDescansosWidget> {
  // Registra la hora de descanso de cada empleado DESPUÉS de guardarla.
  // Se usa para validar que no todos coincidan a la misma hora.
  final Map<int, TimeOfDay> _descansosGuardados = {};

  @override
  Widget build(BuildContext context) {
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
            children: activos
                .map((e) => _FilaDescanso(
                      empleado: e,
                      totalEmpleadosActivos: activos.length,
                      descansosGuardados:
                          Map.unmodifiable(_descansosGuardados),
                      onDescansoGuardado: (id, hora) =>
                          setState(() => _descansosGuardados[id] = hora),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fila de un empleado
// ─────────────────────────────────────────────────────────────────────────────

class _FilaDescanso extends ConsumerStatefulWidget {
  const _FilaDescanso({
    required this.empleado,
    required this.totalEmpleadosActivos,
    required this.descansosGuardados,
    required this.onDescansoGuardado,
  });

  final Empleado empleado;
  final int totalEmpleadosActivos;
  // Copia inmutable de los descansos ya guardados de todos los empleados.
  final Map<int, TimeOfDay> descansosGuardados;
  final void Function(int id, TimeOfDay hora) onDescansoGuardado;

  @override
  ConsumerState<_FilaDescanso> createState() => _FilaDescansoState();
}

class _FilaDescansoState extends ConsumerState<_FilaDescanso> {
  late TimeOfDay _hora;
  late int _minutos;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Si el empleado ya tiene descanso guardado en el backend, lo usamos.
    // Si no, usamos los valores por defecto (14:00 y 30 min).
    final horaStr = widget.empleado.horaDescanso;
    if (horaStr != null) {
      final partes = horaStr.split(':');
      _hora = TimeOfDay(
        hour: int.parse(partes[0]),
        minute: int.parse(partes[1]),
      );
    } else {
      _hora = const TimeOfDay(hour: 14, minute: 0);
    }
    _minutos = widget.empleado.duracionDescansoMinutos ?? 30;
  }

  // ── Picker estilo rueda iPhone ────────────────────────────────────────────

  Future<void> _abrirPicker() async {
    int horaSeleccionada = _hora.hour;
    // Redondeamos el minuto al múltiplo de 5 más cercano.
    int minutoSeleccionado = ((_hora.minute + 2) ~/ 5) * 5;
    if (minutoSeleccionado >= 60) minutoSeleccionado = 55;

    final resultado = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setEstado) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          height: 300,
          child: Column(
            children: [
              // Cabecera
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const Text(
                      'Hora del descanso',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(
                        TimeOfDay(
                            hour: horaSeleccionada,
                            minute: minutoSeleccionado),
                      ),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary),
                      child: const Text('Listo'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Ruedas hora : minuto
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: horaSeleccionada),
                        itemExtent: 44,
                        onSelectedItemChanged: (i) =>
                            setEstado(() => horaSeleccionada = i),
                        children: List.generate(
                          24,
                              (i) => Center(
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(':',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: minutoSeleccionado ~/ 5),
                        itemExtent: 44,
                        onSelectedItemChanged: (i) =>
                            setEstado(() => minutoSeleccionado = i * 5),
                        children: List.generate(
                          12,
                              (i) => Center(
                            child: Text(
                              (i * 5).toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (resultado != null) setState(() => _hora = resultado);
  }

  /*
      Picker estilo rueda/engranaje iPhone, pero las horas en formato 24 y los
      minutos en formato desde 00 01 02 03 hasta el 59. Y con croll infinito (loop)
      Tanto en las horas. como en los minutos

      Código completo con scroll infinito (horas 00–23 y minutos 00–59)


  Future<void> _abrirPicker() async {
  int horaSeleccionada = _hora.hour;
  int minutoSeleccionado = _hora.minute;

  final resultado = await showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (_, setEstado) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        height: 300,
        child: Column(
          children: [
            // Cabecera
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const Text(
                    'Hora del descanso',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(
                      TimeOfDay(
                        hour: horaSeleccionada,
                        minute: minutoSeleccionado,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Pickers
            Expanded(
              child: Row(
                children: [
                  // HORAS (00–23) con scroll infinito
                  Expanded(
                    child: CupertinoPicker(
                      looping: true,
                      scrollController: FixedExtentScrollController(
                        initialItem: horaSeleccionada,
                      ),
                      itemExtent: 44,
                      onSelectedItemChanged: (i) {
                        setEstado(() => horaSeleccionada = i % 24);
                      },
                      children: List.generate(
                        240, // 24 * 10 para scroll infinito
                        (i) => Center(
                          child: Text(
                            (i % 24).toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Text(
                    ':',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),

                  // MINUTOS (00–59) con scroll infinito
                  Expanded(
                    child: CupertinoPicker(
                      looping: true,
                      scrollController: FixedExtentScrollController(
                        initialItem: minutoSeleccionado,
                      ),
                      itemExtent: 44,
                      onSelectedItemChanged: (i) {
                        setEstado(() => minutoSeleccionado = i % 60);
                      },
                      children: List.generate(
                        600, // 60 * 10 para scroll infinito
                        (i) => Center(
                          child: Text(
                            (i % 60).toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (resultado != null) {
    setState(() => _hora = resultado);
  }
}

   */
  // ── Build ─────────────────────────────────────────────────────────────────

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
            label: Text(
                '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}'),
            onPressed: _abrirPicker,
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _minutos,
            items: const [10, 15, 20, 30, 45, 60] // INTERVALOS PARA LOS DESCANSOS
                .map((m) =>
                    DropdownMenuItem(value: m, child: Text('$m min')))
                .toList(),
            onChanged: (v) => setState(() => _minutos = v ?? 30),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined, color: AppColors.primary),
            onPressed: _guardando ? null : _guardar,
          ),
        ],
      ),
    );
  }

  // ── Guardar con validaciones ──────────────────────────────────────────────

  Future<void> _guardar() async {
    // Validación 1: la hora debe estar dentro del horario de apertura.
    final horario = ref.read(horarioNotifierProvider).asData?.value;
    if (horario != null && !_estaEnHorarioApertura(_hora, horario)) {
      final rango = _textoRangoHorario(horario);
      _snack('El descanso debe estar dentro del horario laboral'
          '${rango.isNotEmpty ? ' ($rango)' : ''}.');
      return;
    }

    // Validación 2: no pueden coincidir todos los empleados a la misma hora.
    if (_todosCoinciden(_hora)) {
      _snack('No se puede poner a todos los empleados en descanso a la misma '
          'hora. Al menos uno debe permanecer trabajando.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final horaStr =
          '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';
      await ref
          .read(actualizarDescansoProvider)
          .ejecutar(widget.empleado.id, horaStr, _minutos);

      widget.onDescansoGuardado(widget.empleado.id, _hora);

      if (mounted) {
        _snack('Descanso guardado para ${widget.empleado.nombre}');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ── Lógica de validación ──────────────────────────────────────────────────

  /// Verdadero si [hora] cae dentro del rango de apertura de algún día laborable.
  bool _estaEnHorarioApertura(TimeOfDay hora, HorarioPeluqueria h) {
    final min = hora.hour * 60 + hora.minute;

    bool enRango(String? apertura, String? cierre) {
      if (apertura == null || cierre == null) return false;
      final pA = apertura.split(':');
      final pC = cierre.split(':');
      final aMin = int.parse(pA[0]) * 60 + int.parse(pA[1]);
      final cMin = int.parse(pC[0]) * 60 + int.parse(pC[1]);
      return min >= aMin && min < cMin;
    }

    return enRango(h.aperturaLunes, h.cierreLunes) ||
        enRango(h.aperturaMartes, h.cierreMartes) ||
        enRango(h.aperturaMiercoles, h.cierreMiercoles) ||
        enRango(h.aperturaJueves, h.cierreJueves) ||
        enRango(h.aperturaViernes, h.cierreViernes) ||
        enRango(h.aperturaSabado, h.cierreSabado) ||
        enRango(h.aperturaDomingo, h.cierreDomingo);
  }

  /// Devuelve texto "entre las HH:mm y las HH:mm" con el rango global
  /// (mínimo de aperturas, máximo de cierres) para mostrar en el error.
  String _textoRangoHorario(HorarioPeluqueria h) {
    int? minAp;
    int? maxCi;

    void actualizar(String? apertura, String? cierre) {
      if (apertura == null || cierre == null) return;
      final pA = apertura.split(':');
      final pC = cierre.split(':');
      final aMin = int.parse(pA[0]) * 60 + int.parse(pA[1]);
      final cMin = int.parse(pC[0]) * 60 + int.parse(pC[1]);
      if (minAp == null || aMin < minAp!) minAp = aMin;
      if (maxCi == null || cMin > maxCi!) maxCi = cMin;
    }

    actualizar(h.aperturaLunes, h.cierreLunes);
    actualizar(h.aperturaMartes, h.cierreMartes);
    actualizar(h.aperturaMiercoles, h.cierreMiercoles);
    actualizar(h.aperturaJueves, h.cierreJueves);
    actualizar(h.aperturaViernes, h.cierreViernes);
    actualizar(h.aperturaSabado, h.cierreSabado);
    actualizar(h.aperturaDomingo, h.cierreDomingo);

    if (minAp == null || maxCi == null) return '';

    String fmt(int totalMin) =>
        '${(totalMin ~/ 60).toString().padLeft(2, '0')}:${(totalMin % 60).toString().padLeft(2, '0')}';

    return 'entre las ${fmt(minAp!)} y las ${fmt(maxCi!)}';
  }

  /// Verdadero si, al guardar [nuevaHora] para este empleado,
  /// TODOS los empleados activos quedan con la misma hora de descanso.
  /// Solo evalúa cuando tenemos datos guardados de todos.
  bool _todosCoinciden(TimeOfDay nuevaHora) {
    if (widget.totalEmpleadosActivos <= 1) return false;

    final tentativo = Map<int, TimeOfDay>.from(widget.descansosGuardados)
      ..[widget.empleado.id] = nuevaHora;

    // Sin datos completos no podemos asegurar el conflicto → dejar pasar.
    if (tentativo.length < widget.totalEmpleadosActivos) return false;

    return tentativo.values.toSet().length == 1;
  }

  void _snack(String mensaje) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(mensaje)));
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta contenedora reutilizable
// ─────────────────────────────────────────────────────────────────────────────

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
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
