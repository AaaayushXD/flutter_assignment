import 'package:flutter/material.dart';

class GlobalThemeSwitcher extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;
  final double size;

  const GlobalThemeSwitcher({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.size = 36,
  });

  @override
  State<GlobalThemeSwitcher> createState() => _GlobalThemeSwitcherState();
}

class _GlobalThemeSwitcherState extends State<GlobalThemeSwitcher>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation controller
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Scale animation controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animation curves
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOutBack),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    // Trigger scale animation
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    // Trigger rotation animation
    _rotationController.forward().then((_) {
      _rotationController.reset();
    });

    // Change theme
    widget.onThemeChanged();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationAnimation,
          _scaleAnimation,
          _pulseAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isDarkMode
                        ? [
                            Colors.orange.withOpacity(0.6),
                            Colors.deepOrange.withOpacity(0.4),
                            Colors.orange.withOpacity(0.3),
                          ]
                        : [
                            Colors.blue.withOpacity(0.6),
                            Colors.indigo.withOpacity(0.4),
                            Colors.blue.withOpacity(0.3),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDarkMode
                          ? Colors.orange.withOpacity(0.6)
                          : Colors.blue.withOpacity(0.6),
                      blurRadius: 8 * _pulseAnimation.value,
                      spreadRadius: 1 * _pulseAnimation.value,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.orange.withOpacity(0.6)
                          : Colors.blue.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                    child: Icon(
                      widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      key: ValueKey(widget.isDarkMode),
                      color: widget.isDarkMode ? Colors.orange : Colors.blue,
                      size: widget.size * 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
