// Tests unitarios de los helpers puros de la cuadrícula de la agenda admin.
// Cubren la conversión de horas, el cálculo del rango del día, la detección
// de día cerrado (festivos/cierre anual/domingo), el cálculo de huecos
// libres respetando descansos y citas, y el posicionamiento en píxeles.

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_victorino/features/administrador/agenda/domain/entidades/cita.dart';
import 'package:frontend_victorino/features/administrador/agenda/presentation/widgets/agenda_grid/agenda_grid_helpers.dart';
import 'package:frontend_victorino/features/administrador/negocio/domain/entidades/horario_peluqueria.dart';

// Horario base "10:00 a 18:00 de lunes a sábado, domingo cerrado".
HorarioPeluqueria _horarioStd() => const HorarioPeluqueria(
      idPeluqueria: 1,
      nombre: 'Victorino',
      aperturaLunes:     '10:00', cierreLunes:     '18:00',
      aperturaMartes:    '10:00', cierreMartes:    '18:00',
      aperturaMiercoles: '10:00', cierreMiercoles: '18:00',
      aperturaJueves:    '10:00', cierreJueves:    '18:00',
      aperturaViernes:   '10:00', cierreViernes:   '18:00',
      aperturaSabado:    '10:00', cierreSabado:    '14:00',
      aperturaDomingo:   null,    cierreDomingo:   null,
    );

// Factoría rápida de citas con lo justo para los cálculos.
CitaAdmin _cita({
  required String horaInicio,
  required String horaFin,
  String fecha = '2026-05-12',
  EstadoCita estado = EstadoCita.confirmada,
  int idEmpleado = 1,
  int duracion = 60,
}) {
  return CitaAdmin(
    idCita: 0,
    fecha: fecha,
    horaInicio: horaInicio,
    horaFin: horaFin,
    estado: estado,
    nombreCliente: 'X',
    esInvitado: false,
    idEmpleado: idEmpleado,
    nombreEmpleado: 'Emp',
    fotoEmpleado: '',
    idServicio: 1,
    nombreServicio: 'Corte',
    duracionMinutos: duracion,
    precioServicio: 0,
  );
}

void main() {
  group('minutosDesdeHora', () {
    test('parsea "HH:mm"', () {
      expect(minutosDesdeHora('10:30'), 630);
      expect(minutosDesdeHora('00:00'), 0);
      expect(minutosDesdeHora('23:59'), 23 * 60 + 59);
    });

    test('parsea "HH:mm:ss" (formato del backend)', () {
      expect(minutosDesdeHora('10:30:00'), 630);
    });

    test('devuelve null con entrada inválida', () {
      expect(minutosDesdeHora(null), isNull);
      expect(minutosDesdeHora(''), isNull);
      expect(minutosDesdeHora('1030'), isNull);
      expect(minutosDesdeHora('25:00'), isNull);
    });
  });

  group('rangoDelDia', () {
    test('lunes 10–18 devuelve rango (600, 1080)', () {
      // 2026-05-11 es lunes.
      final r = rangoDelDia(_horarioStd(), DateTime(2026, 5, 11));
      expect(r, isNotNull);
      expect(r!.aperturaMin, 600);
      expect(r.cierreMin, 1080);
    });

    test('domingo sin horario devuelve null', () {
      // 2026-05-10 es domingo.
      expect(rangoDelDia(_horarioStd(), DateTime(2026, 5, 10)), isNull);
    });

    test('sábado 10–14 devuelve rango (600, 840)', () {
      // 2026-05-16 es sábado.
      final r = rangoDelDia(_horarioStd(), DateTime(2026, 5, 16));
      expect(r!.cierreMin, 840);
    });
  });

  group('motivoCierre', () {
    test('día normal abierto', () {
      final m = motivoCierre(
        fecha: DateTime(2026, 5, 11),
        horario: _horarioStd(),
        festivos: const [],
      );
      expect(m, MotivoCierre.abierto);
    });

    test('domingo sin horario', () {
      final m = motivoCierre(
        fecha: DateTime(2026, 5, 10),
        horario: _horarioStd(),
        festivos: const [],
      );
      expect(m, MotivoCierre.domingoSinHorario);
    });

    test('festivo nacional detectado', () {
      final festivos = const [
        Festivo(id: 1, fecha: '2026-05-11', descripcion: 'Día de prueba', tipo: TipoFestivo.nacional),
      ];
      final m = motivoCierre(
        fecha: DateTime(2026, 5, 11),
        horario: _horarioStd(),
        festivos: festivos,
      );
      expect(m, MotivoCierre.festivo);
    });

    test('festivo tipo vacaciones devuelve motivo vacaciones', () {
      final festivos = const [
        Festivo(id: 2, fecha: '2026-08-03', descripcion: 'Cierre verano', tipo: TipoFestivo.vacaciones),
      ];
      final m = motivoCierre(
        fecha: DateTime(2026, 8, 3),
        horario: _horarioStd(),
        festivos: festivos,
      );
      expect(m, MotivoCierre.vacaciones);
    });

    test('cierre anual entre fechas devuelve cierreAnual', () {
      final m = motivoCierre(
        fecha: DateTime(2026, 8, 10),
        horario: _horarioStd(),
        festivos: const [],
        cierreAnual: const CierreAnual(fechaInicio: '2026-08-01', fechaFin: '2026-08-31'),
      );
      expect(m, MotivoCierre.cierreAnual);
    });
  });

  group('calcularHuecos', () {
    final rango = const RangoHorario(aperturaMin: 600, cierreMin: 720); // 10–12

    test('día vacío genera un único hueco de toda la franja', () {
      final huecos = calcularHuecos(rango: rango, citasEmpleado: const []);
      expect(huecos, hasLength(1));
      expect(huecos.first.inicioMin, 600);
      expect(huecos.first.finMin, 720);
    });

    test('cita 10:00–10:30 deja hueco 10:30–12:00', () {
      final huecos = calcularHuecos(
        rango: rango,
        citasEmpleado: [_cita(horaInicio: '10:00', horaFin: '10:30')],
      );
      expect(huecos, hasLength(1));
      expect(huecos.first.inicioMin, 630);
      expect(huecos.first.finMin, 720);
    });

    test('cita cancelada NO bloquea el hueco', () {
      final huecos = calcularHuecos(
        rango: rango,
        citasEmpleado: [
          _cita(horaInicio: '10:00', horaFin: '11:00', estado: EstadoCita.canceladaCliente),
        ],
      );
      expect(huecos, hasLength(1));
      expect(huecos.first.duracionMin, 120);
    });

    test('descanso del empleado se trata como hueco bloqueado', () {
      final huecos = calcularHuecos(
        rango: rango,
        citasEmpleado: const [],
        descanso: const FranjaDescanso(inicioMin: 660, finMin: 690), // 11:00–11:30
      );
      expect(huecos, hasLength(2));
      expect(huecos[0].finMin, 660);
      expect(huecos[1].inicioMin, 690);
    });

    test('huecos < slot se descartan', () {
      // Cita 10:00–11:50 deja un hueco real de 10 min: debe filtrarse con slot=15.
      final huecos = calcularHuecos(
        rango: rango,
        citasEmpleado: [_cita(horaInicio: '10:00', horaFin: '11:50')],
        slotMin: 15,
      );
      expect(huecos, isEmpty);
    });
  });

  group('estadoEfectivoCita', () {
    // Cita 11 mayo 2026 10:00-11:00 marcada como CONFIRMADA por backend.
    CitaAdmin confirmada() => _cita(
          horaInicio: '10:00',
          horaFin: '11:00',
          fecha: '2026-05-11',
          estado: EstadoCita.confirmada,
        );

    test('antes del inicio sigue CONFIRMADA', () {
      final e = estadoEfectivoCita(confirmada(), DateTime(2026, 5, 11, 9, 30));
      expect(e, EstadoCita.confirmada);
    });

    test('dentro del rango → EN_PROCESO', () {
      final e = estadoEfectivoCita(confirmada(), DateTime(2026, 5, 11, 10, 30));
      expect(e, EstadoCita.enProceso);
    });

    test('después del fin → COMPLETADA', () {
      final e = estadoEfectivoCita(confirmada(), DateTime(2026, 5, 11, 12, 0));
      expect(e, EstadoCita.completada);
    });

    test('cancelada permanece cancelada aunque haya pasado la hora', () {
      final c = _cita(
        horaInicio: '10:00',
        horaFin: '11:00',
        fecha: '2026-05-11',
        estado: EstadoCita.canceladaCliente,
      );
      final e = estadoEfectivoCita(c, DateTime(2026, 5, 11, 15, 0));
      expect(e, EstadoCita.canceladaCliente);
    });

    test('no presentado permanece no presentado', () {
      final c = _cita(
        horaInicio: '10:00',
        horaFin: '11:00',
        fecha: '2026-05-11',
        estado: EstadoCita.noPresentado,
      );
      final e = estadoEfectivoCita(c, DateTime(2026, 5, 11, 15, 0));
      expect(e, EstadoCita.noPresentado);
    });
  });

  group('posiciones en píxeles', () {
    final rango = const RangoHorario(aperturaMin: 600, cierreMin: 1080); // 10–18

    test('cita a las 10:00 con slot 22px → top 0', () {
      final top = posicionTopCita(
        cita: _cita(horaInicio: '10:00', horaFin: '10:30'),
        rango: rango,
        altoSlot: 22,
      );
      expect(top, 0);
    });

    test('cita a las 11:00 con slot 22px → top 88px (4 slots)', () {
      final top = posicionTopCita(
        cita: _cita(horaInicio: '11:00', horaFin: '12:00'),
        rango: rango,
        altoSlot: 22,
      );
      expect(top, 88);
    });

    test('duración 45min con slot 22px → 66px de alto (3 slots)', () {
      final h = alturaCita(
        cita: _cita(horaInicio: '10:00', horaFin: '10:45'),
        altoSlot: 22,
      );
      expect(h, 66);
    });
  });
}
