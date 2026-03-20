import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(const FidgetSpinnerApp());
}

class FidgetSpinnerApp extends StatelessWidget {
  const FidgetSpinnerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fidget Spinner',
      theme: ThemeData(useMaterial3: true),
      home: const SpinnerScreen(),
    );
  }
}

class SpinnerScreen extends StatefulWidget {
  const SpinnerScreen({Key? key}) : super(key: key);
  @override
  State<SpinnerScreen> createState() => _SpinnerScreenState();
}

class _SpinnerScreenState extends State<SpinnerScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  double _spinVelocity = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
  }

  void _spin() {
    _spinVelocity = 5;
    _spinController.forward(from: 0);

    // Haptic feedback
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: GestureDetector(
          onTap: _spin,
          child: RotationTransition(
            turns: _spinController,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }
}
