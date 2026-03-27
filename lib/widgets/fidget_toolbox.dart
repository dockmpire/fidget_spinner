import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/fidget_definition.dart';
import '../models/fidget_registry.dart';

/// Slide-up toolbox for selecting a fidget toy.
/// Triggered by long-pressing the active fidget on the home screen.
class FidgetToolbox extends StatefulWidget {
  final int activeFidgetIndex;
  final Function(int index) onSelect;
  final VoidCallback onDismiss;

  const FidgetToolbox({
    super.key,
    required this.activeFidgetIndex,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<FidgetToolbox> createState() => _FidgetToolboxState();
}

class _FidgetToolboxState extends State<FidgetToolbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.activeFidgetIndex;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Future<void> _select(int index) async {
    await _controller.reverse();
    widget.onSelect(index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop — tap to dismiss
        FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
        ),

        // Toolbox panel
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnimation,
            child: _ToolboxPanel(
              selectedIndex: _selectedIndex,
              onSelect: (index) {
                setState(() => _selectedIndex = index);
              },
              onConfirm: _select,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolboxPanel extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  final Function(int) onConfirm;

  const _ToolboxPanel({
    required this.selectedIndex,
    required this.onSelect,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final fidgets = FidgetRegistry.all;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: kAccent.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kTextMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Label
          const Text(
            'Select Fidget',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Fidget cards
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fidgets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final fidget = fidgets[index];
                final isSelected = index == selectedIndex;
                return _FidgetCard(
                  fidget: fidget,
                  isSelected: isSelected,
                  onTap: () {
                    onSelect(index);
                    onConfirm(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FidgetCard extends StatelessWidget {
  final FidgetDefinition fidget;
  final bool isSelected;
  final VoidCallback onTap;

  const _FidgetCard({
    required this.fidget,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: fidget.isPremium ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 100,
        decoration: BoxDecoration(
          color: isSelected
              ? fidget.accentColor.withValues(alpha: 0.12)
              : kBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? fidget.accentColor
                : kTextMuted.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Icon + name
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    fidget.icon,
                    color: isSelected ? fidget.accentColor : kTextMuted,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fidget.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kTextMuted,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Lock badge for premium
            if (fidget.isPremium)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: kTextMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(Icons.lock, color: kTextMuted, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
