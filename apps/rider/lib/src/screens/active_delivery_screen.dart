import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/rider_service.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;
  final RiderService riderService;
  final VoidCallback onComplete;

  const ActiveDeliveryScreen({
    super.key,
    required this.delivery,
    required this.riderService,
    required this.onComplete,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  // Stages:
  // 0: Heading to Pickup
  // 1: Arrived at Pickup
  // 2: Heading to Dropoff
  // 3: Arrived at Dropoff (Verify 4-digit code)
  int _currentStageIndex = 0;
  final TextEditingController _codeController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _stages = [
    {
      'title': 'Heading to Pickup',
      'instruction': 'Turn right onto Tamale Central Market Way in 200m',
      'targetAddress': 'Tamale Central Market, Gate 3',
      'targetType': 'PICKUP',
      'action': 'I Have Arrived at Pickup',
      'distance': '1.2 km',
      'eta': '4 mins',
      'turnIcon': Icons.turn_right,
    },
    {
      'title': 'At Pickup Point',
      'instruction': 'Locate sender and collect package',
      'targetAddress': 'Tamale Central Market, Gate 3',
      'targetType': 'COLLECT PACKAGE',
      'action': 'Confirm Package Picked Up',
      'distance': '0 m',
      'eta': 'At Pickup',
      'turnIcon': Icons.inventory_2,
    },
    {
      'title': 'Heading to Destination',
      'instruction': 'Continue straight toward Hospital Road / Kukuo in 500m',
      'targetAddress': 'Kukuo Nursing Training Road',
      'targetType': 'DROP-OFF',
      'action': 'I Have Arrived at Destination',
      'distance': '3.5 km',
      'eta': '11 mins',
      'turnIcon': Icons.straight,
    },
    {
      'title': 'At Delivery Location',
      'instruction': 'Hand over package & collect cash',
      'targetAddress': 'Kukuo Nursing Training Road',
      'targetType': 'HANDOVER & CODE',
      'action': 'Enter Receiver 4-Digit Code',
      'distance': '0 m',
      'eta': 'At Dropoff',
      'turnIcon': Icons.verified_user,
    },
  ];

  void _nextStage() {
    if (_currentStageIndex < _stages.length - 1) {
      setState(() => _currentStageIndex++);
    } else {
      _showCodeVerificationDialog();
    }
  }

  void _showCodeVerificationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Receiver Handover Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ask the receiver for their 4-digit security code to verify handover and confirm cash collection.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 20,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      hintText: '••••',
                      hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.clearBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            final code = _codeController.text.trim();
                            if (code.length != 4) {
                              setModalState(() => _errorMessage = 'Please enter all 4 digits of the code.');
                              return;
                            }

                            setModalState(() {
                              _submitting = true;
                              _errorMessage = null;
                            });

                            try {
                              final result = await widget.riderService.completeDelivery(
                                widget.delivery['id'],
                                code,
                              );

                              if (result['ok'] == true) {
                                if (mounted) {
                                  Navigator.pop(context);
                                  widget.onComplete();
                                }
                              } else {
                                setModalState(() {
                                  _submitting = false;
                                  if (result['error'] == 'wrong_code') {
                                    _errorMessage = 'Wrong code. Please confirm with the receiver.';
                                  } else if (result['error'] == 'locked') {
                                    _errorMessage = 'Code guessing locked for 15 minutes.';
                                  } else {
                                    _errorMessage = 'Could not verify delivery code.';
                                  }
                                });
                              }
                            } catch (e) {
                              setModalState(() {
                                _submitting = false;
                                _errorMessage = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'CONFIRM HANDOVER & COLLECT CASH',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_currentStageIndex];
    final fare = (widget.delivery['fare'] as num?)?.toDouble() ?? 20.0;
    final payer = widget.delivery['payer'] ?? 'receiver';
    final pickupText = widget.delivery['pickup_text'] ?? 'Tamale Central Market, Gate 3';
    final dropoffText = widget.delivery['dropoff_text'] ?? 'Kukuo Nursing Training Road';

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.clearBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'STAGE ${_currentStageIndex + 1} OF 4',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF60A5FA)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Order #${widget.delivery['id'].toString().substring(0, 8)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Cash Collection Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              color: const Color(0xFFD97706),
              child: Row(
                children: [
                  const Icon(Icons.payments, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COLLECT GH₵ ${fare.toStringAsFixed(2)} IN CASH',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                            Text(
                              payer == 'receiver' ? 'Collect from receiver at destination' : 'Collect from sender at pickup',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('COD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Turn-by-Turn Simulated Navigation Header (Uber/Bolt Style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: const Color(0xFF0F172A),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.clearBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(stage['turnIcon'] as IconData, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage['instruction'] as String,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${stage['distance']} • ${stage['eta']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF60A5FA)),
                            ),
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: Colors.white24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stage['title'] as String,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Simulated Map Route Canvas with Path Trajectory
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF131C2E),
                child: Stack(
                  children: [
                    // Simulated Road Grid
                    CustomPaint(
                      size: Size.infinite,
                      painter: _SimulatedRoadPainter(
                        isPickupStage: _currentStageIndex <= 1,
                      ),
                    ),

                    // Top Floating Waypoint Card
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.darkBorder),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentStageIndex <= 1 ? AppTheme.success : const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stage['targetType'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: _currentStageIndex <= 1 ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                    ),
                                  ),
                                  Text(
                                    stage['targetAddress'] as String,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Google Maps integration notice (temporary simulation badge)
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.map_outlined, color: Color(0xFF94A3B8), size: 12),
                            SizedBox(width: 6),
                            Text(
                              'Live GPS route simulation • Connects to Google Maps SDK',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Task Control & Recipient Details Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full Route Summary (Pickup & Dropoff)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle, color: AppTheme.success, size: 10),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pickup: $pickupText',
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 12),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dropoff: $dropoffText',
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Customer Contact
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recipient Contact',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.delivery['receiver_name'] ?? 'Fatima Adams',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.clearBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.phone, color: Color(0xFF60A5FA), size: 20),
                              tooltip: 'Call Recipient',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.directions, color: Color(0xFF34D399), size: 20),
                              tooltip: 'Open Turn-by-Turn GPS',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: _nextStage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStageIndex == _stages.length - 1 ? AppTheme.success : AppTheme.clearBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    child: Text(stage['action'] as String),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to simulate road grid and route path (Uber/Bolt look)
class _SimulatedRoadPainter extends CustomPainter {
  final bool isPickupStage;

  _SimulatedRoadPainter({required this.isPickupStage});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;

    final thinRoadPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.6)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    // Draw background grid roads
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), thinRoadPaint);

    // Draw glowing route path (Blue polyline)
    final path = Path();
    path.moveTo(size.width * 0.35, size.height * 0.8);
    path.lineTo(size.width * 0.35, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.25);

    final routeGlow = Paint()
      ..color = const Color(0xFF2563EB).withOpacity(0.3)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePolyline = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, routeGlow);
    canvas.drawPath(path, routePolyline);

    // Courier Position (Motorbike Pin on Route)
    final courierPaint = Paint()..color = const Color(0xFF2563EB);
    final courierCenter = Offset(size.width * 0.35, size.height * 0.55);
    canvas.drawCircle(courierCenter, 14, courierPaint);
    canvas.drawCircle(courierCenter, 20, Paint()..color = const Color(0x332563EB)..style = PaintingStyle.stroke..strokeWidth = 3);

    // Waypoint Destination Pin
    final targetCenter = Offset(size.width * 0.75, size.height * 0.25);
    final pinPaint = Paint()..color = isPickupStage ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    canvas.drawCircle(targetCenter, 12, pinPaint);
    canvas.drawCircle(targetCenter, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SimulatedRoadPainter oldDelegate) {
    return oldDelegate.isPickupStage != isPickupStage;
  }
}
