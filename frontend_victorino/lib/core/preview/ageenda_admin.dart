import 'package:flutter/material.dart';

/// Vista previa de la Agenda Diaria del Portal de Administración
/// de Victorino Style.
///
/// Sistema:
/// - Eje vertical: horas de 10:00 a 18:00 en intervalos de 15 minutos.
/// - Eje horizontal: una columna fija por peluquero (Marco, Elena, Carlos…).
/// - Cada cita se posiciona ABSOLUTAMENTE dentro de su columna según
///   su hora de inicio y duración real (proporcional al tiempo).
/// - El texto largo NUNCA invade la columna del peluquero vecino: cada
///   tarjeta vive dentro del ancho fijo de su columna y trunca/wrappea
///   dentro de la altura asignada por su duración.
/// - Scroll horizontal y vertical sincronizados entre la cabecera de
///   horas, los avatares y la cuadrícula.
class AgendaAdminPreview extends StatefulWidget {
  const AgendaAdminPreview({super.key});

  @override
  State<AgendaAdminPreview> createState() => _AgendaAdminPreviewState();
}

class _AgendaAdminPreviewState extends State<AgendaAdminPreview> {
  // ───── Paleta ─────
  static const Color kPrimaryPurple = Color(0xFF6B3FD4);
  static const Color kPrimaryPurpleDark = Color(0xFF4A2BA8);
  static const Color kBackground = Color(0xFFF7F5FA);
  static const Color kGridBg = Color(0xFFEFEDF3);
  static const Color kCardBg = Colors.white;
  static const Color kTextDark = Color(0xFF1A1A2E);
  static const Color kTextMuted = Color(0xFF8A8A9B);
  static const Color kTimeColor = Color(0xFFB5B5C3);
  static const Color kGridLine = Color(0xFFE2E0E8);

  static const Color kTagPurple = Color(0xFFE9DEFF);
  static const Color kTagPurpleText = Color(0xFF6B3FD4);
  static const Color kTagTeal = Color(0xFFB8F0E8);
  static const Color kTagTealText = Color(0xFF0FA89B);
  static const Color kTagPink = Color(0xFFFFE0EC);
  static const Color kTagPinkText = Color(0xFFD63384);
  static const Color kTagOrange = Color(0xFFFFE4CC);
  static const Color kTagOrangeText = Color(0xFFE8770E);

  static const String kBarberImage = 'assets/imagenes/barbero_1.png';

  // ───── Configuración temporal ─────
  static const int kStartHour = 10; // 10:00
  static const int kEndHour = 18; // 18:00
  static const int kSlotMinutes = 15; // intervalo del grid
  static const double kSlotHeight = 22.0; // px por cada 15 min
  static const double kColumnWidth = 170.0; // ancho por peluquero
  static const double kTimeColWidth = 56.0; // ancho columna de horas
  static const double kHeaderHeight = 64.0;

  int get _totalMinutes => (kEndHour - kStartHour) * 60;
  double get _gridHeight => (_totalMinutes / kSlotMinutes) * kSlotHeight;

  // ───── Datos ─────
  late final List<_Barber> _barbers;
  late final List<_Appointment> _appointments;
  int _selectedBarber = 1;

  // Controllers
  final ScrollController _verticalCtrl = ScrollController();
  final ScrollController _horizontalHeaderCtrl = ScrollController();
  final ScrollController _horizontalBodyCtrl = ScrollController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _barbers = const [
      _Barber(id: 0, name: 'Marco'),
      _Barber(id: 1, name: 'Elena'),
      _Barber(id: 2, name: 'Carlos'),
      _Barber(id: 3, name: 'Lucía'),
    ];

    _appointments = const [
      // ── Marco ──
      _Appointment(
        barberId: 0,
        startHour: 10, startMinute: 0,
        endHour: 11, endMinute: 30,
        tag: 'EXECUTIVE CUT',
        tagColor: kTagPurple, tagTextColor: kTagPurpleText,
        accentColor: kPrimaryPurple,
        clientName: 'Jonathan Rivers',
        service: 'Full service with beard grooming, hot towel and styling.Full service with beard grooming, hot towel and styling',
        confirmed: true,
      ),
      _Appointment(
        barberId: 0,
        startHour: 12, startMinute: 0,
        endHour: 12, endMinute: 45,
        tag: 'QUICK TRIM',
        tagColor: kTagPurple, tagTextColor: kTagPurpleText,
        accentColor: kPrimaryPurple,
        clientName: 'Marcus Chen',
        service: 'Trim sides and back.',
        confirmed: false,
      ),
      _Appointment(
        barberId: 0,
        startHour: 14, startMinute: 30,
        endHour: 16, endMinute: 0,
        tag: 'BEARD & CUT',
        tagColor: kTagOrange, tagTextColor: kTagOrangeText,
        accentColor: kTagOrangeText,
        clientName: 'Robert King',
        service: 'Premium beard sculpting plus haircut and aftershave ritual.',
        confirmed: true,
      ),
      _Appointment(
        barberId: 0,
        startHour: 17, startMinute: 0,
        endHour: 17, endMinute: 30,
        tag: 'KIDS CUT',
        tagColor: kTagPink, tagTextColor: kTagPinkText,
        accentColor: kTagPinkText,
        clientName: 'Tom Jr.',
        service: '',
        confirmed: false,
      ),

      // ── Elena ──
      _Appointment(
        barberId: 1,
        startHour: 10, startMinute: 0,
        endHour: 12, endMinute: 30,
        tag: 'BALAYAGE & TONE',
        tagColor: kTagTeal, tagTextColor: kTagTealText,
        accentColor: kTagTealText,
        clientName: 'Sarah Jenkins',
        service:
        'Full highlight treatment. Premium package with hydration mask and blow-dry styling.',
        confirmed: false,
      ),
      _Appointment(
        barberId: 1,
        startHour: 13, startMinute: 0,
        endHour: 14, endMinute: 0,
        tag: 'COLOR TOUCH',
        tagColor: kTagPink, tagTextColor: kTagPinkText,
        accentColor: kTagPinkText,
        clientName: 'Emily Watson',
        service: 'Root touch-up and gloss treatment.',
        confirmed: true,
      ),
      _Appointment(
        barberId: 1,
        startHour: 15, startMinute: 30,
        endHour: 17, endMinute: 0,
        tag: 'BRIDAL STYLE',
        tagColor: kTagTeal, tagTextColor: kTagTealText,
        accentColor: kTagTealText,
        clientName: 'Anna López',
        service: 'Trial run for wedding hairstyle. Includes consultation.',
        confirmed: true,
      ),

      // ── Carlos ──
      _Appointment(
        barberId: 2,
        startHour: 10, startMinute: 30,
        endHour: 11, endMinute: 15,
        tag: 'CLASSIC CUT',
        tagColor: kTagPurple, tagTextColor: kTagPurpleText,
        accentColor: kPrimaryPurple,
        clientName: 'David Park',
        service: 'Standard haircut.',
        confirmed: true,
      ),
      _Appointment(
        barberId: 2,
        startHour: 12, startMinute: 0,
        endHour: 13, endMinute: 30,
        tag: 'EXECUTIVE CUT',
        tagColor: kTagPurple, tagTextColor: kTagPurpleText,
        accentColor: kPrimaryPurple,
        clientName: 'Michael Brown',
        service: 'Full executive package with shave.',
        confirmed: false,
      ),
      _Appointment(
        barberId: 2,
        startHour: 14, startMinute: 0,
        endHour: 14, endMinute: 30,
        tag: 'QUICK TRIM',
        tagColor: kTagPurple, tagTextColor: kTagPurpleText,
        accentColor: kPrimaryPurple,
        clientName: 'Liam Scott',
        service: '',
        confirmed: false,
      ),
      _Appointment(
        barberId: 2,
        startHour: 16, startMinute: 0,
        endHour: 17, endMinute: 45,
        tag: 'BEARD & CUT',
        tagColor: kTagOrange, tagTextColor: kTagOrangeText,
        accentColor: kTagOrangeText,
        clientName: 'James Wilson',
        service: 'Hair, beard sculpting, and hot towel finish.',
        confirmed: true,
      ),

      // ── Lucía ──
      _Appointment(
        barberId: 3,
        startHour: 10, startMinute: 0,
        endHour: 11, endMinute: 0,
        tag: 'COLOR TOUCH',
        tagColor: kTagPink, tagTextColor: kTagPinkText,
        accentColor: kTagPinkText,
        clientName: 'Sofia Martín',
        service: 'Root color refresh.',
        confirmed: true,
      ),
      _Appointment(
        barberId: 3,
        startHour: 11, startMinute: 30,
        endHour: 13, endMinute: 0,
        tag: 'BALAYAGE & TONE',
        tagColor: kTagTeal, tagTextColor: kTagTealText,
        accentColor: kTagTealText,
        clientName: 'Carmen Ruiz',
        service: 'Highlight refresh with toner.',
        confirmed: false,
      ),
      _Appointment(
        barberId: 3,
        startHour: 14, startMinute: 0,
        endHour: 15, endMinute: 30,
        tag: 'BRIDAL STYLE',
        tagColor: kTagTeal, tagTextColor: kTagTealText,
        accentColor: kTagTealText,
        clientName: 'Patricia Vega',
        service:
        'Wedding hairstyle session with makeup consultation included.',
        confirmed: true,
      ),
      _Appointment(
        barberId: 3,
        startHour: 16, startMinute: 30,
        endHour: 17, endMinute: 30,
        tag: 'KIDS CUT',
        tagColor: kTagPink, tagTextColor: kTagPinkText,
        accentColor: kTagPinkText,
        clientName: 'Mia G.',
        service: 'First haircut.',
        confirmed: false,
      ),
    ];

    // Sincronizar scroll horizontal cabecera <-> cuerpo
    _horizontalHeaderCtrl.addListener(() {
      if (_isSyncing) return;
      if (_horizontalBodyCtrl.hasClients &&
          _horizontalBodyCtrl.offset != _horizontalHeaderCtrl.offset) {
        _isSyncing = true;
        _horizontalBodyCtrl.jumpTo(_horizontalHeaderCtrl.offset);
        _isSyncing = false;
      }
    });
    _horizontalBodyCtrl.addListener(() {
      if (_isSyncing) return;
      if (_horizontalHeaderCtrl.hasClients &&
          _horizontalHeaderCtrl.offset != _horizontalBodyCtrl.offset) {
        _isSyncing = true;
        _horizontalHeaderCtrl.jumpTo(_horizontalBodyCtrl.offset);
        _isSyncing = false;
      }
    });
  }

  @override
  void dispose() {
    _verticalCtrl.dispose();
    _horizontalHeaderCtrl.dispose();
    _horizontalBodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTitleSection(),
            const SizedBox(height: 12),
            _buildSelectDateButton(),
            const SizedBox(height: 16),
            Expanded(child: _buildAgendaContainer()),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingEditButton(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─────────────────────────── HEADER ───────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.menu, color: kPrimaryPurple, size: 26),
              SizedBox(width: 16),
              Text(
                'VICTORINO STYLE',
                style: TextStyle(
                  color: kPrimaryPurple,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              image: const DecorationImage(
                image: AssetImage(kBarberImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'MANAGEMENT PORTAL',
            style: TextStyle(
              color: Color(0xFF1F6B6B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Daily Agenda',
            style: TextStyle(
              color: kTextDark,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Wednesday, October 25, 2023',
            style: TextStyle(
              color: kTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectDateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFEAEAEF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.calendar_today_outlined, size: 15, color: kTextDark),
              SizedBox(width: 8),
              Text(
                'Select Date',
                style: TextStyle(
                  color: kTextDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── AGENDA CONTAINER ───────────────────────
  Widget _buildAgendaContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kGridBg,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _buildBarbersHeader(),
          Expanded(child: _buildScrollableBody()),
        ],
      ),
    );
  }

  Widget _buildBarbersHeader() {
    return Container(
      height: kHeaderHeight,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: kTimeColWidth,
            child: Center(
              child: Text(
                'TIME',
                style: TextStyle(
                  color: kTimeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalHeaderCtrl,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: List.generate(
                  _barbers.length,
                      (i) => _buildBarberCard(i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarberCard(int index) {
    final isSelected = _selectedBarber == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedBarber = index),
      child: Container(
        width: kColumnWidth,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Colors.tealAccent.shade400
                  : Colors.transparent,
              width: 3,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(kBarberImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _barbers[index].name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: kTextDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── BODY SCROLL ───────────────────
  Widget _buildScrollableBody() {
    return SingleChildScrollView(
      controller: _verticalCtrl,
      physics: const ClampingScrollPhysics(),
      child: SizedBox(
        height: _gridHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeColumn(),
            Expanded(
              child: SingleChildScrollView(
                controller: _horizontalBodyCtrl,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: _barbers.length * (kColumnWidth + 8),
                  height: _gridHeight,
                  child: Stack(
                    children: [
                      _buildHourLines(),
                      Row(
                        children: List.generate(
                          _barbers.length,
                              (i) => _buildBarberColumn(i),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn() {
    final List<Widget> labels = [];
    final totalSlots = _totalMinutes ~/ kSlotMinutes;
    for (int s = 0; s <= totalSlots; s++) {
      final minutesFromStart = s * kSlotMinutes;
      final hour = kStartHour + minutesFromStart ~/ 60;
      final minute = minutesFromStart % 60;
      final isFullHour = minute == 0;
      labels.add(Positioned(
        top: s * kSlotHeight - 7,
        left: 0,
        right: 0,
        child: Center(
          child: Text(
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: isFullHour ? kTextDark : kTimeColor,
              fontSize: isFullHour ? 12 : 9,
              fontWeight: isFullHour ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ));
    }
    return SizedBox(
      width: kTimeColWidth,
      height: _gridHeight,
      child: Stack(children: labels),
    );
  }

  Widget _buildHourLines() {
    final List<Widget> lines = [];
    final totalHours = kEndHour - kStartHour;
    for (int h = 0; h <= totalHours; h++) {
      lines.add(Positioned(
        top: h * 4 * kSlotHeight,
        left: 0,
        right: 0,
        child: Container(height: 1, color: kGridLine),
      ));
    }
    return Stack(children: lines);
  }

  // Cada peluquero tiene su columna de ancho fijo. Las citas se
  // posicionan en `Stack` con `top`/`height` calculados desde la hora,
  // y siempre quedan dentro del ancho de su columna.
  Widget _buildBarberColumn(int barberId) {
    final apps = _appointments.where((a) => a.barberId == barberId).toList();

    return Container(
      width: kColumnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          ...apps.map(_buildPositionedAppointment),
        ],
      ),
    );
  }

  Widget _buildPositionedAppointment(_Appointment app) {
    final startMinutes =
        (app.startHour - kStartHour) * 60 + app.startMinute;
    final endMinutes = (app.endHour - kStartHour) * 60 + app.endMinute;
    final durationMinutes = endMinutes - startMinutes;

    final top = (startMinutes / kSlotMinutes) * kSlotHeight;
    final height = (durationMinutes / kSlotMinutes) * kSlotHeight;

    return Positioned(
      top: top + 2,
      left: 4,
      right: 4,
      height: height - 4,
      child: _AppointmentCard(app: app),
    );
  }

  // ─────────────────── FAB / BOTTOM BAR ───────────────────
  Widget _buildFloatingEditButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 70),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryPurple, kPrimaryPurpleDark],
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryPurple.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.edit_calendar_outlined,
            color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(color: kBackground),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryPurple, kPrimaryPurpleDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimaryPurple.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_today_outlined,
                color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'AGENDA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODELOS
// ═══════════════════════════════════════════════════════════════
class _Barber {
  final int id;
  final String name;
  const _Barber({required this.id, required this.name});
}

class _Appointment {
  final int barberId;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String tag;
  final Color tagColor;
  final Color tagTextColor;
  final Color accentColor;
  final String clientName;
  final String service;
  final bool confirmed;

  const _Appointment({
    required this.barberId,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.tag,
    required this.tagColor,
    required this.tagTextColor,
    required this.accentColor,
    required this.clientName,
    required this.service,
    required this.confirmed,
  });

  String get startTime =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  String get endTime =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
}

// ═══════════════════════════════════════════════════════════════
// APPOINTMENT CARD — Adapta su contenido al alto disponible
// ═══════════════════════════════════════════════════════════════
class _AppointmentCard extends StatelessWidget {
  final _Appointment app;
  const _AppointmentCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        // Niveles de detalle según altura disponible
        final isTiny = h < 50; // 30 min o menos
        final isShort = h < 80; // ~45 min
        final isMedium = h < 120; // ~60 min

        return Container(
          padding: EdgeInsets.fromLTRB(
            10,
            isTiny ? 4 : 8,
            8,
            isTiny ? 4 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: app.accentColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTiny) ...[
                  // Variante TINY: una sola fila con nombre y hora
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.clientName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          app.startTime,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF8A8A9B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: app.tagColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            app.tag,
                            style: TextStyle(
                              color: app.tagTextColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        app.startTime,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF8A8A9B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.clientName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                    maxLines: isShort ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isShort) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${app.startTime} – ${app.endTime}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF8A8A9B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (!isMedium && app.service.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        app.service,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8A8A9B),
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ],
                  if (!isMedium && app.confirmed) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6B3FD4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 8),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'CONFIRMED',
                          style: TextStyle(
                            color: Color(0xFF6B3FD4),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/*
PRIMERA VERSION
import 'package:flutter/material.dart';

/// Vista previa de la Agenda Diaria del Portal de Administración
/// de Victorino Style. Muestra las citas de todos los peluqueros
/// en una cuadrícula con horas y profesionales.
class AgendaAdminPreview extends StatefulWidget {
  const AgendaAdminPreview({super.key});

  @override
  State<AgendaAdminPreview> createState() => _AgendaAdminPreviewState();
}

class _AgendaAdminPreviewState extends State<AgendaAdminPreview> {
  // Color principal morado de la marca
  static const Color kPrimaryPurple = Color(0xFF6B3FD4);
  static const Color kPrimaryPurpleDark = Color(0xFF4A2BA8);
  static const Color kBackground = Color(0xFFF7F5FA);
  static const Color kCardBg = Colors.white;
  static const Color kTextDark = Color(0xFF1A1A2E);
  static const Color kTextMuted = Color(0xFF8A8A9B);
  static const Color kTimeColor = Color(0xFFB5B5C3);

  // Color de tags
  static const Color kTagPurple = Color(0xFFE9DEFF);
  static const Color kTagPurpleText = Color(0xFF6B3FD4);
  static const Color kTagTeal = Color(0xFFB8F0E8);
  static const Color kTagTealText = Color(0xFF0FA89B);

  // Ruta de imagen reutilizada para todos los peluqueros
  static const String kBarberImage = 'assets/imagenes/barbero_1.png';

  // Selección actual de peluquero (índice)
  int _selectedBarber = 1; // Elena seleccionada por defecto como en el diseño

  final List<String> _barbers = ['Marco', 'Elena', 'Carlos'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 16),
                    _buildSelectDateButton(),
                    const SizedBox(height: 20),
                    _buildAgendaGrid(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingEditButton(),
      // bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─────────────────────────── HEADER ───────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.menu, color: kPrimaryPurple, size: 26),
              const SizedBox(width: 16),
              const Text(
                'VICTORINO STYLE',
                style: TextStyle(
                  color: kPrimaryPurple,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 1),
              image: const DecorationImage(
                image: AssetImage(kBarberImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── TITLE: Daily Agenda ───────────────────
  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'MANAGEMENT PORTAL',
            style: TextStyle(
              color: Color(0xFF1F6B6B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Daily Agenda',
            style: TextStyle(
              color: kTextDark,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Wednesday, October 25, 2023',
            style: TextStyle(
              color: kTextMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── SELECT DATE BUTTON ───────────────────
  Widget _buildSelectDateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAEF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.calendar_today_outlined,
                size: 16, color: kTextDark),
            SizedBox(width: 8),
            Text(
              'Select Date',
              style: TextStyle(
                color: kTextDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── AGENDA GRID ───────────────────
  Widget _buildAgendaGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEDF3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Fila de peluqueros (header de columnas)
          _buildBarbersRow(),
          const SizedBox(height: 12),
          // Filas de horas con citas
          _buildTimeSlots(),
        ],
      ),
    );
  }

  Widget _buildBarbersRow() {
    return Row(
      children: [
        // Columna TIME
        const SizedBox(
          width: 50,
          child: Text(
            'TIME',
            style: TextStyle(
              color: kTimeColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        // Avatares de peluqueros con scroll horizontal
        Expanded(
          child: SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _barbers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _buildBarberCard(i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarberCard(int index) {
    final isSelected = _selectedBarber == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedBarber = index),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.tealAccent.shade400 : Colors.transparent,
              width: 3,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(kBarberImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _barbers[index],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: kTextDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── TIME SLOTS ───────────────────
  Widget _buildTimeSlots() {
    final timeSlots = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00'];

    return Column(
      children: [
        // 09:00 - dos citas en paralelo (Jonathan / Sarah)
        _timeRow(
          '09:00',
          children: [
            _appointmentCard(
              tagText: 'EXECUTIVE CUT',
              tagColor: kTagPurple,
              tagTextColor: kTagPurpleText,
              accentColor: kPrimaryPurple,
              startTime: '09:00',
              endTime: '10:30',
              clientName: 'Jonathan\nRivers',
              service: 'Full service with beard grooming.',
              confirmed: true,
            ),
            _appointmentCard(
              tagText: 'BALAYAGE & TONE',
              tagColor: kTagTeal,
              tagTextColor: kTagTealText,
              accentColor: kTagTealText,
              startTime: '09:00',
              endTime: '11:30',
              clientName: 'Sarah Jenkins',
              service: 'Full highlight treatment. Premium package with hydration mask.',
              confirmed: false,
            ),
          ],
        ),
        // 10:00 - vacío + slot vacío con +
        _timeRow('10:00', children: const []),
        // 11:00 - slot vacío con + para Marco
        _timeRow(
          '11:00',
          children: [
            _emptySlotCard(),
            const SizedBox.shrink(),
          ],
        ),
        // 12:00 - Marcus Chen quick trim
        _timeRow(
          '12:00',
          children: [
            _appointmentCard(
              tagText: 'QUICK TRIM',
              tagColor: kTagPurple,
              tagTextColor: kTagPurpleText,
              accentColor: kPrimaryPurple,
              startTime: '13:15',
              endTime: '',
              clientName: 'Marcus Chen',
              service: '',
              confirmed: false,
              compact: true,
            ),
            const SizedBox.shrink(),
          ],
        ),
        // 13:00 - vacío
        _timeRow('13:00', children: const []),
      ],
    );
  }

  Widget _timeRow(String time, {required List<Widget> children}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hora
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                time,
                style: const TextStyle(
                  color: kTimeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Citas para cada peluquero
          Expanded(
            child: SizedBox(
              height: children.isEmpty ? 70 : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (children.isNotEmpty) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6, bottom: 8),
                        child: children[0],
                      ),
                    ),
                    if (children.length > 1)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 8),
                          child: children[1],
                        ),
                      )
                    else
                      const Expanded(child: SizedBox.shrink()),
                  ] else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── APPOINTMENT CARD ───────────────────
  Widget _appointmentCard({
    required String tagText,
    required Color tagColor,
    required Color tagTextColor,
    required Color accentColor,
    required String startTime,
    required String endTime,
    required String clientName,
    required String service,
    required bool confirmed,
    bool compact = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag + tiempos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tagText,
                    style: TextStyle(
                      color: tagTextColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    startTime,
                    style: const TextStyle(
                      fontSize: 10,
                      color: kTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (endTime.isNotEmpty) ...[
                    const Text('-',
                        style: TextStyle(
                            fontSize: 9, color: kTextMuted, height: 0.8)),
                    Text(
                      endTime,
                      style: const TextStyle(
                        fontSize: 10,
                        color: kTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Nombre del cliente
          Text(
            clientName,
            style: const TextStyle(
              fontSize: 14,
              color: kTextDark,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          if (service.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              service,
              style: const TextStyle(
                fontSize: 11,
                color: kTextMuted,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (confirmed) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: kPrimaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 10),
                ),
                const SizedBox(width: 6),
                const Text(
                  'CONFIRMED',
                  style: TextStyle(
                    color: kPrimaryPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────── EMPTY SLOT (DASHED) ───────────────────
  Widget _emptySlotCard() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kTextMuted.withOpacity(0.4),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          color: kTextMuted.withOpacity(0.7),
          size: 24,
        ),
      ),
    );
  }

  // ─────────────────── FLOATING EDIT BUTTON ───────────────────
  Widget _buildFloatingEditButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 70),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryPurple, kPrimaryPurpleDark],
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryPurple.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.edit_calendar_outlined,
            color: Colors.white, size: 24),
      ),
    );
  }

  /*
  // ─────────────────── BOTTOM BAR ───────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: kBackground,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryPurple, kPrimaryPurpleDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimaryPurple.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_today_outlined,
                color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'AGENDA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

   */
}

 */