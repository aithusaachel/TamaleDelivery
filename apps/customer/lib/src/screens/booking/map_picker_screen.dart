import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  final bool isPickup;
  final String initialAddress;

  const MapPickerScreen({
    super.key,
    required this.isPickup,
    this.initialAddress = '',
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final TextEditingController _addressController;
  int _selectedPresetIndex = 0;

  static const List<String> mapLocations = [
    'Tamale Central Market, Gate 3',
    'Aboabo Market, Station Road',
    'Lamashegu Industrial Fitting',
    'Kukuo Nursing Training Road',
    'Tamale Airport Terminal Arrival',
    'Vittin Barrier, Yendi Road Junction',
  ];

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: widget.initialAddress.isNotEmpty ? widget.initialAddress : mapLocations[0],
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isPickup ? 'Pin Pickup Location' : 'Pin Destination';
    final actionLabel = widget.isPickup ? 'CONFIRM PICKUP' : 'CONFIRM DESTINATION';

    return Scaffold(
      backgroundColor: const Color(0xFF131C2E),
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Simulated Map Canvas (Moves beneath the pin)
          CustomPaint(
            size: Size.infinite,
            painter: _MapCanvasPainter(),
          ),

          // Fixed Center Pin (Section 3.5: Fixed pin at the centre, map moves beneath it)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.midnightNavy,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
                      ],
                    ),
                    child: Text(
                      widget.isPickup ? 'PICKUP' : 'DESTINATION',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.location_on,
                    size: 44,
                    color: widget.isPickup ? AppTheme.success : const Color(0xFFEF4444),
                  ),
                  Container(
                    width: 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pan / Location Simulation Switcher
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.clearBlue,
              onPressed: () {
                setState(() {
                  _selectedPresetIndex = (_selectedPresetIndex + 1) % mapLocations.length;
                  _addressController.text = mapLocations[_selectedPresetIndex];
                });
              },
              tooltip: 'Center on next area',
              child: const Icon(Icons.my_location),
            ),
          ),

          // Bottom Sheet with Resolved Address & Confirmation
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.place,
                        color: widget.isPickup ? AppTheme.success : const Color(0xFFEF4444),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Pinned Location in Tamale',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _addressController,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Resolved Address / Landmark',
                      filled: true,
                      fillColor: AppTheme.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _addressController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isPickup ? AppTheme.success : AppTheme.clearBlue,
                    ),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke;

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.5)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    // Draw street grid
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.55), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.8), secondaryRoadPaint);

    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), secondaryRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
