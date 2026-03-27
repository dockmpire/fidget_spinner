import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/spinner_fidget.dart';
import '../widgets/stat_card.dart';
import 'settings_screen.dart';

class FidgetHomeScreen extends StatefulWidget {
  const FidgetHomeScreen({super.key});

  @override
  State<FidgetHomeScreen> createState() => _FidgetHomeScreenState();
}

class _FidgetHomeScreenState extends State<FidgetHomeScreen> {
  int _lastSpinTime = 0;
  int _totalSpins = 0;
  int _hapticPulses = 0;
  int _longestSpin = 0;
  double _sensitivity = 1.0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _totalSpins = StorageService.getTotalSpins();
      _hapticPulses = StorageService.getTotalHapticPulses();
      _longestSpin = StorageService.getLongestSpin();
      _sensitivity = StorageService.getSensitivity();
    });
  }

  Future<void> _onSpinEnd(int duration) async {
    // Update total spins
    int newTotalSpins = _totalSpins + 1;
    await StorageService.setTotalSpins(newTotalSpins);

    // Update longest spin
    int currentLongest = StorageService.getLongestSpin();
    if (duration > currentLongest) {
      await StorageService.setLongestSpin(duration);
    }

    setState(() {
      _lastSpinTime = duration;
      _totalSpins = newTotalSpins;
      if (duration > _longestSpin) {
        _longestSpin = duration;
      }
    });
  }

  Future<void> _onHapticPulse() async {
    int newTotal = _hapticPulses + 1;
    await StorageService.setTotalHapticPulses(newTotal);
    setState(() {
      _hapticPulses = newTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // Fidget display
                  Expanded(
                    child: Center(
                      child: SpinnerFidget(
                        sensitivity: _sensitivity,
                        onSpinStart: () {},
                        onSpinEnd: _onSpinEnd,
                        onHapticPulse: _onHapticPulse,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatCard(
                        label: 'Last Spin',
                        value: '$_lastSpinTime',
                        unit: 's',
                      ),
                      StatCard(
                        label: 'Total Spins',
                        value: '$_totalSpins',
                        unit: '',
                      ),
                      StatCard(
                        label: 'Haptics',
                        value: '$_hapticPulses',
                        unit: '',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Longest spin
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xFF00D4FF),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Best: ${_longestSpin}s',
                          style: const TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Settings button
            Positioned(
              top: 16,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Color(0xFF888888),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  _loadStats(); // Reload settings when returning
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
