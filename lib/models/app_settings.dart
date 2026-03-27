class AppSettings {
  final double hapticIntensity; // 0.0 to 1.0
  final double sensitivity;    // 0.5 to 2.0
  final bool soundEnabled;

  const AppSettings({
    this.hapticIntensity = 0.8,
    this.sensitivity = 1.0,
    this.soundEnabled = false,
  });

  AppSettings copyWith({
    double? hapticIntensity,
    double? sensitivity,
    bool? soundEnabled,
  }) {
    return AppSettings(
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      sensitivity: sensitivity ?? this.sensitivity,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}
