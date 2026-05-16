// ============================================================================
// WizardReservaScreen — contenedor del wizard de 4 pasos
// ----------------------------------------------------------------------------
// Recibe opcionalmente idServicio (preselección desde el catálogo del Home) y/o
// idCitaEditar (modo edición). Pinta la barra de progreso + el paso actual + los
// botones Atrás/Siguiente/Confirmar.
//
// Al confirmar:
//  - Modo nueva → POST /cliente/citas
//  - Modo edición → PUT /cliente/citas/{id}
// Maneja 409 con código CITA_MISMO_DIA / CITA_MISMA_SEMANA / CITA_MISMO_SERVICIO
// mostrando el diálogo contextual. Cualquier otro error → SnackBar.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colores.dart';
import '../../shared/application/citas_cliente_provider.dart';
import '../../shared/application/refrescar_cliente.dart';
import '../application/reservar_providers.dart';
import '../application/wizard_notifier.dart';
import 'paso_1_servicio.dart';
import 'paso_2_empleado.dart';
import 'paso_3_dia_hora.dart';
import 'paso_4_confirmar.dart';
import 'widgets/barra_progreso.dart';
import 'widgets/dialogo_cita_existente.dart';

class WizardReservaScreen extends ConsumerStatefulWidget {
  const WizardReservaScreen({
    super.key,
    this.idServicioPreseleccionado,
    this.idCitaEditar,
  });

  final int? idServicioPreseleccionado;
  // Si != null, entramos en modo edición. Hay que precargar la cita.
  final int? idCitaEditar;

  @override
  ConsumerState<WizardReservaScreen> createState() => _WizardReservaScreenState();
}

class _WizardReservaScreenState extends ConsumerState<WizardReservaScreen> {
  bool _guardando = false;
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo se inicializa UNA vez al montar la pantalla.
    if (_inicializado) return;
    _inicializado = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.idCitaEditar != null) {
        // Modo edición: cargar la cita actual y precargar el wizard.
        final repo = ref.read(citasClienteRepositorioProvider);
        try {
          final cita = await repo.obtenerCita(widget.idCitaEditar!);
          ref.read(wizardNotifierProvider.notifier).precargarParaEdicion(
                idCita: cita.idCita,
                idServicio: cita.idServicio,
                idEmpleado: cita.idEmpleado,
                fecha: cita.fecha,
                horaInicio: cita.horaInicio,
                nota: cita.nota,
              );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo cargar la cita a modificar')),
            );
            context.pop();
          }
        }
      } else {
        // Modo nueva reserva. Si llega idServicio en la URL, lo preseleccionamos.
        ref.read(wizardNotifierProvider.notifier).reiniciar(
              idServicioPreseleccionado: widget.idServicioPreseleccionado,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(wizardNotifierProvider);
    // La flecha del AppBar y el back del sistema retroceden de paso si estamos
    // en mitad del wizard; solo cierran la pantalla cuando ya estamos en el
    // primer paso. Así se evita la incongruencia con los dos "atrás" anteriores.
    final puedeRetrocederPaso = estado.pasoActual > 0;

    return PopScope(
      canPop: !puedeRetrocederPaso,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ref.read(wizardNotifierProvider.notifier).anterior();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(estado.modoEdicion ? 'Modificar cita' : 'Reservar cita'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (puedeRetrocederPaso) {
                ref.read(wizardNotifierProvider.notifier).anterior();
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: Column(
          children: [
            BarraProgreso(pasoActual: estado.pasoActual),
            Expanded(
              child: switch (estado.pasoActual) {
                0 => const Paso1Servicio(),
                1 => const Paso2Empleado(),
                2 => const Paso3DiaHora(),
                _ => const Paso4Confirmar(),
              },
            ),
            _BotonesNavegacion(
              estado: estado,
              guardando: _guardando,
              onSiguiente: _puedeAvanzar(estado)
                  ? () => ref.read(wizardNotifierProvider.notifier).siguiente()
                  : null,
              onConfirmar:
                  estado.pasoActual == 3 && _puedeConfirmar(estado) ? _confirmar : null,
            ),
          ],
        ),
      ),
    );
  }

  bool _puedeAvanzar(EstadoWizard e) {
    return switch (e.pasoActual) {
      0 => e.datos.tieneServicio,
      1 => e.datos.tieneEmpleadoOComodin,
      2 => e.datos.tieneFechaYHora,
      _ => false,
    };
  }

  bool _puedeConfirmar(EstadoWizard e) => e.datos.esCompleto;

  Future<void> _confirmar() async {
    final estado = ref.read(wizardNotifierProvider);
    setState(() => _guardando = true);

    try {
      if (estado.modoEdicion) {
        await ref.read(modificarCitaProvider).ejecutar(
              estado.idCitaEditar!,
              estado.datos,
            );
      } else {
        await ref.read(crearCitaProvider).ejecutar(estado.datos);
      }
      // Invalida próxima cita + historial para que ambas vistas se refresquen
      // sin que el usuario tenga que hacer pull-to-refresh.
      invalidarCitasCliente(ref);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estado.modoEdicion ? 'Cita modificada correctamente' : 'Cita reservada correctamente',
          ),
        ),
      );
      // Volver al Home tras éxito.
      context.go('/cliente/inicio');
    } on ApiException catch (ex) {
      if (!mounted) return;
      final f = ex.failure;
      // 409 con detalles → diálogo contextual.
      if (f is FailureConflicto && f.codigo != null) {
        final idCitaExistente = await mostrarDialogoCitaExistente(context, f);
        if (idCitaExistente != null && mounted) {
          // El usuario pulsó "Modificar esa cita".
          context.go('/cliente/reservar/wizard?idCita=$idCitaExistente');
        }
        return;
      }
      // Resto de errores → SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.mensaje),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

class _BotonesNavegacion extends StatelessWidget {
  const _BotonesNavegacion({
    required this.estado,
    required this.guardando,
    required this.onSiguiente,
    required this.onConfirmar,
  });

  final EstadoWizard estado;
  final bool guardando;
  final VoidCallback? onSiguiente;
  final VoidCallback? onConfirmar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: guardando
                ? null
                : (estado.pasoActual == 3 ? onConfirmar : onSiguiente),
            child: guardando
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    estado.pasoActual == 3
                        ? (estado.modoEdicion
                            ? 'Guardar cambios'
                            : 'Confirmar reserva')
                        : 'Siguiente',
                  ),
          ),
        ),
      ),
    );
  }
}
