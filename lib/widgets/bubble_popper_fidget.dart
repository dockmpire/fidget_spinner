import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/fidget_definition.dart';

class BubblePopperFidget extends StatefulWidget {
  final FidgetCallbacks callbacks;
  const BubblePopperFidget({super.key, required this.callbacks});

  @override
  State<BubblePopperFidget> createState() => _BubblePopperFidgetState();
}

class _BubblePopperFidgetState extends State<BubblePopperFidget>
    with TickerProviderStateMixin {
  static const int _gridSize = 5;
  static const int _total = _gridSize * _gridSize;

  static const _bubbleColors = [
    Color(0xFFE91E8C), // hot pink
    Color(0xFFAB47BC), // purple
    Color(0xFF5C6BC0), // indigo
    Color(0xFF26C6DA), // cyan
    Color(0xFF66BB6A), // green
  ];

  late List<bool> _popped;
  late List<AnimationController> _controllers;
  bool _interactionStarted = false;

  @override
  void initState() {
    super.initState();
    _popped = List.filled(_total, false);
    _controllers = List.generate(
      _total,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 160),
        vsync: this,
      ),
    );
  }

  Color _colorForIndex(int index) {
    final row = index ~/ _gridSize;
    final col = index % _gridSize;
    return _bubbleColors[(row + col) % _bubbleColors.length];
  }

  void _popBubble(int index) {
    if (_popped[index]) return;

    if (!_interactionStarted) {
      _interactionStarted = true;
      widget.callbacks.onInteractionStart();
    }

    setState(() => _popped[index] = true);
    _controllers[index].forward();
    _triggerHaptic();

    if (_popped.every((p) => p)) {
      widget.callbacks.onInteractionEnd(1);
      Future.delayed(const Duration(milliseconds: 900), _resetAll);
    }
  }

  void _resetAll() {
    if (!mounted) return;
    for (final c in _controllers) c.reset();
    setState(() {
      _popped = List.filled(_total, false);
      _interactionStarted = false;
    });
  }

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
      default:
        HapticFeedback.heavyImpact();
    }
    widget.callbacks.onHapticPulse();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = min(constraints.maxWidth, constraints.maxHeight) * 0.88;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE91E8C).withValues(alpha: 0.35),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E8C).withValues(alpha: 0.18),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: EdgeInsets.all(size * 0.035),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: _total,
          itemBuilder: (context, index) {
            final color = _colorForIndex(index);
            return AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, _) {
                final progress = _controllers[index].value;
                final isPopped = _popped[index];
                return GestureDetector(
                  onTapDown: (_) => _popBubble(index),
                  child: isPopped && progress >= 1.0
                      ? CustomPaint(
                          painter: _PoppedBubblePainter(color: color),
                        )
                      : Transform.scale(
                          scale: isPopped ? (1.0 - progress) : 1.0,
                          child: CustomPaint(
                            painter: _DomeBubblePainter(color: color),
                          ),
                        ),
                );
              },
            );
          },
        ),
      );
    });
  }
}

class _DomeBubblePainter extends CustomPainter {
  final Color color;
  const _DomeBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 * 0.88;

    // Soft drop shadow
    canvas.drawCircle(
      center + Offset(0, r * 0.12),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.25),
    );

    // Base dome
    canvas.drawCircle(center, r, Paint()..color = color);

    // Radial sheen (3D dome illusion)
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.38),
          radius: 0.88,
          colors: [
            Colors.white.withValues(alpha: 0.52),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Bottom rim darkening for depth
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.3, 0.45),
          radius: 0.75,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.28),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Primary highlight
    canvas.drawCircle(
      center + Offset(-r * 0.26, -r * 0.28),
      r * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.62),
    );

    // Tiny specular glint
    canvas.drawCircle(
      center + Offset(-r * 0.18, -r * 0.34),
      r * 0.07,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_DomeBubblePainter old) => old.color != color;
}

class _PoppedBubblePainter extends CustomPainter {
  final Color color;
  const _PoppedBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 * 0.88;

    // Flat sunken disc
    canvas.drawCircle(center, r, Paint()..color = color.withValues(alpha: 0.18));

    // Concave ring shadow
    canvas.drawCircle(
      center,
      r * 0.85,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08),
    );

    // Inner indent circle
    canvas.drawCircle(
      center,
      r * 0.5,
      Paint()
        ..color = color.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PoppedBubblePainter old) => old.color != color;
}
