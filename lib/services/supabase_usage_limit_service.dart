import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class UsageLimitService {
  static final _client = Supabase.instance.client;
  static Future<int> getTodayUsageCount(String userId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await _client
        .from('usage_limits')
        .select('generate_count')
        .eq('user_id', userId)
        .eq('date', today)
        .maybeSingle();
    if (res == null) return 0;
    return res['generate_count'] ?? 0;
  }

  static Future<void> incrementUsage(String userId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final existing = await _client
        .from('usage_limits')
        .select('id, generate_count')
        .eq('user_id', userId)
        .eq('date', today)
        .maybeSingle();
    if (existing == null) {
      await _client.from('usage_limits').insert({
        'user_id': userId,
        'date': today,
        'generate_count': 1,
      });
    } else {
      await _client
          .from('usage_limits')
          .update({'generate_count': (existing['generate_count'] ?? 0) + 1})
          .eq('id', existing['id']);
    }
  }
}
