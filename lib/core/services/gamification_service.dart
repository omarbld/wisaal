import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getGamificationData(
      String userId) async {
    try {
      final result = await _supabase
          .rpc('get_gamification_data', params: {'p_user_id': userId}).select();

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error fetching gamification data: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final result = await _supabase
          .rpc('get_user_badges', params: {'p_user_id': userId}).select();

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error fetching user badges: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getLeaderboard({
    String? role,
    int limit = 10,
  }) async {
    try {
      final result = await _supabase.rpc('get_leaderboard_enhanced', params: {
        'p_role': role,
        'p_limit': limit,
      }).select();

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserRanking(String userId) async {
    try {
      final result = await _supabase
          .rpc('get_user_ranking', params: {'p_user_id': userId}).select();

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error fetching user ranking: $e');
      return null;
    }
  }

  static Future<bool> awardPoints({
    required String userId,
    required int points,
    required String reason,
    String? donationId,
  }) async {
    try {
      await _supabase.rpc('award_points_enhanced', params: {
        'p_user_id': userId,
        'p_points': points,
        'p_reason': reason,
        'p_donation_id': donationId,
      });

      return true;
    } catch (e) {
      print('Error awarding points: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getPointsHistory(
      String userId) async {
    try {
      final result = await _supabase
          .rpc('get_points_history', params: {'p_user_id': userId}).select();

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error fetching points history: $e');
      return [];
    }
  }
}
