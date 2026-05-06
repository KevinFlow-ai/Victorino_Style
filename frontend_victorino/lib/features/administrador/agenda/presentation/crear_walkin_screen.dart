// Pantalla para crear una cita walk-in desde el panel del admin.
//
// Permite elegir empleado, servicio, fecha, hora y datos del cliente
// (registrado o invitado, XOR).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/theme/app_colores.dart';
import '../../empleados/application/empleados_providers.dart';
import '../../negocio/application/negocio_providers.dart';
import '../../negocio/domain/entidades/horario_peluqueria.dart';
import '../../servicios/application/servicios_providers.dart';
import '../application/agenda_providers.dart';
import '../domain/entidades/cita.dart';

class CrearWalkInScreen extends ConsumerStatefulWidget {
  const CrearWalkInScreen({super.key});

  @override
  ConsumerState<CrearWalkInScreen> createState() => _CrearWalkInScreenState();
}

class _CrearWalkInScreenState extends ConsumerState<CrearWalkInScreen> {
  final _form = GlobalKey<FormState>();
  int? _idEmpleado;
  int? _idServicio;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  bool _modoInvitado = true;
  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  final _telefono = TextEditingController();
  final _nota = TextEditingController();
  bool _enviando = false;

  @override
  Widget build(BuildContext context) {
    final empleadosState = ref.watch(empleadosAdminNotifierProvider);
    final serviciosState = ref.watch(serviciosAdminNotifierProvider);
    // Nos aseguramos de observar el horario para que esté cargado si lo necesitamos en el error.
    ref.watch(horarioNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Nueva cita',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textMain)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            empleadosState.maybeWhen(
              orElse: () => const LinearProgressIndicator(),
              data: (lista) => DropdownButtonFormField<int>(
                initialValue: _idEmpleado,
                decoration: _decoracion('Empleado'),
                items: lista.where((e) => e.activo)
                    .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombreCompleto)))
                    .toList(),
                onChanged: (v) => setState(() => _idEmpleado = v),
                validator: (v) => v == null ? 'Selecciona un empleado' : null,
              ),
            ),
            const SizedBox(height: 12),
            serviciosState.maybeWhen(
              orElse: () => const LinearProgressIndicator(),
              data: (lista) => DropdownButtonFormField<int>(
                initialValue: _idServicio,
                decoration: _decoracion('Servicio'),
                items: lista.where((s) => s.activo)
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
            Row(
              children: [
                Expanded(
                  child: _BotonSelector(
                    icono: Icons.calendar_month,
                    etiqueta: DateFormat.yMMMd('es').format(_fecha),
                    alPulsar: () async {
                      final f = await showDatePicker(
                        context: context,
                        initialDate: _fecha,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (f != null) setState(() => _fecha = f);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BotonSelector(
                    icono: Icons.access_time,
                    etiqueta: '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}',
                    alPulsar: () async {
                      final t = await showTimePicker(context: context, initialTime: _hora);
                      if (t != null) setState(() => _hora = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Toggle cliente registrado / invitado.
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Walk-in (Cliente sin cuenta)')),
                // ButtonSegment(value: false, label: Text('Cliente registrado')),
              ],
              selected: {_modoInvitado},
              onSelectionChanged: (s) => setState(() => _modoInvitado = s.first),
            ),
            const SizedBox(height: 12),
            if (_modoInvitado) ...[
              TextFormField(
                controller: _nombre,
                decoration: _decoracion('Nombre'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Campo obligatorio';
                  }

                  final texto = v.trim();
                  final regex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$');

                  if (!regex.hasMatch(texto)) {
                    return 'Solo se permiten letras';
                  }

                  return null;
                },
              ),

              TextFormField(
                controller: _apellidos,
                decoration: _decoracion('Apellidos'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Campo bligatorio';
                  }

                  final texto = v.trim();
                  final regex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$');

                  if (!regex.hasMatch(texto)) {
                    return 'Solo se permiten letras';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _telefono,
                decoration: _decoracion('Teléfono (opcional)'),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return null; // Es opcional
                  }

                  final telefono = v.trim();
                  final regex = RegExp(r'^[0-9 ]+$');

                  if (!regex.hasMatch(telefono)) {
                    return 'El teléfono solo puede contener números';
                  }

                  return null; // Si el teléfono es válido
                },
              ),

            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'TODO: selector de cliente registrado por correo o teléfono. '
                  'Por ahora usa el modo Walk-in.',
                  style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nota,
              decoration: _decoracion('Nota (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _enviando ? null : _crear,
              child: _enviando
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Crear cita'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crear() async {
    if (!_form.currentState!.validate()) return;
    if (!_modoInvitado) return; // todavía no soportado

    final ahora = DateTime.now();
    final citaDateTime = DateTime(
      _fecha.year, _fecha.month, _fecha.day, _hora.hour, _hora.minute,
    );
    if (!citaDateTime.isAfter(ahora)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes reservar una hora que ya ha pasado.')),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      final datos = DatosWalkIn(
        idEmpleado: _idEmpleado!,
        idServicio: _idServicio!,
        fecha: DateFormat('yyyy-MM-dd').format(_fecha),
        horaInicio: '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}',
        nombreInvitado: _nombre.text,
        apellidosInvitado: _apellidos.text,
        telefonoInvitado: _telefono.text.trim().isEmpty ? null : _telefono.text,
        nota: _nota.text.trim().isEmpty ? null : _nota.text,
      );
      await ref.read(crearWalkInProvider).ejecutar(datos);
      await ref.read(agendaAdminNotifierProvider.notifier).recargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita creada')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        String mensaje = e.failure.mensaje;

        // Si el error es por horario, intentamos dar más detalle
        if (mensaje.contains('fuera del horario de apertura')) {
          final horario = ref.read(horarioNotifierProvider).asData?.value;
          if (horario != null) {
            final textoHoras = _getHorarioTexto(horario, _fecha);
            if (textoHoras != null) {
              mensaje = 'La cita debe ser $textoHoras';
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// Devuelve un texto descriptivo del horario para un día concreto.
  String? _getHorarioTexto(HorarioPeluqueria h, DateTime fecha) {
    final (String? apertura, String? cierre) = switch (fecha.weekday) {
      DateTime.monday => (h.aperturaLunes, h.cierreLunes),
      DateTime.tuesday => (h.aperturaMartes, h.cierreMartes),
      DateTime.wednesday => (h.aperturaMiercoles, h.cierreMiercoles),
      DateTime.thursday => (h.aperturaJueves, h.cierreJueves),
      DateTime.friday => (h.aperturaViernes, h.cierreViernes),
      DateTime.saturday => (h.aperturaSabado, h.cierreSabado),
      DateTime.sunday => (h.aperturaDomingo, h.cierreDomingo),
      _ => (null, null),
    };

    if (apertura == null || cierre == null) return null;
    return 'entre las $apertura y las $cierre';
  }

  InputDecoration _decoracion(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}

class _BotonSelector extends StatelessWidget {
  const _BotonSelector({required this.icono, required this.etiqueta, required this.alPulsar});
  final IconData icono;
  final String etiqueta;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icono, size: 16),
      label: Text(etiqueta),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: alPulsar,
    );
  }
}
