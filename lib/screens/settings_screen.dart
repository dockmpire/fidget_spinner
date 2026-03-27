import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _hapticIntensity;
  late double _sensitivity;
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _hapticIntensity = StorageService.getHapticIntensity();
    _sensitivity = StorageService.getSensitivity();
    _soundEnabled = StorageService.getSoundEnabled();
  }

  Future<void> _saveSettings() async {
    await StorageService.setHapticIntensity(_hapticIntensity);
    await StorageService.setSensitivity(_sensitivity);
    await StorageService.setSoundEnabled(_soundEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Haptic Intensity
            _SettingCard(
              title: 'Haptic Intensity',
              subtitle: 'Strength of vibration feedback',
              child: Column(
                children: [
                  Slider(
                    value: _hapticIntensity,
                    min: 0.0,
                    max: 1.0,
                    activeColor: const Color(0xFF00D4FF),
                    inactiveColor: const Color(0xFF333333),
                    onChanged: (value) {
                      setState(() => _hapticIntensity = value);
                    },
                    onChangeEnd: (value) => _saveSettings(),
                  ),
                  Text(
                    '${(_hapticIntensity * 100).toInt()}%',
                    style: const TextStyle(color: Color(0xFF00D4FF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sensitivity
            _SettingCard(
              title: 'Spin Sensitivity',
              subtitle: 'How fast the spinner responds to swipe',
              child: Column(
                children: [
                  Slider(
                    value: _sensitivity,
                    min: 0.5,
                    max: 2.0,
                    activeColor: const Color(0xFF00D4FF),
                    inactiveColor: const Color(0xFF333333),
                    onChanged: (value) {
                      setState(() => _sensitivity = value);
                    },
                    onChangeEnd: (value) => _saveSettings(),
                  ),
                  Text(
                    _sensitivity < 1.0 ? 'Light' : (_sensitivity > 1.0 ? 'Strong' : 'Normal'),
                    style: const TextStyle(color: Color(0xFF00D4FF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sound
            _SettingCard(
              title: 'Sound Effects',
              subtitle: 'Play sounds during spin',
              child: Switch(
                value: _soundEnabled,
                activeTrackColor: const Color(0xFF00D4FF),
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  _saveSettings();
                },
              ),
            ),
            const SizedBox(height: 32),

            // Reset Stats button
            Center(
              child: TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await StorageService.setTotalSpins(0);
                  await StorageService.setTotalHapticPulses(0);
                  await StorageService.setLongestSpin(0);
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Statistics reset'),
                        backgroundColor: Color(0xFF1A1A1A),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Reset Statistics',
                  style: TextStyle(color: Color(0xFFFF4444)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
