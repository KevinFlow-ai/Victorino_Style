import 'package:flutter/material.dart';

class AgendaAdminPage extends StatefulWidget {
  const AgendaAdminPage({super.key});

  @override
  State<AgendaAdminPage> createState() => _AgendaAdminPageState();
}

class _AgendaAdminPageState extends State<AgendaAdminPage> {
  final ScrollController _hoursController = ScrollController();
  final ScrollController _gridController = ScrollController();

  final double hourHeight = 80;
  bool _syncing = false;

  final List<String> barberImages = [
    'assets/imagenes/barbero_1.png',
    'assets/imagenes/barbero_1.png',
    'assets/imagenes/barbero_1.png',
  ];
  final List<String> barbers = ['Marco', 'Elena', 'Luis'];

  List<Appointment> appointments = [
    Appointment(barberIndex: 0, startMinutes: 540, duration: 90, name: 'Jonathan'),
    Appointment(barberIndex: 1, startMinutes: 600, duration: 60, name: 'Sarah'),
  ];

  @override
  void initState() {
    super.initState();

    /// Sync scroll
    _hoursController.addListener(() {
      if (_syncing) return;
      _syncing = true;
      if (_gridController.hasClients) {
        _gridController.jumpTo(_hoursController.offset);
      }
      _syncing = false;
    });

    _gridController.addListener(() {
      if (_syncing) return;
      _syncing = true;
      if (_hoursController.hasClients) {
        _hoursController.jumpTo(_gridController.offset);
      }
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda Pro')),
      body: Column(
        children: [
          /// 🔥 DAYS BAR
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (_, i) {
                final isSelected = i == 2;

                return Container(
                  width: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Wed',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      ),
                      Text(
                        '25',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          /// 🔥 CALENDAR
          Expanded(
            child: Row(
              children: [
                /// HOURS COLUMN
                SizedBox(
                  width: 60,
                  child: ListView.builder(
                    controller: _hoursController,
                    itemCount: 24,
                    itemBuilder: (_, i) => SizedBox(
                      height: hourHeight,
                      child: Center(
                        child: Text(
                          '${i.toString().padLeft(2, '0')}:00',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ),

                /// GRID (SCROLL GLOBAL)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _gridController,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          barbers.length,
                              (index) => _buildColumn(index),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildColumn(int barberIndex) {
    final theme = Theme.of(context);

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          /// 🔥 HEADER BARBER (SIN IMAGEN)
          const SizedBox(height: 8),

          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(barberImages[barberIndex]),
            onBackgroundImageError: (_, __) {},
          ),

          const SizedBox(height: 4),

          Text(
            barbers[barberIndex],
            style: theme.textTheme.labelSmall,
          ),

          const SizedBox(height: 8),

          /// GRID + APPOINTMENTS
          SizedBox(
            height: 24 * hourHeight,
            child: Stack(
              children: [
                /// GRID LINES
                Column(
                  children: List.generate(
                    24,
                        (i) => Container(
                      height: hourHeight,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ),

                /// APPOINTMENTS
                ...appointments
                    .where((a) => a.barberIndex == barberIndex)
                    .map((a) => _appointmentWidget(a))
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _appointmentWidget(Appointment a) {
    return Positioned(
      top: _minutesToPixels(a.startMinutes),
      left: 8,
      right: 8,
      height: _minutesToPixels(a.duration),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            a.startMinutes += _pixelsToMinutes(details.delta.dy);

            /// límites
            if (a.startMinutes < 0) a.startMinutes = 0;
            if (a.startMinutes > 1440 - a.duration) {
              a.startMinutes = 1440 - a.duration;
            }

            /// snap 15 min
            a.startMinutes = ((a.startMinutes / 15).round()) * 15;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.name),
              Text(_formatTime(a.startMinutes)),
            ],
          ),
        ),
      ),
    );
  }

  double _minutesToPixels(int minutes) {
    return (minutes / 60) * hourHeight;
  }

  int _pixelsToMinutes(double pixels) {
    return (pixels / hourHeight * 60).round();
  }

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class Appointment {
  int barberIndex;
  int startMinutes;
  int duration;
  String name;

  Appointment({
    required this.barberIndex,
    required this.startMinutes,
    required this.duration,
    required this.name,
  });
}
