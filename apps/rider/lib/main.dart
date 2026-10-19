import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/theme/app_theme.dart';
import 'src/services/rider_service.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/earnings_screen.dart';
import 'src/screens/account_screen.dart';
import 'src/screens/offer_screen.dart';
import 'src/screens/active_delivery_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase live credentials
  await Supabase.initialize(
    url: 'https://uzxljljjsxchbwqtqryf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6eGxqbGpqc3hjaGJ3cXRxcnlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0MTQxNDcsImV4cCI6MjEwNzk5MDE0N30.wdV7m-q_9aFU3FOzxQKW8RlnUY6Ocin5tRK8bdOEXxw',
  );

  runApp(const TamaleRiderApp());
}

class TamaleRiderApp extends StatelessWidget {
  const TamaleRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamale Courier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const RiderRootShell(),
    );
  }
}

class RiderRootShell extends StatefulWidget {
  const RiderRootShell({super.key});

  @override
  State<RiderRootShell> createState() => _RiderRootShellState();
}

class _RiderRootShellState extends State<RiderRootShell> {
  int _currentIndex = 0;
  final RiderService _riderService = RiderService();

  // Active delivery or incoming offer state
  Map<String, dynamic>? _activeDelivery;
  bool _showingOffer = false;

  void _triggerSimulatedOffer() {
    setState(() => _showingOffer = true);
  }

  void _acceptSimulatedOffer() {
    setState(() {
      _showingOffer = false;
      _activeDelivery = {
        'id': 'd7b1a209-1122-4433-8899-abcdef123456',
        'fare': 20.00,
        'commission_rate': 0.15,
        'payer': 'receiver',
        'receiver_name': 'Fatima Adams',
        'receiver_phone': '0241234567',
        'pickup_text': 'Tamale Central Market, Gate 3',
        'dropoff_text': 'Kukuo Nursing Training Road',
      };
    });
  }

  void _declineOffer() {
    setState(() => _showingOffer = false);
  }

  void _completeActiveDelivery() {
    setState(() {
      _activeDelivery = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delivery Completed! Fare collected and commission recorded.'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. If currently on an active delivery, show ActiveDeliveryScreen (Bottom nav hidden per Section 4.2)
    if (_activeDelivery != null) {
      return ActiveDeliveryScreen(
        delivery: _activeDelivery!,
        riderService: _riderService,
        onComplete: _completeActiveDelivery,
      );   
    }

    // 2. If an offer arrives, show 30s focused countdown screen (Bottom nav hidden)
    if (_showingOffer) {
      return JobOfferScreen(
        pickupDistanceKm: 1.2,
        tripDistanceKm: 3.5,
        vehicle: 'Motorbike',
        totalFare: 20.00,
        netEarning: 17.00, // GH₵20.00 - 15% platform commission
        pickupAddress: 'Tamale Central Market, Gate 3',
        dropoffAddress: 'Kukuo Nursing Training Road',
        packageType: 'Parcel & Documents • Cash on Delivery',
        estimatedMinutes: 14,
        onAccept: _acceptSimulatedOffer,
        onDecline: _declineOffer,
      );
    }

    // 3. Normal 3-Tab Rider Interface
    final screens = [
      RiderHomeScreen(
        riderService: _riderService,
        onOfferTest: _triggerSimulatedOffer,
      ),
      RiderEarningsScreen(riderService: _riderService),
      RiderAccountScreen(riderService: _riderService),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppTheme.clearBlue,
          unselectedItemColor: AppTheme.textSecondary,
          backgroundColor: AppTheme.surface,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.two_wheeler_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.two_wheeler),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.account_balance_wallet_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.account_balance_wallet),
              ),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person),
              ),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
