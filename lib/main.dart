import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math';

void main() {
  runApp(const FormFreshFidgetApp());
}

class FormFreshFidgetApp extends StatelessWidget {
  const FormFreshFidgetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FormFresh Fidgets',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4FF), // Cyan accent
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Pure black
      ),
      home: const FidgetHomeScreen(),
    );
  }
}

class FidgetHomeScreen extends StatefulWidget {
  const FidgetHomeScreen({Key? key}) : super(key: key);

  @override
  State<FidgetHomeScreen> createState() => _FidgetHomeScreenState();
}

class _FidgetHomeScreenState extends State<FidgetHomeScreen> {
  int _spinTime = 0;
  int _totalSpins = 0;
  int _hapticPulses = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {});
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Fidget display - pure black background
              Expanded(
                child: Center(
                  child: SpinnerFidget(
                    onSpinStart: () {
                      setState(() {
                        _spinTime = 0;
                        _hapticPulses = 0;
                      });
                    },
                    onSpinEnd: (duration) {
                      setState(() {
                        _spinTime = duration;
                        _totalSpins++;
                      });
                    },
                    onHapticPulse: () {
                      setState(() => _hapticPulses++);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats display - three cards at bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatCard(
                    label: 'Last Spin',
                    value: '$_spinTime',
                    unit: 's',
                  ),
                  _StatCard(
                    label: 'Total Spins',
                    value: '$_totalSpins',
                    unit: '',
                  ),
                  _StatCard(
                    label: 'Haptic Pulses',
                    value: '$_hapticPulses',
                    unit: '',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF00D4FF),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SpinnerFidget extends StatefulWidget {
  final VoidCallback onSpinStart;
  final Function(int) onSpinEnd;
  final VoidCallback onHapticPulse;

  const SpinnerFidget({
    Key? key,
    required this.onSpinStart,
    required this.onSpinEnd,
    required this.onHapticPulse,
  }) : super(key: key);

  @override
  State<SpinnerFidget> createState() => _SpinnerFidgetState();
}

class _SpinnerFidgetState extends State<SpinnerFidget> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _currentVelocity = 0;
  double _totalRotation = 0;
  int _spinStartTime = 0;
  Timer? _decayTimer;
  Offset _lastDragPosition = Offset.zero;
  double _lastHapticPosition = 0; // Track last haptic trigger to avoid duplicates

  static const double _friction = 0.95;
  static const double _velocityThreshold = 0.01;
  static const Duration _decayInterval = Duration(milliseconds: 50);
  static const double _swipeMultiplier = 0.01;
  
  // Haptic zones based on bearing ball positions (0°, 120°, 240°)
  static const double _hapticTriggerThreshold = 0.05; // Radians to trigger haptic

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this);
  }

  void _startSpin(double velocity) {
    widget.onSpinStart();
    _spinStartTime = DateTime.now().millisecondsSinceEpoch;
    _currentVelocity = velocity;
    _decayTimer?.cancel();

    HapticFeedback.heavyImpact();

    _decayTimer = Timer.periodic(_decayInterval, (_) {
      if (_currentVelocity.abs() < _velocityThreshold) {
        _decayTimer?.cancel();
        int spinDuration = (DateTime.now().millisecondsSinceEpoch - _spinStartTime) ~/ 1000;
        widget.onSpinEnd(spinDuration);
        _stopSpin();
        return;
      }

      setState(() {
        _currentVelocity *= _friction;
        _totalRotation += _currentVelocity * 0.01;

        // Calculate bearing ball positions (3 balls at 120° intervals)
        // Normalize rotation to 0-1 range (one full spin)
        double normalizedRotation = _totalRotation % 1.0;
        
        // Three bearing positions at 0°, 120°, 240°
        List<double> bearingPositions = [0.0, 1/3, 2/3];
        
        for (double bearingPos in bearingPositions) {
          // Check if we're near this bearing (strong haptic zone)
          double distance = (normalizedRotation - bearingPos).abs();
          // Handle wraparound
          if (distance > 0.5) distance = 1.0 - distance;
          
          // Strong haptic when bearing is at top (near 0° of rotation)
          if (distance < _hapticTriggerThreshold && 
              (_lastHapticPosition - normalizedRotation).abs() > 0.1) {
            // Strong pulse for bearing impact
            HapticFeedback.heavyImpact();
            widget.onHapticPulse();
            _lastHapticPosition = normalizedRotation;
            break;
          }
        }
        
        // Light haptic for general rotation feel (between bearings)
        if ((_totalRotation * 10).toInt() % 2 == 0 && 
            (_lastHapticPosition - normalizedRotation).abs() < 0.05) {
          // Softer pulse for continuous rotation sensation
          if (_currentVelocity.abs() > 0.5) { // Only when spinning fast enough
            HapticFeedback.selectionClick(); // Lighter haptic
          }
        }
      });
    });
  }

  void _stopSpin() {
    _decayTimer?.cancel();
    _currentVelocity = 0;
  }

  void _onPanStart(DragStartDetails details) {
    _lastDragPosition = details.globalPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    Offset delta = details.globalPosition - _lastDragPosition;
    _lastDragPosition = details.globalPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    double swipeVelocity = details.velocity.pixelsPerSecond.distance;
    double spinVelocity = (swipeVelocity * _swipeMultiplier).clamp(0.5, 15.0);
    
    _startSpin(spinVelocity);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.rotate(
        angle: _totalRotation * 2 * pi,
        child: CustomPaint(
          size: const Size(180, 180),
          painter: LuxeSpinnerPainter(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }
}

// Luxe spinner graphics - cyan accent
class LuxeSpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circle gradient - cyan accent
    final outerPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          const Color(0xFF00D4FF),
          const Color(0xFF0099CC),
        ],
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, outerPaint);

    // Three bearing balls - white with subtle glow
    final ballRadius = 12.0;
    final ballDistance = radius - 20;
    
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * pi / 3);
      final ballX = center.dx + (ballDistance * cos(angle));
      final ballY = center.dy + (ballDistance * sin(angle));
      
      // Ball glow
      final glowPaint = Paint()
        ..color = const Color(0xFF00D4FF).withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(ballX, ballY), ballRadius + 4, glowPaint);
      
      // Ball itself
      final ballPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(ballX, ballY), ballRadius, ballPaint);
    }

    // Center bearing
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 15, centerPaint);

    // Center circle rim - cyan
    final rimPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 15, rimPaint);
  }

  @override
  bool shouldRepaint(LuxeSpinnerPainter oldDelegate) => false;
}
