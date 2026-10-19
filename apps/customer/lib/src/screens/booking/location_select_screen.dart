import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'map_picker_screen.dart';

class LocationSelectScreen extends StatefulWidget {
  final String initialPickup;
  final String initialDropoff;
  final bool focusPickup;
  final Function(String pickup, String dropoff, double distanceKm) onLocationsConfirmed;

  const LocationSelectScreen({
    super.key,
    this.initialPickup = 'Tamale Central Market, Gate 3',
    this.initialDropoff = '',
    this.focusPickup = true,
    required this.onLocationsConfirmed,
  });

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  late final TextEditingController _pickupController;
  late final TextEditingController _dropoffController;
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _dropoffFocusNode = FocusNode();

  static const List<String> quickAddresses = [
    'Central Market, Gate 3',
    'Aboabo Market, Station Road',
    'Tamale Airport, Arrivals Gate',
    'Lamashegu Industrial Fitting',
    'Kukuo Nursing Training Road',
    'Vittin Barrier, Yendi Road',
    'Education Ridge, Police HQ',
    'Nyankpala Campus Road',
  ];

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController(text: widget.initialPickup);
    _dropoffController = TextEditingController(text: widget.initialDropoff);

    // Focus cursor based on whether user chose Send or Receive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusPickup) {
        _pickupFocusNode.requestFocus();
        _pickupController.selection = TextSelection(baseOffset: 0, extentOffset: _pickupController.text.length);
      } else {
        _dropoffFocusNode.requestFocus();
        _dropoffController.selection = TextSelection(baseOffset: 0, extentOffset: _dropoffController.text.length);
      }
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    super.dispose();
  }

  void _openMapPicker({required bool isPickup}) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          isPickup: isPickup,
          initialAddress: isPickup ? _pickupController.text : _dropoffController.text,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isPickup) {
          _pickupController.text = result;
          _dropoffFocusNode.requestFocus();
        } else {
          _dropoffController.text = result;
        }
      });
    }
  }

  void _confirm() {
    final pickup = _pickupController.text.trim();
    final dropoff = _dropoffController.text.trim();

    if (pickup.isEmpty || dropoff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify both pickup and delivery locations.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (pickup.toLowerCase() == dropoff.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and destination cannot be identical.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final distanceKm = 4.2;
    widget.onLocationsConfirmed(pickup, dropoff, distanceKm);
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _pickupController.text.trim().isNotEmpty && _dropoffController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE), // Warm Ivory
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(widget.focusPickup ? 'Send a Package' : 'Receive a Package'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Location Input Card
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 350),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, child) {
                        return Opacity(
                          opacity: val,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - val)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Sender / Pickup Field
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextField(
                                    controller: _pickupController,
                                    focusNode: _pickupFocusNode,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    decoration: const InputDecoration(
                                      labelText: 'Sender / Pickup Location',
                                      hintText: 'Enter sender location',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.map_outlined, color: AppTheme.clearBlue, size: 22),
                                  onPressed: () => _openMapPicker(isPickup: true),
                                  tooltip: 'Pick on map',
                                ),
                              ],
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Divider(color: AppTheme.divider),
                            ),

                            // Receiver / Destination Field
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextField(
                                    controller: _dropoffController,
                                    focusNode: _dropoffFocusNode,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    decoration: const InputDecoration(
                                      labelText: 'Receiver / Delivery Destination',
                                      hintText: 'Enter delivery address in Tamale',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.map_outlined, color: AppTheme.clearBlue, size: 22),
                                  onPressed: () => _openMapPicker(isPickup: false),
                                  tooltip: 'Pick on map',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Address suggestions
                    const Text(
                      'SUGGESTIONS IN TAMALE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: quickAddresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final loc = quickAddresses[index];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (_pickupFocusNode.hasFocus) {
                                _pickupController.text = loc;
                                _dropoffFocusNode.requestFocus();
                              } else {
                                _dropoffController.text = loc;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border.withOpacity(0.6)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 18, color: AppTheme.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    loc,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                ),
                                const Icon(Icons.north_west, size: 14, color: AppTheme.textMuted),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Confirm Locations Bottom Action
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: ElevatedButton(
                onPressed: canConfirm ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canConfirm ? AppTheme.clearBlue : AppTheme.surfaceMuted,
                  foregroundColor: canConfirm ? Colors.white : AppTheme.textMuted,
                ),
                child: const Text('CONFIRM LOCATIONS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
