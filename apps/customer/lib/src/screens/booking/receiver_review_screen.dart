import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/customer_service.dart';

class ReceiverReviewScreen extends StatefulWidget {
  final String pickupAddress;
  final String dropoffAddress;
  final String vehicleType;
  final double distanceKm;
  final double fare;
  final CustomerService customerService;
  final Function(Map<String, dynamic> createdOrder) onOrderCreated;

  const ReceiverReviewScreen({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.vehicleType,
    required this.distanceKm,
    required this.fare,
    required this.customerService,
    required this.onOrderCreated,
  });

  @override
  State<ReceiverReviewScreen> createState() => _ReceiverReviewScreenState();
}

class _ReceiverReviewScreenState extends State<ReceiverReviewScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _payer = 'sender'; // 'sender' | 'receiver'
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the receiver\'s name.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Ghana phone number (e.g. 0244123456).'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final order = await widget.customerService.createOrder(
        senderName: 'Customer',
        senderPhone: '0240000000',
        pickupAddress: widget.pickupAddress,
        dropoffAddress: widget.dropoffAddress,
        vehicleType: widget.vehicleType,
        distanceKm: widget.distanceKm,
        fare: widget.fare,
        receiverName: name,
        receiverPhone: phone,
        payer: _payer,
        instructions: _instructionsController.text.trim(),
      );

      if (mounted) {
        widget.onOrderCreated(order);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleTitle = widget.vehicleType == 'moto_king' ? 'Moto King (Cargo)' : 'Motorbike';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Review & Receiver Details'),
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
                    // Route & Fee Summary
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                vehicleTitle,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                              ),
                              Text(
                                'GH₵ ${widget.fare.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.clearBlue),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: AppTheme.divider),
                          Row(
                            children: [
                              const Icon(Icons.circle, color: AppTheme.success, size: 10),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'From: ${widget.pickupAddress}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 12),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'To: ${widget.dropoffAddress}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'RECEIVER CONTACT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Inputs
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Receiver Name',
                              hintText: 'e.g. Fatima Adams',
                              filled: true,
                              fillColor: AppTheme.surfaceMuted,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Receiver Phone Number',
                              hintText: 'e.g. 024 123 4567',
                              filled: true,
                              fillColor: AppTheme.surfaceMuted,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _instructionsController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Instructions / Landmark (Optional)',
                              hintText: 'e.g. Near blue kiosk by the mosque',
                              filled: true,
                              fillColor: AppTheme.surfaceMuted,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.notes, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'WHO PAYS THE RIDER?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Cash Payer Radio Selector
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'sender',
                            groupValue: _payer,
                            activeColor: AppTheme.clearBlue,
                            title: const Text(
                              'I pay the rider in cash at pickup',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            subtitle: const Text('Rider collects cash from you when picking up'),
                            onChanged: (val) => setState(() => _payer = val!),
                          ),
                          const Divider(height: 1, color: AppTheme.divider),
                          RadioListTile<String>(
                            value: 'receiver',
                            groupValue: _payer,
                            activeColor: AppTheme.clearBlue,
                            title: const Text(
                              'Receiver pays in cash upon delivery',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            subtitle: const Text('Rider collects cash from the recipient upon drop-off'),
                            onChanged: (val) => setState(() => _payer = val!),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Plain language payment statement
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _payer == 'sender'
                                  ? 'Payment Statement: You will pay GH₵ ${widget.fare.toStringAsFixed(2)} in cash to the rider at pickup.'
                                  : 'Payment Statement: The receiver will pay GH₵ ${widget.fare.toStringAsFixed(2)} in cash to the rider upon delivery.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Confirm Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('CONFIRM DELIVERY · GH₵ ${widget.fare.toStringAsFixed(2)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
