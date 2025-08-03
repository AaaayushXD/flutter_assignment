import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../blocs/counter/counter.dart';
import '../providers/theme_provider.dart';
import '../widgets/global_theme_switcher.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CounterBloc()..add(LoadCounter()),
      child: const CounterView(),
    );
  }
}

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start the pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF1A1A2E)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Counter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          GlobalThemeSwitcher(
            isDarkMode: isDarkMode,
            onThemeChanged: () {
              themeProvider.toggleTheme();
            },
            size: 50,
          ),
        ],
      ),
      body: BlocBuilder<CounterBloc, CounterState>(
        builder: (context, state) {
          if (state is CounterLoading) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          const Color(0xFF1A1A2E),
                          const Color(0xFF16213E),
                          const Color(0xFF0F3460),
                        ]
                      : [
                          const Color(0xFFF5F5F5),
                          const Color(0xFFE8F4FD),
                          const Color(0xFFD4F1F4),
                        ],
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state is CounterError) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          const Color(0xFF1A1A2E),
                          const Color(0xFF16213E),
                          const Color(0xFF0F3460),
                        ]
                      : [
                          const Color(0xFFF5F5F5),
                          const Color(0xFFE8F4FD),
                          const Color(0xFFD4F1F4),
                        ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CounterBloc>().add(LoadCounter());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is CounterLoaded) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          const Color(0xFF1A1A2E),
                          const Color(0xFF16213E),
                          const Color(0xFF0F3460),
                        ]
                      : [
                          const Color(0xFFF5F5F5),
                          const Color(0xFFE8F4FD),
                          const Color(0xFFD4F1F4),
                        ],
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCounterDisplay(isDarkMode, state),
                        const SizedBox(height: 50),
                        _buildControlButtons(isDarkMode),
                      ],
                    ),
                  ),
                  _buildCounterHistory(isDarkMode, state),
                ],
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                        const Color(0xFF0F3460),
                      ]
                    : [
                        const Color(0xFFF5F5F5),
                        const Color(0xFFE8F4FD),
                        const Color(0xFFD4F1F4),
                      ],
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildCounterDisplay(bool isDarkMode, CounterLoaded state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.calculate_rounded,
                    size: 50,
                    color: isDarkMode ? Colors.white70 : Colors.blue,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),

          // Counter display
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsivePadding(state.count),
              vertical: 25,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.blue.withOpacity(0.1),
                        Colors.green.withOpacity(0.1),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${state.count}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(state.count),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isDarkMode ? Colors.white : Colors.black87,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (state.isSaving)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.save,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _getStatusColor(isDarkMode, state.count).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(
                  isDarkMode,
                  state.count,
                ).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(isDarkMode, state.count),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(state.count),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(isDarkMode, state.count),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isDarkMode, int count) {
    if (count == 0) {
      return isDarkMode ? Colors.white70 : Colors.grey;
    } else if (count > 0) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  String _getStatusText(int count) {
    if (count == 0) {
      return 'Zero';
    } else if (count > 0) {
      return 'Positive';
    } else {
      return 'Negative';
    }
  }

  double _getResponsiveFontSize(int count) {
    final digitCount = count.abs().toString().length;

    // Adjust font size based on number of digits
    if (digitCount <= 3) {
      return 90.0;
    } else if (digitCount == 4) {
      return 70.0;
    } else if (digitCount == 5) {
      return 55.0;
    } else if (digitCount == 6) {
      return 45.0;
    } else {
      return 35.0; // For 7+ digits
    }
  }

  double _getResponsivePadding(int count) {
    final digitCount = count.abs().toString().length;

    // Adjust padding based on number of digits
    if (digitCount <= 3) {
      return 40.0;
    } else if (digitCount == 4) {
      return 30.0;
    } else if (digitCount == 5) {
      return 20.0;
    } else if (digitCount == 6) {
      return 15.0;
    } else {
      return 10.0; // For 7+ digits
    }
  }

  Widget _buildControlButtons(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Decrement Button
        _buildControlButton(
          icon: Icons.remove_rounded,
          onPressed: () =>
              context.read<CounterBloc>().add(const DecrementCounter()),
          color: Colors.red,
          isDarkMode: isDarkMode,
          size: 60,
        ),

        // Reset Button
        _buildControlButton(
          icon: Icons.refresh_rounded,
          onPressed: () => context.read<CounterBloc>().add(ResetCounter()),
          color: Colors.orange,
          isDarkMode: isDarkMode,
          size: 50,
        ),

        // Increment Button
        _buildControlButton(
          icon: Icons.add_rounded,
          onPressed: () =>
              context.read<CounterBloc>().add(const IncrementCounter()),
          color: Colors.green,
          isDarkMode: isDarkMode,
          size: 60,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required bool isDarkMode,
    required double size,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
            ),
            child: Icon(icon, color: color, size: size * 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterHistory(bool isDarkMode, CounterLoaded state) {
    return Container(
      width: double.infinity,
      height: 220,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Current: ${state.count}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              crossAxisCount: 3,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 2.8,
              children: [
                _buildQuickActionButton(
                  '+5',
                  () => context.read<CounterBloc>().add(
                    const IncrementCounter(5),
                  ),
                  Colors.green,
                  isDarkMode,
                ),
                _buildQuickActionButton(
                  '+10',
                  () => context.read<CounterBloc>().add(
                    const IncrementCounter(10),
                  ),
                  Colors.green,
                  isDarkMode,
                ),
                _buildQuickActionButton(
                  '+50',
                  () => context.read<CounterBloc>().add(
                    const IncrementCounter(50),
                  ),
                  Colors.green,
                  isDarkMode,
                ),
                _buildQuickActionButton(
                  '-5',
                  () => context.read<CounterBloc>().add(
                    const DecrementCounter(5),
                  ),
                  Colors.red,
                  isDarkMode,
                ),
                _buildQuickActionButton(
                  '-10',
                  () => context.read<CounterBloc>().add(
                    const DecrementCounter(10),
                  ),
                  Colors.red,
                  isDarkMode,
                ),
                _buildQuickActionButton(
                  '-50',
                  () => context.read<CounterBloc>().add(
                    const DecrementCounter(50),
                  ),
                  Colors.red,
                  isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    VoidCallback onPressed,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
