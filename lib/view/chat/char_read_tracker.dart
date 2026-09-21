// ============================================================
// CHAT READ TRACKER
// ============================================================
// Local-only record of when the user last opened a chat.
// Used by the inbox to decide whether a conversation has
// unread messages.
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

class ChatReadTracker {
  static const String _prefix = 'chat_read_at_';

  /// Returns the last time this user opened the chat for [orderId],
  /// or null if they never have.
  static Future<DateTime?> lastReadAt(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString('$_prefix$orderId');
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  /// Marks the chat for [orderId] as read as of right now.
  static Future<void> markReadNow(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$orderId',
      DateTime.now().toIso8601String(),
    );
  }

  /// Clears the read marker for a single order (optional helper).
  static Future<void> clear(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$orderId');
  }

  /// Clears all read markers (optional — useful on logout).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}