import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking the main flow
      print('Error sending notification: $e');
    }
  }

  static Future<void> sendBulkNotification({
    required String title,
    required String body,
    String? role,
    List<String>? userIds,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.rpc('send_bulk_notification', params: {
        'p_title': title,
        'p_body': body,
        'p_role': role,
      });
    } catch (e) {
      print('Error sending bulk notification: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('notifications')
          .select()
          .or('user_id.eq.${user.id},user_id.is.null')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id', const FetchOptions(count: CountOption.exact))
          .or('user_id.eq.${user.id},user_id.is.null')
          .eq('is_read', false);

      return response.count ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  static Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  static Future<void> deleteNotification(int notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Predefined notification templates
  static Future<void> notifyDonationAccepted({
    required String donorId,
    required String donationTitle,
    required String associationName,
  }) async {
    await sendNotification(
      userId: donorId,
      title: 'تم قبول تبرعك',
      body: 'تم قبول تبرعك "$donationTitle" من قبل $associationName',
    );
  }

  static Future<void> notifyDonationCancelled({
    required String donorId,
    required String donationTitle,
    String? reason,
  }) async {
    await sendNotification(
      userId: donorId,
      title: 'تم إلغاء التبرع',
      body: 'تم إلغاء تبرعك "$donationTitle"${reason != null ? ': $reason' : ''}',
    );
  }

  static Future<void> notifyTaskAssigned({
    required String volunteerId,
    required String donationTitle,
    required String pickupAddress,
  }) async {
    await sendNotification(
      userId: volunteerId,
      title: 'مهمة جديدة',
      body: 'تم تعيينك لاستلام تبرع "$donationTitle" من $pickupAddress',
    );
  }

  static Future<void> notifyDonationCompleted({
    required String associationId,
    required String donationTitle,
    required String volunteerName,
  }) async {
    await sendNotification(
      userId: associationId,
      title: 'تم استلام التبرع',
      body: 'تم استلام تبرع "$donationTitle" بواسطة المتطوع $volunteerName',
    );
  }

  static Future<void> notifyVolunteerRated({
    required String volunteerId,
    required int rating,
    required String raterName,
  }) async {
    await sendNotification(
      userId: volunteerId,
      title: 'تقييم جديد',
      body: 'تم تقييمك بـ $rating نجوم من قبل $raterName',
    );
  }

  static Future<void> notifyUrgentDonation({
    required String donationTitle,
    required String city,
  }) async {
    await sendBulkNotification(
      title: 'تبرع عاجل',
      body: 'تبرع عاجل متاح في $city: $donationTitle',
      role: 'association',
    );
  }
}