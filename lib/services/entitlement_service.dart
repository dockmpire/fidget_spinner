import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which premium fidgets the user has unlocked.
/// Wraps SharedPreferences so entitlements survive app restarts.
class EntitlementService {
  static SharedPreferences? _prefs;
  static const String _keyPrefix = 'entitlement_';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns true if the fidget with [fidgetId] is unlocked.
  static bool isUnlocked(String fidgetId) {
    return _prefs?.getBool('$_keyPrefix$fidgetId') ?? false;
  }

  /// Marks [fidgetId] as unlocked. Called after a successful purchase or restore.
  static Future<void> unlock(String fidgetId) async {
    await _prefs?.setBool('$_keyPrefix$fidgetId', true);
  }

  /// Unlocks all fidgets in [fidgetIds]. Used during purchase restore.
  static Future<void> unlockAll(List<String> fidgetIds) async {
    for (final id in fidgetIds) {
      await unlock(id);
    }
  }

  /// Returns the list of all currently unlocked fidget IDs.
  static List<String> getUnlocked() {
    final keys = _prefs?.getKeys() ?? {};
    return keys
        .where((k) => k.startsWith(_keyPrefix) && (_prefs?.getBool(k) ?? false))
        .map((k) => k.replaceFirst(_keyPrefix, ''))
        .toList();
  }
}
