import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/customer_service.dart';

class CustomerActivityScreen extends StatefulWidget {
  final CustomerService customerService;
  final ValueChanged<Map<String, dynamic>>? onSelectDelivery;

  const CustomerActivityScreen({
    super.key,
    required this.customerService,
    this.onSelectDelivery,
  });

  @override
  State<CustomerActivityScreen> createState() => _CustomerActivityScreenState();
}

class _CustomerActivityScreenState extends State<CustomerActivityScreen> {
  List<Map<String, dynamic>> _deliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() => _loading = true);
    final history = await widget.customerService.getDeliveryHistory();
    if (mounted) {
      setState(() {
        _deliveries = history;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _loadActivity,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Past Deliveries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.clearBlue))
                    : _deliveries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.surfaceMuted,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Deliveries Yet',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'When you book a courier in Tamale,\nyour orders and receipts will appear here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _deliveries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _deliveries[index];
                              final fare = (item['fare'] as num?)?.toDouble() ?? 20.0;
                              final status = item['status'] ?? 'delivered';
                              final isDelivered = status == 'delivered';

                              return InkWell(
                                onTap: () {
                                  if (widget.onSelectDelivery != null) {
                                    widget.onSelectDelivery!(item);
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.border),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isDelivered ? AppTheme.successBg : AppTheme.blueTint,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isDelivered ? Icons.check_circle_outline : Icons.local_shipping_outlined,
                                          color: isDelivered ? AppTheme.success : AppTheme.clearBlue,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Order #${item['id'].toString().substring(0, 8)}',
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item['pickup_text'] ?? 'Pickup'} → ${item['dropoff_text'] ?? 'Dropoff'}',
                                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'GH₵ ${fare.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDelivered ? AppTheme.successBg : const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              status.toString().toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: isDelivered ? AppTheme.success : AppTheme.clearBlue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
