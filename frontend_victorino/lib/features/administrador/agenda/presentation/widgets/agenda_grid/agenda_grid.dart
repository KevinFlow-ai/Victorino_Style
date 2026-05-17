// Cuadrícula temporal de la agenda admin (eje Y = horas, eje X = peluqueros).
//
// Este widget es 100 % presentación: recibe los datos ya combinados desde la
// pantalla y se encarga del layout, el scroll sincronizado y el posicionamiento
// absoluto de las citas. La aritmética temporal vive en `agenda_grid_helpers`.
//
// Estructura visual:
//
//   ┌──────────────────────────────────────────────────┐
//   │ TIME │ [Marco] [Elena] [Carlos] [Lucía] …       │ ← encabezado
//   ├──────┼───────────────────────────────────────────┤
//   │10:00 │ ░░cita░░  ░░cita░░  ░░+░░  ░░cita░░      │
//   │10:15 │                                           │
//   │10:30 │ ░░+░░    ░░descanso░░  ░░cita░░          │
//   │ …    │                                           │
//   └──────┴───────────────────────────────────────────┘
//     ↑ fijo                ↑ scroll horizontal compartido con el encabezado
//   ambos hacen scroll vertical conjunto.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/theme/app_colores.dart';
import '../../../../empleados/domain/entidades/empleado.dart';
import '../../../domain/entidades/cita.dart';
import 'agenda_grid_helpers.dart';

// ─────────────────────────── Constantes visuales ───────────────────────────

const double _kAltoSlot       = 40.0;  // px por cada 15 min, el espacio entre los minutos
const double _kAnchoColumna   = 170.0;
const double _kAnchoColHoras  = 56.0;
const double _kAltoEncabezado = 64.0;
const int    _kSlotMin        = 15;
// Margen superior interno del grid: deja "respirar" la primera hora para
// que su etiqueta no quede pegada al borde de la tarjeta de encabezado.
const double _kPadTop         = 5.0;
// Margen inferior interno del grid: pequeño, solo cosmético, para que la
// última hora no quede pegada al borde inferior del contenedor del grid.
// La separación con la bottom navigation la garantiza el Scaffold padre
// (su `bottomNavigationBar` se resta del `body`), no este padding.
const double _kPadBottom      = 16.0;

// Paleta complementaria al AppColors actual. Se mantienen aquí para no
// "ensuciar" `AppColors` con tonos específicos de la agenda. Si más adelante
// se reutilizan, se promocionan a la paleta global.
const Color _kFondoGrid = Color(0xFFEFEDF3);
const Color _kFondoCol  = Color(0xFFF7F5FA);
const Color _kLineaHora = Color(0xFFE2E0E8);
const Color _kHoraTenue = Color(0xFFB5B5C3);

// Colores por estado de cita (acento lateral + fondo del badge).
class _ColorEstado {
  const _ColorEstado(this.acento, this.tagFondo, this.tagTexto);
  final Color acento;
  final Color tagFondo;
  final Color tagTexto;
}

_ColorEstado _coloresEstado(EstadoCita e) {
  switch (e) {
    case EstadoCita.confirmada:
      return const _ColorEstado(Color(0xFF6B3FD4), Color(0xFFE9DEFF), Color(0xFF6B3FD4));
    case EstadoCita.enProceso:
      return const _ColorEstado(Color(0xFF0FA89B), Color(0xFFB8F0E8), Color(0xFF0FA89B));
    case EstadoCita.completada:
      return const _ColorEstado(Color(0xFF787885), Color(0xFFEAEAEF), Color(0xFF555560));
    case EstadoCita.canceladaCliente:
    case EstadoCita.canceladaPeluqueria:
      return const _ColorEstado(Color(0xFFD63384), Color(0xFFFFE0EC), Color(0xFFD63384));
    case EstadoCita.noPresentado:
      return const _ColorEstado(Color(0xFFE8770E), Color(0xFFFFE4CC), Color(0xFFE8770E));
  }
}

String _etiquetaEstado(EstadoCita e) {
  return switch (e) {
    EstadoCita.confirmada          => 'CONFIRMADA',
    EstadoCita.enProceso           => 'EN CURSO',
    EstadoCita.completada          => 'COMPLETADA',
    EstadoCita.canceladaCliente    => 'CANCELADA',
    EstadoCita.canceladaPeluqueria => 'CANCELADA',
    EstadoCita.noPresentado        => 'NO ASISTIÓ',
  };
}

bool _estadoAtenuado(EstadoCita e) {
  return e == EstadoCita.canceladaCliente ||
      e == EstadoCita.canceladaPeluqueria ||
      e == EstadoCita.noPresentado;
}

// ───────────────────────── Widget principal ─────────────────────────

// Callback que dispara la pantalla al pulsar un "+". Recibe la información
// suficiente para abrir el bottom-sheet sin que el grid conozca rutas
// ni providers.
typedef OnHuecoPulsado = void Function({
required int idEmpleado,
required String nombreEmpleado,
required DateTime fecha,
// Hora inicial sugerida (inicio del hueco), alineada al slot.
required String horaInicio,
// Límite superior del hueco: al pulsar el "+" el usuario podrá elegir
// cualquier hora dentro de [horaInicio, horaFinHueco) para encajar
// la cita a la hora exacta que pida el cliente.
required String horaFinHueco,
});

class AgendaGrid extends StatefulWidget {
  const AgendaGrid({
    super.key,
    required this.fecha,
    required this.rango,
    required this.empleados,
    required this.citas,
    required this.onHuecoPulsado,
    this.anchoColumna = _kAnchoColumna, // Valor por defecto 170.0
  });

  final DateTime fecha;
  final RangoHorario rango;
  final List<Empleado> empleados;
  final List<CitaAdmin> citas;
  final OnHuecoPulsado onHuecoPulsado;
  final double anchoColumna;

  @override
  State<AgendaGrid> createState() => _AgendaGridState();
}

class _AgendaGridState extends State<AgendaGrid> {
  // Tres controladores: vertical (compartido) y dos horizontales sincronizados
  // mediante listeners cruzados con un flag para evitar bucle infinito.
  final _vertical   = ScrollController();
  final _horHeader  = ScrollController();
  final _horBody    = ScrollController();
  bool _sincronizando = false;

  // Timer que dispara un setState cada minuto para recalcular el estado
  // visual de las citas (CONFIRMADA → EN_PROCESO → COMPLETADA). El cálculo
  // real lo hace `estadoEfectivoCita` en helpers; este timer solo provoca
  // el rebuild.
  Timer? _tickEstados;
  DateTime _ahora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _horHeader.addListener(() {
      if (_sincronizando) return;
      if (_horBody.hasClients && _horBody.offset != _horHeader.offset) {
        _sincronizando = true;
        _horBody.jumpTo(_horHeader.offset);
        _sincronizando = false;
      }
    });
    _horBody.addListener(() {
      if (_sincronizando) return;
      if (_horHeader.hasClients && _horHeader.offset != _horBody.offset) {
        _sincronizando = true;
        _horHeader.jumpTo(_horBody.offset);
        _sincronizando = false;
      }
    });
    // Tick cada 60 s. Suficiente para que una cita pase a EN_PROCESO o
    // COMPLETADA con poco retardo. No martillamos al backend: solo
    // recalculamos en memoria.
    _tickEstados = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() => _ahora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tickEstados?.cancel();
    _vertical.dispose();
    _horHeader.dispose();
    _horBody.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activos = widget.empleados.where((e) => e.activo).toList();
    // El alto real del cuerpo suma los paddings: el superior empuja la
    // primera hora hacia abajo del encabezado, el inferior deja colchón
    // antes de la barra de navegación.
    final altoGridPx =
        altoGrid(widget.rango, _kAltoSlot, _kSlotMin) + _kPadTop + _kPadBottom;

    // El grid debe ADAPTARSE al horario del día:
    //   - Horario corto (10–13): el contenedor se contrae al alto necesario
    //     y no genera un gran hueco gris al final.
    //   - Horario largo (10–20): el contenedor ocupa todo el alto disponible
    //     y el cuerpo interno hace scroll vertical.
    // LayoutBuilder nos da la altura disponible del padre (Expanded del
    // Scaffold) y elegimos el menor de los dos.
    return LayoutBuilder(builder: (ctx, c) {
      final altoNecesario = altoGridPx + _kAltoEncabezado;
      final altoFinal = altoNecesario < c.maxHeight ? altoNecesario : c.maxHeight;
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: altoFinal,
          child: _construirGrid(activos, altoGridPx),
        ),
      );
    });
  }

  Widget _construirGrid(List<Empleado> activos, double altoGridPx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kFondoGrid,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _Encabezado(
            empleados: activos,
            controller: _horHeader,
            anchoColumna: widget.anchoColumna,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _vertical,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                height: altoGridPx,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ColumnaHoras(rango: widget.rango, altoTotal: altoGridPx),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horBody,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: SizedBox(
                          width: activos.length * (widget.anchoColumna + 8),
                          height: altoGridPx,
                          child: Stack(
                            children: [
                              _LineasHora(rango: widget.rango, altoTotal: altoGridPx),
                              Row(
                                children: activos
                                    .map((e) => _ColumnaEmpleado(
                                  empleado: e,
                                  fecha: widget.fecha,
                                  rango: widget.rango,
                                  ahora: _ahora,
                                  citas: widget.citas
                                      .where((c) => c.idEmpleado == e.id)
                                      .toList(),
                                  onHueco: widget.onHuecoPulsado,
                                  anchoColumna: widget.anchoColumna,
                                ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Encabezado de empleados ─────────────────────────

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.empleados,
    required this.controller,
    required this.anchoColumna,
  });
  final List<Empleado> empleados;
  final ScrollController controller;
  final double anchoColumna;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kAltoEncabezado,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: _kAnchoColHoras,
            child: Center(
              child: Text(
                'HORA',
                style: GoogleFonts.poppins(
                  color: _kHoraTenue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: empleados
                    .map((e) => _TarjetaEmpleado(e, anchoColumna: anchoColumna))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaEmpleado extends StatelessWidget {
  const _TarjetaEmpleado(this.empleado, {required this.anchoColumna});
  final Empleado empleado;
  final double anchoColumna;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: anchoColumna,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          ClipOval(
            child: _FotoEmpleado(rutaRelativa: empleado.fotoUrl, tam: 36),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              empleado.nombreCompleto,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Avatar del empleado. Cuando el admin edita un empleado y vuelve, el
// provider `empleadosAdminNotifierProvider` se invalida y este widget se
// reconstruye con la URL actualizada — Flutter por defecto cachea por URL,
// así que basta con que la URL cambie para que se vuelva a descargar.
class _FotoEmpleado extends StatelessWidget {
  const _FotoEmpleado({required this.rutaRelativa, required this.tam});
  final String rutaRelativa;
  final double tam;

  @override
  Widget build(BuildContext context) {
    if (rutaRelativa.isEmpty) {
      return _placeholder();
    }
    return Image.network(
      ApiEndpoints.urlImagen(rutaRelativa),
      width: tam,
      height: tam,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(
          width: tam,
          height: tam,
          color: AppColors.accentGlow,
        );
      },
    );
  }

  Widget _placeholder() => Container(
    width: tam,
    height: tam,
    color: AppColors.accentGlow,
    alignment: Alignment.center,
    child: Icon(Icons.person, color: AppColors.primary, size: tam * 0.6),
  );
}

// ───────────────────────── Columna de horas (fija) ─────────────────────────

class _ColumnaHoras extends StatelessWidget {
  const _ColumnaHoras({required this.rango, required this.altoTotal});
  final RangoHorario rango;
  final double altoTotal;

  @override
  Widget build(BuildContext context) {
    final labels = <Widget>[];
    final totalSlots = rango.duracionMin ~/ _kSlotMin;
    for (int s = 0; s <= totalSlots; s++) {
      final minutosAbs = rango.aperturaMin + s * _kSlotMin;
      final hora = minutosAbs ~/ 60;
      final min  = minutosAbs % 60;
      final esHoraEntera = min == 0;
      labels.add(Positioned(
        top: _kPadTop + s * _kAltoSlot - 7,
        left: 0,
        right: 0,
        child: Center(
          child: Text(
            '${hora.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              color: esHoraEntera ? AppColors.textMain : _kHoraTenue,
              fontSize: esHoraEntera ? 12 : 9,
              fontWeight: esHoraEntera ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ));
    }
    return SizedBox(
      width: _kAnchoColHoras,
      height: altoTotal,
      child: Stack(children: labels),
    );
  }
}

// Líneas guía cada hora dentro del Stack del cuerpo. Se ponen detrás de las
// citas (primero en el Stack) para que no interfieran al pinchar.
class _LineasHora extends StatelessWidget {
  const _LineasHora({required this.rango, required this.altoTotal});
  final RangoHorario rango;
  final double altoTotal;

  @override
  Widget build(BuildContext context) {
    final lineas = <Widget>[];
    final horasTotales = rango.duracionMin ~/ 60;
    for (int h = 0; h <= horasTotales; h++) {
      lineas.add(Positioned(
        top: _kPadTop + h * 4 * _kAltoSlot, // 4 slots de 15 = 1 hora
        left: 0,
        right: 0,
        child: Container(height: 1, color: _kLineaHora),
      ));
    }
    return Stack(children: lineas);
  }
}

// ───────────────────────── Columna de un empleado ─────────────────────────

class _ColumnaEmpleado extends StatelessWidget {
  const _ColumnaEmpleado({
    required this.empleado,
    required this.fecha,
    required this.rango,
    required this.ahora,
    required this.citas,
    required this.onHueco,
    required this.anchoColumna,
  });

  final Empleado empleado;
  final DateTime fecha;
  final RangoHorario rango;
  // Hora actual usada para calcular el estado efectivo de cada cita.
  // Viene del timer del padre para que cambiar de CONFIRMADA a EN_PROCESO
  // a COMPLETADA sea automático cada minuto.
  final DateTime ahora;
  final List<CitaAdmin> citas;
  final OnHuecoPulsado onHueco;
  final double anchoColumna;

  @override
  Widget build(BuildContext context) {
    final descanso = franjaDescansoDelDia(
      horaDescanso: empleado.horaDescanso,
      duracionDescansoMinutos: empleado.duracionDescansoMinutos,
      rango: rango,
    );
    final huecos = calcularHuecos(
      rango: rango,
      citasEmpleado: citas,
      descanso: descanso,
      slotMin: _kSlotMin,
    );

    return Container(
      width: anchoColumna,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: _kFondoCol,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (descanso != null) _FranjaDescanso(descanso: descanso, rango: rango),
          ...huecos.map((h) => _Hueco(
            hueco: h,
            rango: rango,
            onPulsar: () => onHueco(
              idEmpleado: empleado.id,
              nombreEmpleado: empleado.nombreCompleto,
              fecha: fecha,
              horaInicio: h.horaInicio,
              horaFinHueco: h.horaFin,
            ),
          )),
          ...citas.map((c) => _TarjetaCita(cita: c, rango: rango, ahora: ahora)),
        ],
      ),
    );
  }
}

// ───────────────────────── Franja de descanso ─────────────────────────

class _FranjaDescanso extends StatelessWidget {
  const _FranjaDescanso({required this.descanso, required this.rango});
  final FranjaDescanso descanso;
  final RangoHorario rango;

  @override
  Widget build(BuildContext context) {
    final top    = _kPadTop +
        ((descanso.inicioMin - rango.aperturaMin) / _kSlotMin) * _kAltoSlot;
    final altura = ((descanso.finMin - descanso.inicioMin) / _kSlotMin) * _kAltoSlot;
    return Positioned(
      top: top + 2,
      left: 4,
      right: 4,
      height: altura - 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'DESCANSO',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Hueco libre con "+" ─────────────────────────

class _Hueco extends StatelessWidget {
  const _Hueco({required this.hueco, required this.rango, required this.onPulsar});
  final HuecoLibre hueco;
  final RangoHorario rango;
  final VoidCallback onPulsar;

  @override
  Widget build(BuildContext context) {
    final top    = _kPadTop +
        ((hueco.inicioMin - rango.aperturaMin) / _kSlotMin) * _kAltoSlot;
    final altura = (hueco.duracionMin / _kSlotMin) * _kAltoSlot;

    return Positioned(
      top: top + 2,
      left: 4,
      right: 4,
      height: altura - 4,
      child: InkWell(
        onTap: onPulsar,
        borderRadius: BorderRadius.circular(10),
        child: DottedBorderBox(
          child: Center(
            child: Icon(Icons.add, color: AppColors.primary.withValues(alpha: 0.7), size: 22),
          ),
        ),
      ),
    );
  }
}

// Caja con borde punteado simulada con `DecoratedBox`. Evita meter una
// dependencia nueva (`dotted_border`) solo para esto.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PinturaPunteada(color: AppColors.primary.withValues(alpha: 0.45)),
      child: child,
    );
  }
}

class _PinturaPunteada extends CustomPainter {
  _PinturaPunteada({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap  = 3.0;
    const radio = 10.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radio),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double d = 0;
      while (d < m.length) {
        final fin = (d + dash).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(d, fin), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PinturaPunteada old) => old.color != color;
}

// ───────────────────────── Tarjeta de cita ─────────────────────────

class _TarjetaCita extends StatelessWidget {
  const _TarjetaCita({required this.cita, required this.rango, required this.ahora});
  final CitaAdmin cita;
  final RangoHorario rango;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final top = _kPadTop +
        posicionTopCita(cita: cita, rango: rango, altoSlot: _kAltoSlot);
    final altura = alturaCita(cita: cita, altoSlot: _kAltoSlot);

    return Positioned(
      top: top + 2,
      left: 4,
      right: 4,
      height: altura - 4,
      child: _TarjetaContenido(cita: cita, ahora: ahora),
    );
  }
}

class _TarjetaContenido extends StatelessWidget {
  const _TarjetaContenido({required this.cita, required this.ahora});
  final CitaAdmin cita;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    // Estado efectivo: si el backend la trae como CONFIRMADA pero ya pasó
    // la hora de inicio, se muestra como EN CURSO; pasada la hora de fin,
    // como COMPLETADA. No mutamos `cita`; solo cambia la presentación.
    final estado = estadoEfectivoCita(cita, ahora);
    final colores = _coloresEstado(estado);
    final atenuada = _estadoAtenuado(estado);

    // Estructura fija (el usuario lo pidió así):
    //   1) Badge de estado pequeño (CONFIRMADA / EN CURSO / …)
    //   2) Nombre del cliente
    //   3) Hora inicio – fin
    //   4) Servicio
    //
    // El ClipRRect externo + clipBehavior hardEdge garantizan que, si la
    // tarjeta es muy corta (cita de 15 min), el contenido sobrante se
    // recorta visualmente y nunca invade la cita siguiente.
    return Opacity(
      opacity: atenuada ? 0.55 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: colores.acento, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // OverflowBox + alignment topLeft: si el contenido pide más altura
          // que la disponible (cita muy corta), se dibuja hacia abajo y el
          // clip exterior lo recorta — el orden visible siempre es:
          // estado → nombre → hora → servicio.
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxHeight: double.infinity,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _badgeEstado(colores, estado),
                  const SizedBox(height: 3),
                  Text(
                    cita.nombreCliente,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      decoration: atenuada ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${cita.horaInicio} – ${cita.horaFin}',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cita.nombreServicio,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgeEstado(_ColorEstado colores, EstadoCita estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colores.tagFondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _etiquetaEstado(estado),
        style: GoogleFonts.poppins(
          color: colores.tagTexto,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ───────────────────────── Cartel de día cerrado ─────────────────────────

class CartelCerrado extends StatelessWidget {
  const CartelCerrado({super.key, required this.motivo});
  final MotivoCierre motivo;

  @override
  Widget build(BuildContext context) {
    final (IconData icono, String titulo, String detalle) = switch (motivo) {
      MotivoCierre.domingoSinHorario =>
      (Icons.event_busy, 'Peluquería cerrada', 'Hoy no hay horario de apertura.'),
      MotivoCierre.festivo =>
      (Icons.flag_outlined, 'Día festivo', 'La peluquería permanece cerrada por festivo.'),
      MotivoCierre.vacaciones =>
      (Icons.beach_access_outlined, 'Vacaciones', 'La peluquería está cerrada por vacaciones.'),
      MotivoCierre.mantenimiento =>
      (Icons.build_outlined, 'Mantenimiento', 'Cerrado por trabajos de mantenimiento.'),
      MotivoCierre.cierreAnual =>
      (Icons.calendar_today_outlined, 'Cierre anual', 'Estamos en el periodo de cierre anual.'),
      MotivoCierre.abierto =>
      (Icons.check_circle_outline, 'Abierto', ''),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 64, color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Disculpe las molestias — $detalle',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
