// Bottom-sheet de creación rápida de cita lanzado al pulsar el "+" de un hueco
// libre en la cuadrícula de la agenda admin.
//
// Recibe empleado, fecha y el RANGO del hueco (horaInicio sugerida +
// horaFinHueco). La hora es editable dentro de ese rango: el usuario puede
// pulsar el campo y elegir cualquier hora libre del hueco con `showTimePicker`.
// Esto evita la limitación de que solo se pudiera crear en la primera hora
// disponible.
//
// Reutiliza `crearWalkInProvider` para no duplicar la llamada al backend.
// Al éxito devuelve `true` y recarga la agenda.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/errors/api_exception.dart';
import '../../../../../../core/theme/app_colores.dart';
import '../../../../servicios/application/servicios_providers.dart';
import '../../../application/agenda_providers.dart';
import '../../../domain/entidades/cita.dart';

class BottomSheetCrearCitaRapida extends ConsumerStatefulWidget {
  const BottomSheetCrearCitaRapida({
    super.key,
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.fecha,
    required this.horaInicio,
    required this.horaFinHueco,
  });

  final int idEmpleado;
  final String nombreEmpleado;
  final DateTime fecha;
  // Inicio sugerido (inicio del hueco) — el usuario puede cambiarlo.
  final String horaInicio;      // "HH:mm"
  // Fin del hueco libre — la hora elegida no puede ser >= a esto.
  final String horaFinHueco;    // "HH:mm"

  @override
  ConsumerState<BottomSheetCrearCitaRapida> createState() => _BottomSheetCrearCitaRapidaState();
}

class _BottomSheetCrearCitaRapidaState extends ConsumerState<BottomSheetCrearCitaRapida> {
  final _form = GlobalKey<FormState>();
  int? _idServicio;
  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  final _telefono = TextEditingController();
  final _nota = TextEditingController();
  bool _enviando = false;

  // Hora actualmente elegida. Arranca con la propuesta inicial del hueco.
  late TimeOfDay _hora;

  @override
  void initState() {
    super.initState();
    _hora = _parse(widget.horaInicio);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellidos.dispose();
    _telefono.dispose();
    _nota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviciosState = ref.watch(serviciosAdminNotifierProvider);
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _drag(),
                const SizedBox(height: 8),
                Text(
                  'Nueva cita',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.nombreEmpleado}  ·  ${DateFormat.yMMMd('es').format(widget.fecha)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _selectorHora(),
                const SizedBox(height: 12),
                serviciosState.maybeWhen(
                  orElse: () => const LinearProgressIndicator(),
                  data: (lista) => DropdownButtonFormField<int>(
                    initialValue: _idServicio,
                    decoration: _dec('Servicio'),
                    items: lista
                        .where((s) => s.activo)
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.nombre} (${s.duracionMinutos} min)'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _idServicio = v),
                    validator: (v) => v == null ? 'Selecciona un servicio' : null,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGlow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cliente sin cuenta (walk-in)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombre,
                  decoration: _dec('Nombre'),
                  validator: _validarTexto,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _apellidos,
                  decoration: _dec('Apellidos'),
                  validator: _validarTexto,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefono,
                  decoration: _dec('Teléfono (opcional)'),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(r'^[0-9 ]+$').hasMatch(v.trim())) {
                      return 'Solo números';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nota,
                  decoration: _dec('Nota (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _enviando ? null : _crear,
                    child: _enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Crear cita',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Selector de hora editable. Muestra la franja libre del hueco como guía
  // y abre `showTimePicker` al pulsar.
  Widget _selectorHora() {
    final horaTxt = _format(_hora);
    return InkWell(
      onTap: _elegirHora,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hora de la cita',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    horaTxt,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Libre ${widget.horaInicio} – ${widget.horaFinHueco}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _elegirHora() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _hora,
      builder: (ctx, child) => MediaQuery(
        // Fuerza formato 24h coherente con el resto de la app.
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null) return;

    // Validamos que la elección quede DENTRO del hueco libre. Si no, avisamos
    // y dejamos la hora previa intacta — no auto-corregimos para que el admin
    // entienda por qué su elección no es válida.
    final eleccionMin = t.hour * 60 + t.minute;
    final inicioMin   = _toMin(widget.horaInicio);
    final finMin      = _toMin(widget.horaFinHueco);
    if (eleccionMin < inicioMin || eleccionMin >= finMin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Esa hora cae fuera del hueco libre '
              '(${widget.horaInicio} – ${widget.horaFinHueco}).',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _hora = t);
  }

  Widget _drag() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  String? _validarTexto(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(v.trim())) {
      return 'Solo letras';
    }
    return null;
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  static TimeOfDay _parse(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  static String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static int _toMin(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  Future<void> _crear() async {
    if (!_form.currentState!.validate()) return;

    final citaDateTime = DateTime(
      widget.fecha.year, widget.fecha.month, widget.fecha.day,
      _hora.hour, _hora.minute,
    );
    if (!citaDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes reservar una hora que ya ha pasado.')),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      final datos = DatosWalkIn(
        idEmpleado: widget.idEmpleado,
        idServicio: _idServicio!,
        fecha: DateFormat('yyyy-MM-dd').format(widget.fecha),
        horaInicio: _format(_hora),
        nombreInvitado: _nombre.text,
        apellidosInvitado: _apellidos.text,
        telefonoInvitado: _telefono.text.trim().isEmpty ? null : _telefono.text,
        nota: _nota.text.trim().isEmpty ? null : _nota.text,
      );
      await ref.read(crearWalkInProvider).ejecutar(datos);
      await ref.read(agendaAdminNotifierProvider.notifier).recargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita creada')),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.failure.mensaje)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}
