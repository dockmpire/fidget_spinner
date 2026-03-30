import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/fidget_definition.dart';

class StressBallFidget extends StatefulWidget {
  final FidgetCallbacks callbacks;
  const StressBallFidget({super.key, required this.callbacks});

  @override
  State<StressBallFidget> createState() => _StressBallFidgetState();
}

class _StressBallFidgetState extends State<StressBallFidget>
    with SingleTickerProviderStateMixin {
  static const _maxStretch = 0.42;
  static const _minScale = 0.65;

  double _scaleX = 1.0;
  double _scaleY = 1.0;
  Offset _driftOffset = Offset.zero;

  double _releaseScaleX = 1.0;
  double _releaseScaleY = 1.0;
  Offset _releaseDrift = Offset.zero;

  late AnimationController _releaseCtrl;
  late Animation<double> _releaseAnim;

  bool _isTouching = false;
  Offset _dragStart = Offset.zero;
  int _touchStartMs = 0;

  double _lastHapticScaleX = 1.0;
  double _lastHapticScaleY = 1.0;

  @override
  void initState() {
    super.initState();
    _releaseCtrl = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    );
    _releaseAnim = CurvedAnimation(
      parent: _releaseCtrl,
      curve: Curves.elasticOut,
    );
    _releaseCtrl.addListener(_onReleaseAnim);
  }

  void _onReleaseAnim() {
    final t = _releaseAnim.value;
    setState(() {
      _scaleX = _lerp(_releaseScaleX, 1.0, t);
      _scaleY = _lerp(_releaseScaleY, 1.0, t);
      _driftOffset =
          Offset.lerp(_releaseDrift, Offset.zero, t.clamp(0.0, 1.0))!;
    });
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _onPanStart(DragStartDetails details) {
    _releaseCtrl.stop();
    _isTouching = true;
    _dragStart = details.localPosition;
    _touchStartMs = DateTime.now().millisecondsSinceEpoch;
    widget.callbacks.onInteractionStart();
    _lastHapticScaleX = 1.0;
    _lastHapticScaleY = 1.0;
    _triggerHaptic(light: true);
  }

  void _onPanUpdate(DragUpdateDetails details, double ballRadius) {
    if (!_isTouching) return;

    final delta = details.localPosition - _dragStart;
    final dist = delta.distance;
    final t = (dist / (ballRadius * 1.1)).clamp(0.0, 1.0);
    final angle = atan2(delta.dy, delta.dx);

    final cosA = cos(angle).abs();
    final sinA = sin(angle).abs();

    final newScaleX =
        (1.0 + _maxStretch * t * cosA - _maxStretch * 0.5 * t * sinA)
            .clamp(_minScale, 1.0 + _maxStretch);
    final newScaleY =
        (1.0 + _maxStretch * t * sinA - _maxStretch * 0.5 * t * cosA)
            .clamp(_minScale, 1.0 + _maxStretch);

    final driftMag = (dist * 0.16).clamp(0.0, ballRadius * 0.2);
    final newDrift =
        Offset(cos(angle) * driftMag, sin(angle) * driftMag);

    setState(() {
      _scaleX = newScaleX;
      _scaleY = newScaleY;
      _driftOffset = newDrift;
    });

    if ((_scaleX - _lastHapticScaleX).abs() > 0.07 ||
        (_scaleY - _lastHapticScaleY).abs() > 0.07) {
      _triggerHaptic(light: false);
      _lastHapticScaleX = _scaleX;
      _lastHapticScaleY = _scaleY;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isTouching) return;
    _isTouching = false;

    _releaseScaleX = _scaleX;
    _releaseScaleY = _scaleY;
    _releaseDrift = _driftOffset;

    _releaseCtrl.reset();
    _releaseCtrl.forward();
    _triggerHaptic(light: true);

    final dur = max(
        1, (DateTime.now().millisecondsSinceEpoch - _touchStartMs) ~/ 1000);
    widget.callbacks.onInteractionEnd(dur);
    _lastHapticScaleX = 1.0;
    _lastHapticScaleY = 1.0;
  }

  void _triggerHaptic({bool light = false}) {
    final intensity = widget.callbacks.hapticIntensity;
    if (intensity == 0) return;
    if (light || intensity == 1) {
      HapticFeedback.lightImpact();
    } else if (intensity == 2) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    widget.callbacks.onHapticPulse();
  }

  @override
  void dispose() {
    _releaseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = min(constraints.maxWidth, constraints.maxHeight) * 0.78;
      final ballRadius = size / 2;

      return GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: (d) => _onPanUpdate(d, ballRadius),
        onPanEnd: _onPanEnd,
        child: SizedBox(
          width: size,
          height: size,
          child: Transform.translate(
            offset: _driftOffset,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(_scaleX, _scaleY, 1.0),
              child: CustomPaint(
                size: Size(size, size),
                painter: const _StressBallPainter(),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _StressBallPainter extends CustomPainter {
  const _StressBallPainter();

  static const _outerColor = Color(0xFF4DD0E1); // bright teal
  static const _innerColor = Color(0xFF00838F); // dark teal

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2;
    final innerR = r * 0.62;

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, r * 0.88),
        width: r * 1.4,
        height: r * 0.22,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.14),
    );

    // Ball drop shadow
    canvas.drawCircle(
      center + Offset(r * 0.04, r * 0.07),
      r * 0.97,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );

    // Outer ring — bright teal base
    canvas.drawCircle(center, r, Paint()..color = _outerColor);

    // Outer ring — upper-left sheen
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.55),
          radius: 0.78,
          colors: [
            Colors.white.withValues(alpha: 0.45),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Outer ring — bottom darkening for depth
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.25, 0.5),
          radius: 0.8,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.22),
          ],
          stops: const [0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Inner circle — dark teal
    canvas.drawCircle(center, innerR, Paint()..color = _innerColor);

    // Inner circle — subtle gradient
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          radius: 0.88,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: innerR)),
    );

    // Inner circle — edge darkening
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.28),
          ],
          stops: const [0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: innerR)),
    );

    // Outer ring specular — large soft blob
    canvas.drawCircle(
      center + Offset(-r * 0.30, -r * 0.50),
      r * 0.20,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // Outer ring specular — bright glint
    canvas.drawCircle(
      center + Offset(-r * 0.22, -r * 0.57),
      r * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.90),
    );
  }

  @override
  bool shouldRepaint(_StressBallPainter old) => false;
}
