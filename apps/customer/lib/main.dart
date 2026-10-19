import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/theme/app_theme.dart';
import 'src/services/customer_service.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/activity_screen.dart';
import 'src/screens/account_screen.dart';
import 'src/screens/booking/location_select_screen.dart';
import 'src/screens/booking/vehicle_fare_screen.dart';
import 'src/screens/booking/receiver_review_screen.dart';
import 'src/screens/tracking/order_tracking_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase live credentials
  await Supabase.initialize(
    url: 'https://uzxljljjsxchbwqtqryf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6eGxqbGpqc3hjaGJ3cXRxcnlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0MTQxNDcsImV4cCI6MjEwNzk5MDE0N30.wdV7m-q_9aFU3FOzxQKW8RlnUY6Ocin5tRK8bdOEXxw',
  );

  runApp(const TamaleCustomerApp());
}

class TamaleCustomerApp extends StatelessWidget {
  const TamaleCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamale Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CustomerRootShell(),
    );
  }
}

class CustomerRootShell extends StatefulWidget {
  const CustomerRootShell({super.key});

  @override
  State<CustomerRootShell> createState() => _CustomerRootShellState();
}

class _CustomerRootShellState extends State<CustomerRootShell> {
  int _currentIndex = 0;
  final CustomerService _customerService = CustomerService();

  // Active delivery state (Step 4 Live Tracking)
  Map<String, dynamic>? _activeDelivery;

  // Start 4-Step Booking Journey
  void _startBookingFlow({String? presetDestination, bool focusPickup = true}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSelectScreen(
          initialDropoff: presetDestination ?? '',
          focusPickup: focusPickup,
          onLocationsConfirmed: (pickup, dropoff, distanceKm) {
            _onLocationsConfirmed(pickup, dropoff, distanceKm);
          },
        ),
      ),
    );
  }

  // Step 1 Completed -> Open Step 2 (Vehicle & Fare)
  void _onLocationsConfirmed(String pickup, String dropoff, double distanceKm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleFareScreen(
          pickupAddress: pickup,
          dropoffAddress: dropoff,
          distanceKm: distanceKm,
          customerService: _customerService,
          onVehicleSelected: (vehicleType, fare) {
            _onVehicleSelected(pickup, dropoff, distanceKm, vehicleType, fare);
          },
        ),
      ),
    );
  }

  // Step 2 Completed -> Open Step 3 (Receiver & Payment Review)
  void _onVehicleSelected(String pickup, String dropoff, double distanceKm, String vehicleType, double fare) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiverReviewScreen(
          pickupAddress: pickup,
          dropoffAddress: dropoff,
          vehicleType: vehicleType,
          distanceKm: distanceKm,
          fare: fare,
          customerService: _customerService,
          onOrderCreated: (createdOrder) {
            // Pop booking screens and enter Step 4 Live Tracking
            Navigator.popUntil(context, (route) => route.isFirst);
            setState(() {
              _activeDelivery = createdOrder;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If an order is currently active, show Live Tracking (Bottom nav hidden per Section 3.2)
    if (_activeDelivery != null) {
      return OrderTrackingScreen(
        order: _activeDelivery!,
        customerService: _customerService,
        onDismiss: () {
          setState(() {
            _activeDelivery = null;
          });
        },
      );
    }

    final screens = [
      CustomerHomeScreen(
        onStartBooking: () => _startBookingFlow(focusPickup: false),
        onSend: () => _startBookingFlow(focusPickup: true),
        onReceive: () => _startBookingFlow(focusPickup: false),
        activeOrder: _activeDelivery,
        onOpenTracking: () {
          if (_activeDelivery != null) {
            setState(() {});
          }
        },
      ),
      CustomerActivityScreen(
        customerService: _customerService,
        onSelectDelivery: (item) {
          setState(() {
            _activeDelivery = item;
          });
        },
      ),
      const CustomerAccountScreen(),
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
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.receipt_long_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.receipt_long),
              ),
              label: 'Activity',
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
