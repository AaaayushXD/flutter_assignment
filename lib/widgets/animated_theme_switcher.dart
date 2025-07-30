import 'package:flutter/material.dart';

class AnimatedThemeSwitcher extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final double size;

  const AnimatedThemeSwitcher({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.size = 60,
  });

  @override
  State<AnimatedThemeSwitcher> createState() => _AnimatedThemeSwitcherState();
}

class _AnimatedThemeSwitcherState extends State<AnimatedThemeSwitcher>
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scale animation controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animation curves
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOutBack),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
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
    widget.onThemeChanged(!widget.isDarkMode);
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
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isDarkMode
                        ? [
                            Colors.orange.withOpacity(0.3),
                            Colors.deepOrange.withOpacity(0.2),
                            Colors.orange.withOpacity(0.1),
                          ]
                        : [
                            Colors.indigo.withOpacity(0.3),
                            Colors.blue.withOpacity(0.2),
                            Colors.indigo.withOpacity(0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDarkMode
                          ? Colors.orange.withOpacity(0.4)
                          : Colors.indigo.withOpacity(0.4),
                      blurRadius: 15 * _pulseAnimation.value,
                      spreadRadius: 2 * _pulseAnimation.value,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.indigo.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
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
                      widget.isDarkMode
                          ? Icons.wb_sunny
                          : Icons.nightlight_round,
                      key: ValueKey(widget.isDarkMode),
                      color: widget.isDarkMode ? Colors.orange : Colors.indigo,
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

// Enhanced animated background container
class AnimatedBackgroundContainer extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;
  final Duration duration;

  const AnimatedBackgroundContainer({
    super.key,
    required this.isDarkMode,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F3460),
                  const Color(0xFF0F3460),
                ]
              : [
                  const Color(0xFFF5F5F5),
                  const Color(0xFFE8F4FD),
                  const Color(0xFFD4F1F4),
                  const Color(0xFFB8E6B8),
                ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
}

// Animated card with theme support
class AnimatedThemeCard extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Duration duration;

  const AnimatedThemeCard({
    super.key,
    required this.isDarkMode,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeInOut,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.8),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

// Animated text with theme support
class AnimatedThemeText extends StatelessWidget {
  final String text;
  final bool isDarkMode;
  final TextStyle? style;
  final Duration duration;

  const AnimatedThemeText({
    super.key,
    required this.text,
    required this.isDarkMode,
    this.style,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: duration,
      style: (style ?? const TextStyle()).copyWith(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      child: Text(text),
    );
  }
}
