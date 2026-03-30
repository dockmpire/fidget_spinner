import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/fidget_definition.dart';
import '../services/sound_service.dart';

class BubblePopperFidget extends StatefulWidget {
  final FidgetCallbacks callbacks;
  const BubblePopperFidget({super.key, required this.callbacks});

  @override
  State<BubblePopperFidget> createState() => _BubblePopperFidgetState();
}

class _BubblePopperFidgetState extends State<BubblePopperFidget>
    with TickerProviderStateMixin {
  static const int _cols = 6;
  static const int _rows = 8;
  static const int _total = _cols * _rows; // 48

  static const _bubbleColor = Color(0xFF5C6BC0); // indigo

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
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );
  }

  void _popBubble(int index) {
    if (_popped[index]) return;

    if (!_interactionStarted) {
      _interactionStarted = true;
      widget.callbacks.onInteractionStart();
    }

    setState(() => _popped[index] = true);
    _controllers[index].forward();
    SoundService.instance.playBubblePop();
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
      const spacing = 6.0;
      const padding = 12.0;

      // Compute the largest square cell that fits _cols columns and _rows rows
      final cellW = (constraints.maxWidth - 2 * padding - (_cols - 1) * spacing) / _cols;
      final cellH = (constraints.maxHeight - 2 * padding - (_rows - 1) * spacing) / _rows;
      final cell = min(cellW, cellH);

      final gridW = _cols * cell + (_cols - 1) * spacing + 2 * padding;
      final gridH = _rows * cell + (_rows - 1) * spacing + 2 * padding;

      return Center(
        child: Container(
          width: gridW,
          height: gridH,
          decoration: BoxDecoration(
            color: const Color(0xFF12122A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _bubbleColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(padding),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _cols,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: 1.0,
            ),
            itemCount: _total,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controllers[index],
                builder: (context, _) {
                  final progress = _controllers[index].value;
                  final isPopped = _popped[index];
                  return GestureDetector(
                    onTapDown: (_) => _popBubble(index),
                    child: isPopped && progress >= 1.0
                        ? CustomPaint(
                            painter: _PoppedBubblePainter(color: _bubbleColor),
                          )
                        : Transform.scale(
                            scale: isPopped ? (1.0 - progress) : 1.0,
                            child: CustomPaint(
                              painter: _DomeBubblePainter(color: _bubbleColor),
                            ),
                          ),
                  );
                },
              );
            },
          ),
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

    // Drop shadow
    canvas.drawCircle(
      center + Offset(0, r * 0.12),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.22),
    );

    // Base dome
    canvas.drawCircle(center, r, Paint()..color = color);

    // Radial sheen
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.38),
          radius: 0.85,
          colors: [
            Colors.white.withValues(alpha: 0.48),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Bottom rim darkening
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.3, 0.5),
          radius: 0.7,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.30),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Primary highlight
    canvas.drawCircle(
      center + Offset(-r * 0.26, -r * 0.28),
      r * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.58),
    );

    // Specular glint
    canvas.drawCircle(
      center + Offset(-r * 0.18, -r * 0.35),
      r * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
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

    // Sunken flat disc
    canvas.drawCircle(center, r, Paint()..color = color.withValues(alpha: 0.15));

    // Concave ring shadow
    canvas.drawCircle(
      center,
      r * 0.82,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.18
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.07),
    );

    // Inner indent ring
    canvas.drawCircle(
      center,
      r * 0.45,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_PoppedBubblePainter old) => old.color != color;
}
