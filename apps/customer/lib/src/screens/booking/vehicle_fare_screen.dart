import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/customer_service.dart';

class VehicleFareScreen extends StatefulWidget {
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;
  final CustomerService customerService;
  final Function(String vehicleType, double fare) onVehicleSelected;

  const VehicleFareScreen({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.customerService,
    required this.onVehicleSelected,
  });

  @override
  State<VehicleFareScreen> createState() => _VehicleFareScreenState();
}

class _VehicleFareScreenState extends State<VehicleFareScreen> {
  String _selectedVehicle = 'motorbike';

  @override
  Widget build(BuildContext context) {
    final motorbikeFare = widget.customerService.calculateFare(
      distanceKm: widget.distanceKm,
      vehicle: 'motorbike',
    );

    final motoKingFare = widget.customerService.calculateFare(
      distanceKm: widget.distanceKm,
      vehicle: 'moto_king',
    );

    final currentFare = _selectedVehicle == 'motorbike' ? motorbikeFare : motoKingFare;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Choose Delivery Type'),
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
                    // Route Overview Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.pickupAddress,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
                            height: 20,
                            alignment: Alignment.centerLeft,
                            child: Container(width: 2, height: 20, color: AppTheme.border),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.dropoffAddress,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.straighten, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Estimated Route Distance: ${widget.distanceKm} km',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'AVAILABLE VEHICLES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vehicle 1: Motorbike
                    _buildVehicleCard(
                      id: 'motorbike',
                      title: 'Motorbike',
                      description: 'Small parcels, envelopes, meals & boxes',
                      fare: motorbikeFare,
                      icon: Icons.two_wheeler,
                      isSelected: _selectedVehicle == 'motorbike',
                    ),

                    const SizedBox(height: 12),

                    // Vehicle 2: Moto King
                    _buildVehicleCard(
                      id: 'moto_king',
                      title: 'Moto King (Tricycle)',
                      description: 'Heavy cargo, sacks, building materials & bulk',
                      fare: motoKingFare,
                      icon: Icons.electric_rickshaw,
                      isSelected: _selectedVehicle == 'moto_king',
                    ),

                    const SizedBox(height: 18),
                    Row(
                      children: const [
                        Icon(Icons.lock_clock_outlined, size: 14, color: AppTheme.textMuted),
                        SizedBox(width: 6),
                        Text(
                          'Guaranteed upfront fare • Cash on delivery',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Continue Button with Selected Fare
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: ElevatedButton(
                onPressed: () {
                  widget.onVehicleSelected(_selectedVehicle, currentFare);
                },
                child: Text('CONTINUE WITH ${_selectedVehicle.toUpperCase()} · GH₵ ${currentFare.toStringAsFixed(2)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard({
    required String id,
    required String title,
    required String description,
    required double fare,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedVehicle = id),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.clearBlue : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppTheme.clearBlue.withOpacity(0.08) : Colors.black.withOpacity(0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.blueTint : AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isSelected ? AppTheme.clearBlue : AppTheme.textSecondary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppTheme.clearBlue : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'GH₵ ${fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Radio<String>(
                  value: id,
                  groupValue: _selectedVehicle,
                  activeColor: AppTheme.clearBlue,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedVehicle = val);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
