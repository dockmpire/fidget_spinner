import 'package:flutter/material.dart';
import 'fidget_definition.dart';
import '../constants.dart';
import '../services/iap_product_ids.dart';
import '../widgets/spinner_fidget.dart';
import '../widgets/bubble_popper_fidget.dart';
import '../widgets/stress_ball_fidget.dart';

/// Central registry of all available fidget toys.
/// To add a new fidget: import its widget and add a FidgetDefinition entry.
class FidgetRegistry {
  static final List<FidgetDefinition> all = [
    FidgetDefinition(
      id: 'spinner',
      name: 'Spinner',
      icon: Icons.rotate_right,
      accentColor: kAccent,
      isPremium: false,
      price: 0.0,
      builder: (callbacks) => SpinnerFidget(callbacks: callbacks),
    ),

    // TEST — remove before publishing:
    FidgetDefinition(
      id: 'bubble_popper',
      name: 'Bubble Popper',
      icon: Icons.bubble_chart,
      accentColor: Color(0xFF5C6BC0),
      isPremium: false,
      price: 0.0,
      builder: (callbacks) => BubblePopperFidget(callbacks: callbacks),
    ),

    // TEST — remove before publishing:
    FidgetDefinition(
      id: 'stress_ball',
      name: 'Stress Ball',
      icon: Icons.circle,
      accentColor: Color(0xFF4DD0E1),
      isPremium: false,
      price: 0.0,
      builder: (callbacks) => StressBallFidget(callbacks: callbacks),
    ),

    // Coming soon — uncomment when widget is built:
    // FidgetDefinition(
    //   id: 'water_gun',
    //   name: 'Water Gun',
    //   icon: Icons.water_drop,
    //   accentColor: Color(0xFF00AAFF),
    //   isPremium: true,
    //   productId: IAPProductIds.waterGun,
    //   price: 0.99,
    //   builder: (callbacks) => WaterGunFidget(callbacks: callbacks),
    // ),
  ];

  static FidgetDefinition getById(String id) {
    return all.firstWhere((f) => f.id == id);
  }

  static List<FidgetDefinition> get free => all.where((f) => !f.isPremium).toList();
  static List<FidgetDefinition> get premium => all.where((f) => f.isPremium).toList();
}
