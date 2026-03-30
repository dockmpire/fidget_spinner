import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/fidget_definition.dart';
import '../models/fidget_registry.dart';
import '../services/storage_service.dart';
import '../widgets/corner_menu.dart';
import '../widgets/fidget_toolbox.dart';
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
  int _hapticIntensity = 3;
  int _activeFidgetIndex = 0;
  bool _toolboxOpen = false;
  bool _menuOpen = false;

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
      _hapticIntensity = StorageService.getHapticIntensity();
    });
  }

  Future<void> _onSpinEnd(int duration) async {
    final newTotalSpins = _totalSpins + 1;
    final newLongest = duration > _longestSpin ? duration : _longestSpin;

    await StorageService.setTotalSpins(newTotalSpins);
    if (duration > _longestSpin) {
      await StorageService.setLongestSpin(duration);
    }

    setState(() {
      _lastSpinTime = duration;
      _totalSpins = newTotalSpins;
      _longestSpin = newLongest;
    });
  }

  Future<void> _onHapticPulse() async {
    final newTotal = _hapticPulses + 1;
    await StorageService.setTotalHapticPulses(newTotal);
    setState(() {
      _hapticPulses = newTotal;
    });
  }

  void _openToolbox() => setState(() => _toolboxOpen = true);
  void _closeToolbox() => setState(() => _toolboxOpen = false);

  void _openMenu() => setState(() => _menuOpen = true);
  void _closeMenu() => setState(() => _menuOpen = false);

  void _selectFidget(int index) {
    setState(() {
      _activeFidgetIndex = index;
      _toolboxOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // Top tab switcher
                  const SizedBox(height: 44),
                  _FidgetTabBar(
                    selectedIndex: _activeFidgetIndex,
                    onSelect: (i) => setState(() => _activeFidgetIndex = i),
                  ),
                  const SizedBox(height: 12),

                  // Fidget display — long press to open toolbox
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ambient glow behind spinner
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                kAccent.withValues(alpha: 0.08),
                                kAccent.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),

                        // Spinner
                        GestureDetector(
                          onLongPress: _openToolbox,
                          child: FidgetRegistry.all[_activeFidgetIndex].builder(
                            FidgetCallbacks(
                              onInteractionStart: () {},
                              onInteractionEnd: _onSpinEnd,
                              onHapticPulse: _onHapticPulse,
                              sensitivity: _sensitivity,
                              hapticIntensity: _hapticIntensity,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      color: kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kAccent.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events, color: kAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Best: ${_longestSpin}s',
                          style: const TextStyle(
                            color: kAccent,
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

            // Corner menu icon — top left
            Positioned(
              top: 16,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.menu, color: kTextMuted),
                onPressed: _openMenu,
              ),
            ),

            // Settings button — top right
            Positioned(
              top: 16,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.settings, color: kTextMuted),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  _loadStats();
                },
              ),
            ),

            // Fidget toolbox overlay
            if (_toolboxOpen)
              FidgetToolbox(
                activeFidgetIndex: _activeFidgetIndex,
                onSelect: _selectFidget,
                onDismiss: _closeToolbox,
              ),

            // Corner menu overlay
            if (_menuOpen)
              CornerMenu(onDismiss: _closeMenu),
          ],
        ),
      ),
    );
  }
}

/// Top tab bar for switching between fidget toys.
class _FidgetTabBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const _FidgetTabBar({required this.selectedIndex, required this.onSelect});

  static const _activeColor = Color(0xFF7057C0);

  @override
  Widget build(BuildContext context) {
    final fidgets = FidgetRegistry.all;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(fidgets.length, (i) {
          final isActive = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: isActive
                    ? BoxDecoration(
                        color: _activeColor,
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                child: Text(
                  fidgets[i].name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.white : kTextMuted,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Shows the active fidget name with a subtle long-press hint below it.
class _FidgetLabel extends StatelessWidget {
  final String name;
  const _FidgetLabel({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          Text(
            name.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kAccent.withValues(alpha: 0.7),
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                size: 11,
                color: kTextMuted.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 4),
              Text(
                'Hold to switch',
                style: TextStyle(
                  fontSize: 10,
                  color: kTextMuted.withValues(alpha: 0.35),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
