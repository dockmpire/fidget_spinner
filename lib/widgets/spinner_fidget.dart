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
        final spinDuration =
            (DateTime.now().millisecondsSinceEpoch - _spinStartTime) ~/ 1000;
        widget.callbacks.onInteractionEnd(spinDuration);
        _stopSpin();
        return;
      }

      setState(() {
        _currentVelocity *= _friction;
        _totalRotation += _currentVelocity * 0.01;

        final normalizedRotation = _totalRotation % 1.0;
        const bearingPositions = [0.0, 1 / 3, 2 / 3];

        for (final bearingPos in bearingPositions) {
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
    final swipeVelocity = details.velocity.pixelsPerSecond.distance;
    final adjustedVelocity =
        swipeVelocity * _swipeMultiplier * widget.callbacks.sensitivity;
    final spinVelocity = adjustedVelocity.clamp(kMinVelocity, kMaxVelocity);
    _startSpin(spinVelocity);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight) * 0.82;
        return GestureDetector(
          onPanEnd: _onPanEnd,
          child: Transform.rotate(
            angle: _totalRotation * 2 * pi,
            child: CustomPaint(
              size: Size(size, size),
              painter: LuxeSpinnerPainter(),
            ),
          ),
        );
      },
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
    final r = min(size.width, size.height) / 2;

    // Dimensions derived from radius
    final tipR = r * 0.20;       // outer bearing radius
    final hubR = r * 0.16;       // center hub radius
    final armW = r * 0.26;       // arm thickness
    final armStart = hubR * 0.5; // arm starts inside hub (overlap)
    final armEnd = r - tipR * 1.4; // arm ends before bearing center

    // ── Arms ────────────────────────────────────────────────────────────────
    for (int i = 0; i < 3; i++) {
      final angle = i * 2 * pi / 3;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final armRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(armStart, -armW / 2, armEnd - armStart, armW),
        Radius.circular(armW / 2),
      );

      // Arm gradient (along the arm axis)
      final armPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            kAccent.withValues(alpha: 0.9),
            kAccentMuted,
          ],
        ).createShader(Rect.fromLTWH(armStart, -armW / 2, armEnd, armW));

      canvas.drawRRect(armRect, armPaint);
      canvas.restore();
    }

    // ── Tip bearings ─────────────────────────────────────────────────────────
    for (int i = 0; i < 3; i++) {
      final angle = i * 2 * pi / 3;
      final tip = Offset(
        center.dx + (r - tipR) * cos(angle),
        center.dy + (r - tipR) * sin(angle),
      );

      // Glow
      canvas.drawCircle(
        tip,
        tipR + 8,
        Paint()
          ..color = kAccent.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Ball base
      canvas.drawCircle(tip, tipR, Paint()..color = Colors.white);

      // Ball sheen (subtle gradient overlay)
      canvas.drawCircle(
        tip,
        tipR,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.9,
            colors: [
              Colors.white,
              const Color(0xFFB8EEFF),
            ],
          ).createShader(Rect.fromCircle(center: tip, radius: tipR)),
      );

      // Specular highlight
      canvas.drawCircle(
        Offset(tip.dx - tipR * 0.28, tip.dy - tipR * 0.28),
        tipR * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.75),
      );
    }

    // ── Center hub ────────────────────────────────────────────────────────────

    // Hub glow
    canvas.drawCircle(
      center,
      hubR + 10,
      Paint()
        ..color = kAccent.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Hub base
    canvas.drawCircle(
      center,
      hubR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: [Colors.white, const Color(0xFFCCF5FF)],
        ).createShader(Rect.fromCircle(center: center, radius: hubR)),
    );

    // Hub rim
    canvas.drawCircle(
      center,
      hubR,
      Paint()
        ..color = kAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Hub centre dot
    canvas.drawCircle(center, hubR * 0.28, Paint()..color = kAccent);
  }

  @override
  bool shouldRepaint(LuxeSpinnerPainter oldDelegate) => false;
}
