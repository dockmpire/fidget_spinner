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
  static const _ballColor = Color(0xFF7ED348);
  static const _maxStretch = 0.46;
  static const _minScale = 0.62;

  double _scaleX = 1.0;
  double _scaleY = 1.0;
  Offset _driftOffset = Offset.zero;

  // Values at the moment the finger lifts (used by release animation)
  double _releaseScaleX = 1.0;
  double _releaseScaleY = 1.0;
  Offset _releaseDrift = Offset.zero;

  late AnimationController _releaseCtrl;
  late Animation<double> _releaseAnim;

  bool _isTouching = false;
  Offset _dragStart = Offset.zero;
  int _touchStartMs = 0;

  // Haptic gating
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
      _driftOffset = Offset.lerp(_releaseDrift, Offset.zero, t.clamp(0.0, 1.0))!;
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

    // Normalise against ball radius so the feel is size-independent
    final t = (dist / (ballRadius * 1.2)).clamp(0.0, 1.0);
    final angle = atan2(delta.dy, delta.dx);

    final cosA = cos(angle).abs();
    final sinA = sin(angle).abs();

    // Primary axis stretches; perpendicular axis squishes (volume conservation feel)
    final newScaleX = (1.0 + _maxStretch * t * cosA - _maxStretch * 0.55 * t * sinA)
        .clamp(_minScale, 1.0 + _maxStretch);
    final newScaleY = (1.0 + _maxStretch * t * sinA - _maxStretch * 0.55 * t * cosA)
        .clamp(_minScale, 1.0 + _maxStretch);

    // Slight drift in the drag direction so the ball "follows" the finger
    final driftMag = (dist * 0.18).clamp(0.0, ballRadius * 0.22);
    final newDrift = Offset(cos(angle) * driftMag, sin(angle) * driftMag);

    setState(() {
      _scaleX = newScaleX;
      _scaleY = newScaleY;
      _driftOffset = newDrift;
    });

    // Haptic when deformation crosses a meaningful threshold
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

    final dur = max(1, (DateTime.now().millisecondsSinceEpoch - _touchStartMs) ~/ 1000);
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
      final size = min(constraints.maxWidth, constraints.maxHeight) * 0.72;
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
                painter: _StressBallPainter(color: _ballColor),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _StressBallPainter extends CustomPainter {
  final Color color;
  const _StressBallPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2;

    // Ambient shadow underneath
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, r * 0.82),
        width: r * 1.5,
        height: r * 0.28,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
    );

    // Drop shadow on ball
    canvas.drawCircle(
      center + Offset(r * 0.05, r * 0.08),
      r * 0.96,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.14),
    );

    // Base ball
    canvas.drawCircle(center, r, Paint()..color = color);

    // Subsurface scattering simulation — warm inner glow
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.1, 0.15),
          radius: 0.7,
          colors: [
            const Color(0xFFCBFF99).withValues(alpha: 0.45),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Top-left light sheen
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.40),
          radius: 0.82,
          colors: [
            Colors.white.withValues(alpha: 0.38),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Texture bumps (simulate the grainy rubber surface)
    final rng = Random(7);
    final bumpPaint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (int i = 0; i < 28; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final d = rng.nextDouble() * r * 0.72;
      canvas.drawCircle(
        center + Offset(cos(a) * d, sin(a) * d),
        r * 0.038,
        bumpPaint,
      );
    }

    // Edge darkening (gives roundness / depth)
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.32),
          ],
          stops: const [0.62, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Primary highlight blob
    canvas.drawCircle(
      center + Offset(-r * 0.27, -r * 0.27),
      r * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.58),
    );

    // Bright specular glint
    canvas.drawCircle(
      center + Offset(-r * 0.20, -r * 0.35),
      r * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );
  }

  @override
  bool shouldRepaint(_StressBallPainter old) => old.color != color;
}
