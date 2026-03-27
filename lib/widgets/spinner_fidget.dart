import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../constants.dart';
import '../models/fidget_definition.dart';

class SpinnerFidget extends StatefulWidget {
  final FidgetCallbacks callbacks;

  const SpinnerFidget({super.key, required this.callbacks});

  @override
  State<SpinnerFidget> createState() => _SpinnerFidgetState();
}

class _SpinnerFidgetState extends State<SpinnerFidget> {
  double _currentVelocity = 0;
  double _totalRotation = 0;
  int _spinStartTime = 0;
  Timer? _decayTimer;
  double _lastHapticPosition = 0;

  static const double _friction = kFriction;
  static const double _velocityThreshold = kVelocityThreshold;
  static const Duration _decayInterval = kDecayInterval;
  static const double _swipeMultiplier = kSwipeMultiplier;
  static const double _hapticTriggerThreshold = kHapticTriggerThreshold;

  void _triggerHaptic() {
    final intensity = widget.callbacks.hapticIntensity;
    if (intensity == 0) return;

    switch (intensity) {
      case 1:
        HapticFeedback.lightImpact();
        break;
      case 2:
        HapticFeedback.mediumImpact();
        break;
      case 3:
      default:
        HapticFeedback.heavyImpact();
        break;
    }
    widget.callbacks.onHapticPulse();
  }

  void _triggerLightHaptic() {
    final intensity = widget.callbacks.hapticIntensity;
    if (intensity == 0) return;

    if (intensity >= 2) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _startSpin(double velocity) {
    widget.callbacks.onInteractionStart();
    _spinStartTime = DateTime.now().millisecondsSinceEpoch;
    _currentVelocity = velocity;
    _decayTimer?.cancel();

    _triggerHaptic();

    _decayTimer = Timer.periodic(_decayInterval, (_) {
      if (_currentVelocity.abs() < _velocityThreshold) {
        _decayTimer?.cancel();
        int spinDuration = (DateTime.now().millisecondsSinceEpoch - _spinStartTime) ~/ 1000;
        widget.callbacks.onInteractionEnd(spinDuration);
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
            _triggerHaptic();
            _lastHapticPosition = normalizedRotation;
            break;
          }
        }

        if ((_totalRotation * 10).toInt() % 2 == 0 && 
            (_lastHapticPosition - normalizedRotation).abs() < 0.05) {
          if (_currentVelocity.abs() > 0.5) {
            _triggerLightHaptic();
          }
        }
      });
    });
  }

  void _stopSpin() {
    _decayTimer?.cancel();
    _currentVelocity = 0;
  }

  void _onPanEnd(DragEndDetails details) {
    double swipeVelocity = details.velocity.pixelsPerSecond.distance;
    // Apply sensitivity modifier
    double adjustedVelocity = swipeVelocity * _swipeMultiplier * widget.callbacks.sensitivity;
    double spinVelocity = adjustedVelocity.clamp(kMinVelocity, kMaxVelocity);
    
    _startSpin(spinVelocity);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: _onPanEnd,
      child: Transform.rotate(
        angle: _totalRotation * 2 * pi,
        child: CustomPaint(
          size: const Size(kSpinnerSize, kSpinnerSize),
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
      ..shader = const RadialGradient(
        colors: [kAccent, kAccentMuted],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, outerPaint);

    // Three bearing balls - white with subtle glow
    const ballRadius = kBallRadius;
    final ballDistance = radius - 20;
    
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * pi / 3);
      final ballX = center.dx + (ballDistance * cos(angle));
      final ballY = center.dy + (ballDistance * sin(angle));
      
      // Ball glow
      final glowPaint = Paint()
        ..color = kAccent.withValues(alpha: 0.3)
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

    canvas.drawCircle(center, kCenterBearingRadius, centerPaint);

    // Center circle rim - cyan
    final rimPaint = Paint()
      ..color = kAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, kCenterBearingRadius, rimPaint);
  }

  @override
  bool shouldRepaint(LuxeSpinnerPainter oldDelegate) => false;
}
