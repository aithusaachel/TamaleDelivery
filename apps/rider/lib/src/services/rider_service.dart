import 'package:supabase_flutter/supabase_flutter.dart';

class RiderService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  // 1. Fetch Rider Profile & Status
  Future<Map<String, dynamic>?> getRiderProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('riders')
        .select('*, profiles(full_name, phone, role)')
        .eq('profile_id', user.id)
        .maybeSingle();

    return response;
  }

  // 2. Online / Offline Toggle
  Future<bool> setOnlineStatus(bool online) async {
    final user = currentUser;
    if (user == null) return false;

    // Check credit limit and verification before going online
    if (online) {
      final rider = await getRiderProfile();
      if (rider == null || rider['verification'] != 'approved') {
        throw Exception('Your account is awaiting staff document approval.');
      }
      final double balance = (rider['wallet_balance'] as num).toDouble();
      if (balance < -20.0) {
        throw Exception('Wallet balance below -GH₵ 20.00. Please top up to go online.');
      }
    }

    await _client
        .from('riders')
        .update({'is_online': online, 'updated_at': DateTime.now().toIso8601String()})
        .eq('profile_id', user.id);

    return online;
  }

  // 3. Listen to incoming job offers (Using Realtime Stream)
  Stream<List<Map<String, dynamic>>> getIncomingOffersStream() {
    final user = currentUser;
    if (user == null) return const Stream.empty();

    return _client
        .from('rider_offers')
        .stream(primaryKey: ['offer_id'])
        .eq('rider_id', user.id);
  }

  // 4. Accept Job Offer (Atomic Stored Procedure)
  Future<void> acceptOffer(int offerId) async {
    await _client.rpc('accept_offer', params: {'p_offer': offerId});
  }

  // 5. Complete Delivery with 4-Digit Handover Code
  Future<Map<String, dynamic>> completeDelivery(String deliveryId, String code) async {
    final result = await _client.rpc('complete_delivery', params: {
      'p_delivery': deliveryId,
      'p_code': code,
    });
    return Map<String, dynamic>.from(result);
  }

  // 6. Submit Manual Top-up Request
  Future<void> submitTopupRequest(double amount, String momoReference) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('topup_requests').insert({
      'rider_id': user.id,
      'amount': amount,
      'momo_reference': momoReference,
      'status': 'pending',
    });
  }

  // 7. Fetch Recent Trips Ledger
  Future<List<Map<String, dynamic>>> getTripHistory() async {
    final user = currentUser;
    if (user == null) return [];

    final result = await _client
        .from('deliveries')
        .select('*')
        .eq('rider_id', user.id)
        .order('created_at', ascending: false)
        .limit(30);

    return List<Map<String, dynamic>>.from(result);
  }
}
