import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

class SpinnerFidget extends StatefulWidget {
  final VoidCallback onSpinStart;
  final Function(int) onSpinEnd;
  final VoidCallback onHapticPulse;
  final double sensitivity;

  const SpinnerFidget({
    super.key,
    required this.onSpinStart,
    required this.onSpinEnd,
    required this.onHapticPulse,
    this.sensitivity = 1.0,
  });

  @override
  State<SpinnerFidget> createState() => _SpinnerFidgetState();
}

class _SpinnerFidgetState extends State<SpinnerFidget> {
  double _currentVelocity = 0;
  double _totalRotation = 0;
  int _spinStartTime = 0;
  Timer? _decayTimer;
  double _lastHapticPosition = 0;

  static const double _friction = 0.95;
  static const double _velocityThreshold = 0.01;
  static const Duration _decayInterval = Duration(milliseconds: 50);
  static const double _swipeMultiplier = 0.01;
  static const double _hapticTriggerThreshold = 0.05;

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

        double normalizedRotation = _totalRotation % 1.0;
        List<double> bearingPositions = [0.0, 1/3, 2/3];

        for (double bearingPos in bearingPositions) {
          double distance = (normalizedRotation - bearingPos).abs();
          if (distance > 0.5) distance = 1.0 - distance;

          if (distance < _hapticTriggerThreshold && 
              (_lastHapticPosition - normalizedRotation).abs() > 0.1) {
            HapticFeedback.heavyImpact();
            widget.onHapticPulse();
            _lastHapticPosition = normalizedRotation;
            break;
          }
        }

        if ((_totalRotation * 10).toInt() % 2 == 0 && 
            (_lastHapticPosition - normalizedRotation).abs() < 0.05) {
          if (_currentVelocity.abs() > 0.5) {
            HapticFeedback.selectionClick();
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
    // Track initial position if needed for future enhancements
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Track movement if needed for future enhancements
  }

  void _onPanEnd(DragEndDetails details) {
    double swipeVelocity = details.velocity.pixelsPerSecond.distance;
    // Apply sensitivity modifier
    double adjustedVelocity = swipeVelocity * _swipeMultiplier * widget.sensitivity;
    double spinVelocity = adjustedVelocity.clamp(0.5, 15.0);
    
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
    super.dispose();
  }
}

class LuxeSpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circle gradient - cyan accent
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00D4FF),
          const Color(0xFF0099CC),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
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
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)
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
