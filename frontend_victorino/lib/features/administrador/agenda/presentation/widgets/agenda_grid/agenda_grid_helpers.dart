// Helpers puros (sin Flutter) para la cuadrícula de la agenda admin.
//
// Aquí vive toda la aritmética temporal: convertir "HH:mm" a minutos,
// decidir si un día está cerrado, calcular qué huecos quedan libres en
// la columna de un peluquero, y traducir hora→píxeles para posicionar
// las citas dentro del Stack.
//
// Al ser funciones puras se prueban por completo sin montar widgets.

import '../../../../../administrador/agenda/domain/entidades/cita.dart';
import '../../../../../administrador/negocio/domain/entidades/horario_peluqueria.dart';

// ─────────────────────────── Modelos auxiliares ───────────────────────────

// Rango horario del día seleccionado, ya convertido a minutos desde 00:00
// para evitar tener que parsear strings repetidamente.
class RangoHorario {
  const RangoHorario({required this.aperturaMin, required this.cierreMin});

  // Minutos desde medianoche. Ejemplo: 10:00 → 600.
  final int aperturaMin;
  final int cierreMin;

  int get duracionMin => cierreMin - aperturaMin;
}

// Motivo por el que un día está cerrado. Sirve para pintar el cartel
// con un mensaje distinto según el caso.
enum MotivoCierre {
  abierto,           // el día no está cerrado
  domingoSinHorario, // no hay horario en el día de la semana
  festivo,
  vacaciones,
  mantenimiento,
  cierreAnual,
}

// Hueco libre proponible en la columna de un peluquero. Lo usa el widget
// `HuecoLibre` para pintar el botón "+" y, al pulsarlo, abrir el bottom-sheet
// con la hora de inicio sugerida.
class HuecoLibre {
  const HuecoLibre({required this.inicioMin, required this.finMin});
  final int inicioMin;
  final int finMin;

  int get duracionMin => finMin - inicioMin;
  String get horaInicio => _minutosAHora(inicioMin);
  String get horaFin    => _minutosAHora(finMin);
}

// Descanso del empleado ya normalizado a minutos.
class FranjaDescanso {
  const FranjaDescanso({required this.inicioMin, required this.finMin});
  final int inicioMin;
  final int finMin;
}

// ─────────────────────────── Parsing horas ───────────────────────────

// Convierte "HH:mm" o "HH:mm:ss" a minutos desde medianoche.
// Devuelve null si el string no es válido. Lo usamos en varios sitios
// porque el backend a veces devuelve segundos y a veces no.
int? minutosDesdeHora(String? hhmm) {
  if (hhmm == null || hhmm.isEmpty) return null;
  final partes = hhmm.split(':');
  if (partes.length < 2) return null;
  final h = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

String _minutosAHora(int min) {
  final h = (min ~/ 60).toString().padLeft(2, '0');
  final m = (min % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

// ─────────────────────────── Horario del día ───────────────────────────

// Devuelve el rango (apertura, cierre) del día concreto según el horario
// semanal. Si ese día no se trabaja (apertura o cierre nulos), devuelve null.
RangoHorario? rangoDelDia(HorarioPeluqueria h, DateTime fecha) {
  final (String? ap, String? ci) = switch (fecha.weekday) {
    DateTime.monday    => (h.aperturaLunes,     h.cierreLunes),
    DateTime.tuesday   => (h.aperturaMartes,    h.cierreMartes),
    DateTime.wednesday => (h.aperturaMiercoles, h.cierreMiercoles),
    DateTime.thursday  => (h.aperturaJueves,    h.cierreJueves),
    DateTime.friday    => (h.aperturaViernes,   h.cierreViernes),
    DateTime.saturday  => (h.aperturaSabado,    h.cierreSabado),
    DateTime.sunday    => (h.aperturaDomingo,   h.cierreDomingo),
    _ => (null, null),
  };
  final aMin = minutosDesdeHora(ap);
  final cMin = minutosDesdeHora(ci);
  if (aMin == null || cMin == null || cMin <= aMin) return null;
  return RangoHorario(aperturaMin: aMin, cierreMin: cMin);
}

// ─────────────────────────── Día cerrado ───────────────────────────

// `fechaIso` debe venir como "YYYY-MM-DD" — es el formato que usa el backend.
String _fechaIso(DateTime f) {
  final y = f.year.toString().padLeft(4, '0');
  final m = f.month.toString().padLeft(2, '0');
  final d = f.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

// Determina si el día está cerrado y por qué motivo.
// Orden de prioridad: domingo sin horario → festivo → cierre anual.
// Si el festivo tiene tipo `vacaciones` o `mantenimiento` se devuelve ese
// motivo concreto (más informativo para el cartel).
MotivoCierre motivoCierre({
  required DateTime fecha,
  required HorarioPeluqueria horario,
  required List<Festivo> festivos,
  CierreAnual? cierreAnual,
}) {
  if (rangoDelDia(horario, fecha) == null) {
    return MotivoCierre.domingoSinHorario;
  }
  final iso = _fechaIso(fecha);
  for (final f in festivos) {
    if (f.fecha == iso) {
      return switch (f.tipo) {
        TipoFestivo.vacaciones    => MotivoCierre.vacaciones,
        TipoFestivo.mantenimiento => MotivoCierre.mantenimiento,
        _                         => MotivoCierre.festivo,
      };
    }
  }
  if (cierreAnual != null &&
      cierreAnual.fechaInicio != null &&
      cierreAnual.fechaFin != null &&
      iso.compareTo(cierreAnual.fechaInicio!) >= 0 &&
      iso.compareTo(cierreAnual.fechaFin!) <= 0) {
    return MotivoCierre.cierreAnual;
  }
  return MotivoCierre.abierto;
}

bool diaCerrado({
  required DateTime fecha,
  required HorarioPeluqueria horario,
  required List<Festivo> festivos,
  CierreAnual? cierreAnual,
}) {
  return motivoCierre(
        fecha: fecha,
        horario: horario,
        festivos: festivos,
        cierreAnual: cierreAnual,
      ) !=
      MotivoCierre.abierto;
}

// ─────────────────────────── Descanso del empleado ───────────────────────────

// Lee `horaDescanso` + `duracionDescansoMinutos` del empleado y los traduce
// a una franja [inicioMin, finMin]. Recorta la franja al rango del día por
// si el descanso queda fuera del horario.
FranjaDescanso? franjaDescansoDelDia({
  required String? horaDescanso,
  required int? duracionDescansoMinutos,
  required RangoHorario rango,
}) {
  final inicio = minutosDesdeHora(horaDescanso);
  final dur = duracionDescansoMinutos;
  if (inicio == null || dur == null || dur <= 0) return null;
  final fin = inicio + dur;
  // El descanso se considera solo si solapa con el horario del día.
  if (fin <= rango.aperturaMin || inicio >= rango.cierreMin) return null;
  return FranjaDescanso(
    inicioMin: inicio < rango.aperturaMin ? rango.aperturaMin : inicio,
    finMin:    fin    > rango.cierreMin   ? rango.cierreMin   : fin,
  );
}

// ─────────────────────────── Huecos libres ───────────────────────────

// Calcula huecos contiguos vacíos en la columna de un peluquero. Se excluyen
// las citas en estado cancelado/no-presentado (los huecos que dejan son
// reservables) y el descanso, que se trata como bloque ocupado.
//
// `slotMin` es la granularidad: los huecos se alinean a múltiplos de
// `slotMin` (15 por defecto) y se descartan los < `slotMin` para no
// generar botones "+" ínfimos.
List<HuecoLibre> calcularHuecos({
  required RangoHorario rango,
  required List<CitaAdmin> citasEmpleado,
  FranjaDescanso? descanso,
  int slotMin = 15,
}) {
  // 1) Construir lista de franjas ocupadas, redondeadas al slot.
  final ocupadas = <List<int>>[];

  for (final c in citasEmpleado) {
    if (!_cuentaComoOcupada(c.estado)) continue;
    final ini = minutosDesdeHora(c.horaInicio);
    final fin = minutosDesdeHora(c.horaFin);
    if (ini == null || fin == null) continue;
    if (fin <= rango.aperturaMin || ini >= rango.cierreMin) continue;
    ocupadas.add([
      ini < rango.aperturaMin ? rango.aperturaMin : ini,
      fin > rango.cierreMin   ? rango.cierreMin   : fin,
    ]);
  }
  if (descanso != null) {
    ocupadas.add([descanso.inicioMin, descanso.finMin]);
  }
  ocupadas.sort((a, b) => a[0].compareTo(b[0]));

  // 2) Fusionar solapamientos para evitar huecos duplicados.
  final fusionadas = <List<int>>[];
  for (final f in ocupadas) {
    if (fusionadas.isEmpty || f[0] > fusionadas.last[1]) {
      fusionadas.add([f[0], f[1]]);
    } else {
      fusionadas.last[1] = fusionadas.last[1] > f[1] ? fusionadas.last[1] : f[1];
    }
  }

  // 3) Recorrer el día y emitir los huecos entre franjas, alineados a slot.
  final huecos = <HuecoLibre>[];
  int cursor = rango.aperturaMin;
  for (final f in fusionadas) {
    if (f[0] > cursor) {
      _addHueco(huecos, cursor, f[0], slotMin);
    }
    cursor = f[1] > cursor ? f[1] : cursor;
  }
  if (cursor < rango.cierreMin) {
    _addHueco(huecos, cursor, rango.cierreMin, slotMin);
  }
  return huecos;
}

void _addHueco(List<HuecoLibre> out, int desde, int hasta, int slotMin) {
  // Alinea el inicio al siguiente múltiplo de slotMin y el fin al anterior.
  final inicio = _siguienteMultiplo(desde, slotMin);
  final fin    = _anteriorMultiplo(hasta, slotMin);
  if (fin - inicio >= slotMin) {
    out.add(HuecoLibre(inicioMin: inicio, finMin: fin));
  }
}

int _siguienteMultiplo(int valor, int paso) {
  final resto = valor % paso;
  return resto == 0 ? valor : valor + (paso - resto);
}

int _anteriorMultiplo(int valor, int paso) => valor - (valor % paso);

// Una cita "cuenta como ocupada" si está activa. Las canceladas y
// no-presentado liberan el hueco (el peluquero puede recibir a otro cliente).
bool _cuentaComoOcupada(EstadoCita e) {
  return switch (e) {
    EstadoCita.confirmada => true,
    EstadoCita.enProceso  => true,
    EstadoCita.completada => true,
    EstadoCita.canceladaCliente    => false,
    EstadoCita.canceladaPeluqueria => false,
    EstadoCita.noPresentado        => false,
  };
}

// ─────────────────────────── Posición en píxeles ───────────────────────────

// Devuelve la coordenada Y (top) de una cita dentro del Stack de la columna,
// en píxeles, dado el alto de cada slot de `slotMin` minutos.
double posicionTopCita({
  required CitaAdmin cita,
  required RangoHorario rango,
  required double altoSlot,
  int slotMin = 15,
}) {
  final ini = minutosDesdeHora(cita.horaInicio) ?? rango.aperturaMin;
  final minutosDesdeApertura = ini - rango.aperturaMin;
  return (minutosDesdeApertura / slotMin) * altoSlot;
}

// Devuelve la altura en píxeles de la cita.
double alturaCita({
  required CitaAdmin cita,
  required double altoSlot,
  int slotMin = 15,
}) {
  final ini = minutosDesdeHora(cita.horaInicio);
  final fin = minutosDesdeHora(cita.horaFin);
  final dur = (ini != null && fin != null) ? (fin - ini) : cita.duracionMinutos;
  return (dur / slotMin) * altoSlot;
}

// Alto total del eje vertical (todo el día).
double altoGrid(RangoHorario rango, double altoSlot, int slotMin) {
  return (rango.duracionMin / slotMin) * altoSlot;
}
