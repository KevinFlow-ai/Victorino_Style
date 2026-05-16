// Paso 3 del wizard: elegir DÍA y HORA.
// - Chips horizontales con los próximos 30 días (festivos en gris).
// - Botón para abrir el DatePicker (calendario completo).
// - Al elegir día, llama a GET /cliente/citas/disponibilidad y muestra chips de hora.
// - En modo "Cualquiera", debajo de cada chip aparece el nombre del empleado asignado.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colores.dart';
import '../../shared/domain/entidades/hueco.dart';
import '../application/reservar_providers.dart';
import '../application/wizard_notifier.dart';

class Paso3DiaHora extends ConsumerStatefulWidget {
  const Paso3DiaHora({super.key});

  @override
  ConsumerState<Paso3DiaHora> createState() => _Paso3DiaHoraState();
}

class _Paso3DiaHoraState extends ConsumerState<Paso3DiaHora> {
  // Cache local de huecos según fecha seleccionada.
  AsyncValue<List<Hueco>> _huecos = const AsyncValue.data([]);

  @override
  void initState() {
    super.initState();
    // Si entramos con fecha precargada (modo edición), pedimos huecos.
    final f = ref.read(wizardNotifierProvider).datos.fecha;
    if (f != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _cargarHuecos(f));
    }
  }

  Future<void> _cargarHuecos(DateTime fecha) async {
    final estado = ref.read(wizardNotifierProvider);
    final idServicio = estado.datos.idServicio;
    if (idServicio == null) return;

    setState(() => _huecos = const AsyncValue.loading());
    try {
      final lista = await ref.read(obtenerDisponibilidadProvider).ejecutar(
            idServicio: idServicio,
            fecha: fecha,
            idEmpleado: estado.datos.cualquieraDisponible
                ? null
                : estado.datos.idEmpleado,
            idCitaExcluir: estado.idCitaEditar,
          );
      setState(() => _huecos = AsyncValue.data(lista));
    } catch (e, st) {
      setState(() => _huecos = AsyncValue.error(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(wizardNotifierProvider);
    final dias = List<DateTime>.generate(
      31,
      (i) => DateTime.now().add(Duration(days: i)),
    );
    final fechaSel = estado.datos.fecha;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // ----- Selector de día ----------------------------------------------
        Row(
          children: [
            const Expanded(
              child: Text(
                'Elige día',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('Calendario'),
              onPressed: () async {
                final hoy = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: fechaSel ?? hoy,
                  firstDate: hoy,
                  lastDate: hoy.add(const Duration(days: 30)),
                  locale: const Locale('es', 'ES'),
                );
                if (picked != null) {
                  ref.read(wizardNotifierProvider.notifier).setFechaHora(
                      fecha: picked,
                      horaInicio: '',
                      idEmpleadoFallback: estado.datos.idEmpleado);
                  await _cargarHuecos(picked);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dias.length,
            itemBuilder: (_, i) {
              final d = dias[i];
              final seleccionado = fechaSel != null &&
                  d.year == fechaSel.year &&
                  d.month == fechaSel.month &&
                  d.day == fechaSel.day;
              return _ChipDia(
                fecha: d,
                seleccionado: seleccionado,
                onTap: () async {
                  ref.read(wizardNotifierProvider.notifier).setFechaHora(
                      fecha: d,
                      horaInicio: '',
                      idEmpleadoFallback: estado.datos.idEmpleado);
                  await _cargarHuecos(d);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'Elige hora',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // ----- Lista de huecos ----------------------------------------------
        if (fechaSel == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Selecciona primero un día.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          _huecos.when(
            data: (lista) {
              if (lista.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No hay huecos disponibles ese día.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                );
              }
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: lista.map((h) {
                  final isSel = estado.datos.horaInicio == h.horaInicio;
                  return _ChipHora(
                    hueco: h,
                    mostrarNombre: estado.datos.cualquieraDisponible,
                    seleccionado: isSel,
                    onTap: () => ref
                        .read(wizardNotifierProvider.notifier)
                        .setFechaHora(
                          fecha: fechaSel,
                          horaInicio: h.horaInicio,
                          idEmpleadoFallback: estado.datos.cualquieraDisponible
                              ? h.idEmpleado
                              : estado.datos.idEmpleado,
                        ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text('No se pudieron cargar los huecos.',
                      style: TextStyle(color: AppColors.textMuted)),
                  TextButton(
                    onPressed: () => _cargarHuecos(fechaSel),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ----- Sub-widgets ----------------------------------------------------------

class _ChipDia extends StatelessWidget {
  const _ChipDia({
    required this.fecha,
    required this.seleccionado,
    required this.onTap,
  });

  final DateTime fecha;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diaSemana = DateFormat.E('es').format(fecha).toUpperCase();
    final dia = DateFormat.d().format(fecha);
    final mes = DateFormat.MMM('es').format(fecha).toUpperCase();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.accentGlow,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              diaSemana,
              style: TextStyle(
                fontSize: 10,
                color: seleccionado ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              dia,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: seleccionado ? Colors.white : AppColors.textMain,
              ),
            ),
            Text(
              mes,
              style: TextStyle(
                fontSize: 10,
                color: seleccionado ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipHora extends StatelessWidget {
  const _ChipHora({
    required this.hueco,
    required this.mostrarNombre,
    required this.seleccionado,
    required this.onTap,
  });

  final Hueco hueco;
  final bool mostrarNombre;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.accentGlow,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hueco.horaInicioCorta,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: seleccionado ? Colors.white : AppColors.textMain,
              ),
            ),
            if (mostrarNombre)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  hueco.nombreEmpleado,
                  style: TextStyle(
                    fontSize: 10,
                    color: seleccionado ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
