// Entidades del submódulo "métricas". El backend devuelve un único objeto
// compuesto que cubre KPIs, rankings y series.

class ServicioPopular {
  const ServicioPopular({
    required this.idServicio,
    required this.nombre,
    required this.reservas,
  });
  final int idServicio;
  final String nombre;
  final int reservas;
}

class EmpleadoPopular {
  const EmpleadoPopular({
    required this.idEmpleado,
    required this.nombre,
    required this.citasAtendidas,
  });
  final int idEmpleado;
  final String nombre;
  final int citasAtendidas;
}

class DistribucionDia {
  const DistribucionDia({required this.dia, required this.citas});
  // Día de la semana en formato Java DayOfWeek: "MONDAY", "TUESDAY", ...
  final String dia;
  final int citas;
}

class DistribucionFranja {
  const DistribucionFranja({required this.horaInicio, required this.citas});
  final String horaInicio; // "HH:00"
  final int citas;
}

class MetricasResumen {
  const MetricasResumen({
    required this.totalCitas,
    required this.citasCompletadas,
    required this.citasCanceladas,
    required this.citasNoPresentado,
    required this.tasaAsistencia,
    required this.distribucionPorDiaSemana,
    required this.distribucionPorFranjaHoraria,
    this.servicioMasSolicitado,
    this.empleadoMasReservado,
  });

  final int totalCitas;
  final int citasCompletadas;
  final int citasCanceladas;
  final int citasNoPresentado;
  // Porcentaje 0-100 con 2 decimales (ej. 86.50).
  final double tasaAsistencia;
  final ServicioPopular? servicioMasSolicitado;
  final EmpleadoPopular? empleadoMasReservado;
  final List<DistribucionDia> distribucionPorDiaSemana;
  final List<DistribucionFranja> distribucionPorFranjaHoraria;
}
