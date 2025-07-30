import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/global_theme_switcher.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _count = 0;

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
          // Global Animated Theme Switcher
          GlobalThemeSwitcher(
            isDarkMode: isDarkMode,
            onThemeChanged: () {
              themeProvider.toggleTheme();
            },
            size: 50,
          ),
        ],
      ),
      body: Container(
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
                  _buildCounterDisplay(isDarkMode),
                  const SizedBox(height: 40),
                  _buildControlButtons(isDarkMode),
                ],
              ),
            ),
            _buildCounterHistory(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterDisplay(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.calculate,
            size: 60,
            color: isDarkMode ? Colors.white70 : Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            '$_count',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _count == 0
                ? 'Zero'
                : _count > 0
                ? 'Positive'
                : 'Negative',
            style: TextStyle(
              fontSize: 18,
              color: _count == 0
                  ? (isDarkMode ? Colors.white70 : Colors.grey)
                  : _count > 0
                  ? Colors.green
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Decrement Button
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              setState(() {
                _count--;
              });
            },
            color: Colors.red,
            iconSize: 40,
          ),
        ),

        // Reset Button
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _count = 0;
              });
            },
            color: Colors.orange,
            iconSize: 40,
          ),
        ),

        // Increment Button
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _count++;
              });
            },
            color: Colors.green,
            iconSize: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildCounterHistory(bool isDarkMode) {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Current: $_count',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionButton('+5', () {
                  setState(() {
                    _count += 5;
                  });
                }, Colors.green, isDarkMode ),
                _buildQuickActionButton('+10', () {
                  setState(() {
                    _count += 10;
                  });
                }, Colors.green, isDarkMode),
                _buildQuickActionButton('+50', () {
                  setState(() {
                    _count += 50;
                  });
                }, Colors.green, isDarkMode),
                _buildQuickActionButton('-5', () {
                  setState(() {
                    _count -= 5;
                  });
                }, Colors.red, isDarkMode),
                _buildQuickActionButton('-10', () {
                  setState(() {
                    _count -= 10;
                  });
                }, Colors.red, isDarkMode),
                _buildQuickActionButton('-50', () {
                  setState(() {
                    _count -= 50;
                  });
                }, Colors.red, isDarkMode),
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
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
