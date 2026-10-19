import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/customer_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final CustomerService customerService;
  final VoidCallback onDismiss;

  const OrderTrackingScreen({
    super.key,
    required this.order,
    required this.customerService,
    required this.onDismiss,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // Stages: searching -> accepted -> arrived_pickup -> picked_up -> arrived_dropoff -> delivered
  String _status = 'searching';
  String _code = '4821';
  Timer? _simulationTimer;
  int _secondsPassed = 0;

  @override
  void initState() {
    super.initState();
    _code = widget.order['code'] ?? '4821';

    // Auto-advance simulation for pilot testing
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsPassed += 4;
        if (_secondsPassed == 4) {
          _status = 'accepted';
        } else if (_secondsPassed == 8) {
          _status = 'arrived_pickup';
        } else if (_secondsPassed == 12) {
          _status = 'picked_up';
        } else if (_secondsPassed == 16) {
          _status = 'arrived_dropoff';
        } else if (_secondsPassed >= 20) {
          _status = 'delivered';
          _simulationTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  String _getStatusTitle() {
    switch (_status) {
      case 'searching':
        return 'Finding a nearby courier...';
      case 'accepted':
        return 'Courier assigned • On the way to pickup';
      case 'arrived_pickup':
        return 'Courier arrived at pickup point';
      case 'picked_up':
        return 'Package picked up • Heading to destination';
      case 'arrived_dropoff':
        return 'Courier arrived at delivery destination';
      case 'delivered':
        return 'Delivery completed successfully!';
      case 'cancelled':
        return 'Delivery cancelled';
      default:
        return 'Tracking Delivery';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fare = (widget.order['fare'] as num?)?.toDouble() ?? 20.0;
    final isDelivered = _status == 'delivered';
    final isSearching = _status == 'searching';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text('Order #${widget.order['id'].toString().substring(0, 8)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onDismiss,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Stage Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: isDelivered ? AppTheme.success : AppTheme.clearBlue,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDelivered ? Icons.check_circle : (isSearching ? Icons.radar : Icons.two_wheeler),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusTitle(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          'Cash Fare: GH₵ ${fare.toStringAsFixed(2)} • ${widget.order['payer'] == 'sender' ? 'Sender pays at pickup' : 'Receiver pays on dropoff'}',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Map Simulation Canvas
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF131C2E),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: _TrackingMapPainter(status: _status),
                    ),

                    if (isSearching) ...[
                      // Searching Pulse Badge
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.clearBlue.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.clearBlue.withOpacity(0.3), width: 2),
                        ),
                        child: const Icon(Icons.radar, color: AppTheme.clearBlue, size: 48),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Panel
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 4-Digit Handover Security Code Card (High Contrast)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.midnightNavy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'HANDOVER SECURITY CODE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: Color(0xFF94A3B8)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Give this 4-digit code to rider',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.clearBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _code,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Courier Details (when assigned)
                  if (!isSearching) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.midnightNavy,
                          child: const Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Ibrahim Salifu',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tamale Courier • Motorbike (M-24-NR)',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.blueTint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.phone, color: AppTheme.clearBlue, size: 20),
                            onPressed: () {},
                            tooltip: 'Call Courier',
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Searching Action: Cancel option
                    OutlinedButton(
                      onPressed: () async {
                        await widget.customerService.cancelOrder(widget.order['id'].toString());
                        widget.onDismiss();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                        foregroundColor: AppTheme.error,
                      ),
                      child: const Text('Cancel Request'),
                    ),
                  ],

                  if (isDelivered) ...[
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      child: const Text('DONE · RETURN TO HOME'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingMapPainter extends CustomPainter {
  final String status;

  _TrackingMapPainter({required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke;

    // Background road lines
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), roadPaint);

    // Glowing route
    final path = Path();
    path.moveTo(size.width * 0.35, size.height * 0.7);
    path.lineTo(size.width * 0.35, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.2);

    final routePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, routePaint);

    // Pickup & Dropoff pins
    final pickupCenter = Offset(size.width * 0.35, size.height * 0.7);
    final dropoffCenter = Offset(size.width * 0.75, size.height * 0.2);

    canvas.drawCircle(pickupCenter, 8, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(dropoffCenter, 8, Paint()..color = const Color(0xFFEF4444));

    // Courier marker
    if (status != 'searching') {
      final courierPos = status == 'accepted' || status == 'arrived_pickup'
          ? Offset(size.width * 0.35, size.height * 0.55)
          : Offset(size.width * 0.55, size.height * 0.4);

      canvas.drawCircle(courierPos, 14, Paint()..color = const Color(0xFF2563EB));
      canvas.drawCircle(courierPos, 20, Paint()..color = const Color(0x332563EB)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant _TrackingMapPainter oldDelegate) => oldDelegate.status != status;
}
