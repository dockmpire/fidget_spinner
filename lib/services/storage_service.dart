import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Stats
  static const String _totalSpinsKey = 'total_spins';
  static const String _totalHapticPulsesKey = 'total_haptic_pulses';
  static const String _longestSpinKey = 'longest_spin';

  // Settings
  static const String _hapticIntensityKey = 'haptic_intensity';
  static const String _sensitivityKey = 'sensitivity';
  static const String _soundEnabledKey = 'sound_enabled';

  // Stats getters/setters
  static int getTotalSpins() => _prefs?.getInt(_totalSpinsKey) ?? 0;
  static Future<void> setTotalSpins(int value) async {
    await _prefs?.setInt(_totalSpinsKey, value);
  }

  static int getTotalHapticPulses() => _prefs?.getInt(_totalHapticPulsesKey) ?? 0;
  static Future<void> setTotalHapticPulses(int value) async {
    await _prefs?.setInt(_totalHapticPulsesKey, value);
  }

  static int getLongestSpin() => _prefs?.getInt(_longestSpinKey) ?? 0;
  static Future<void> setLongestSpin(int value) async {
    await _prefs?.setInt(_longestSpinKey, value);
  }

  // Settings getters/setters
  // Haptic intensity: 0.0 (off) to 1.0 (full)
  static double getHapticIntensity() => _prefs?.getDouble(_hapticIntensityKey) ?? 0.8;
  static Future<void> setHapticIntensity(double value) async {
    await _prefs?.setDouble(_hapticIntensityKey, value);
  }

  // Sensitivity: 0.5 (low) to 2.0 (high)
  static double getSensitivity() => _prefs?.getDouble(_sensitivityKey) ?? 1.0;
  static Future<void> setSensitivity(double value) async {
    await _prefs?.setDouble(_sensitivityKey, value);
  }

  static bool getSoundEnabled() => _prefs?.getBool(_soundEnabledKey) ?? false;
  static Future<void> setSoundEnabled(bool value) async {
    await _prefs?.setBool(_soundEnabledKey, value);
  }
}
