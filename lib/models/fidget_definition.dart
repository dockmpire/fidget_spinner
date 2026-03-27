import 'package:flutter/material.dart';
import '../constants.dart';

/// Shared configuration and callbacks passed to every fidget widget.
class FidgetCallbacks {
  final VoidCallback onInteractionStart;
  final Function(int duration) onInteractionEnd; // duration in seconds
  final VoidCallback onHapticPulse;
  final double sensitivity;
  final int hapticIntensity; // 0=off, 1=light, 2=medium, 3=heavy

  const FidgetCallbacks({
    required this.onInteractionStart,
    required this.onInteractionEnd,
    required this.onHapticPulse,
    this.sensitivity = 1.0,
    this.hapticIntensity = 3,
  });
}

/// Metadata and builder for a single fidget toy.
class FidgetDefinition {
  final String id;
  final String name;
  final bool isPremium;

  /// App Store product ID — null for free fidgets.
  final String? productId;

  /// Display price (e.g. 0.99). Use ProductDetails.price for the localised string.
  final double price;

  final IconData icon;
  final Color accentColor;

  /// Builds the fidget widget with the given callbacks.
  final Widget Function(FidgetCallbacks callbacks) builder;

  const FidgetDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.builder,
    this.isPremium = false,
    this.productId,
    this.price = 0.0,
    this.accentColor = kAccent,
  });
}
