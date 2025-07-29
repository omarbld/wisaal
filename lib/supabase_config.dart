import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static Future<void> init() async {
    try {
      await dotenv.load();
      
      // Validate required environment variables
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      
      if (url == null || url.isEmpty) {
        throw Exception('SUPABASE_URL is not set in environment variables');
      }
      
      if (anonKey == null || anonKey.isEmpty) {
        throw Exception('SUPABASE_ANON_KEY is not set in environment variables');
      }
      
      // Additional security checks
      if (!url.startsWith('https://')) {
        throw Exception('SUPABASE_URL must use HTTPS');
      }
      
      if (anonKey.length < 100) {
        throw Exception('SUPABASE_ANON_KEY appears to be invalid (too short)');
      }
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // More secure auth flow
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: kDebugMode ? RealtimeLogLevel.info : RealtimeLogLevel.error,
        ),
      );
      
      if (kDebugMode) {
        print('✅ Supabase initialized successfully');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Supabase: $e');
      }
      rethrow;
    }
  }
  
  // Security helper methods
  static bool get isInitialized => Supabase.instance.client.auth.currentUser != null;
  
  static String get currentUserId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    return user.id;
  }
  
  static Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to sign out: $e');
      }
      rethrow;
    }
  }
}
