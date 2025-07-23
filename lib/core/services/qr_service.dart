import 'package:supabase_flutter/supabase_flutter.dart';

class QRService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> scanQRCode({
    required String donationId,
    required String scanType, // 'pickup' or 'delivery'
    double? latitude,
    double? longitude,
  }) async {
    try {
      final result = await _supabase.rpc('scan_qr_code_enhanced', params: {
        'p_donation_id': donationId,
        'p_scan_type': scanType,
        'p_location_lat': latitude,
        'p_location_lng': longitude,
      }).select();

      return result.first as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getDonationTrackingHistory(
      String donationId) async {
    try {
      final result = await _supabase.rpc('get_donation_tracking_history',
          params: {'p_donation_id': donationId}).select();

      return result.first as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> getVolunteerQRHistory(
      String volunteerId) async {
    try {
      final result = await _supabase.rpc('get_volunteer_qr_scan_history',
          params: {'p_volunteer_id': volunteerId}).select();

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }
}
