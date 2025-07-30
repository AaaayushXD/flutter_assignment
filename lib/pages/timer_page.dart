import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/global_theme_switcher.dart';
import 'dart:async';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer? _timer;
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  final List<int> _presetTimes = [
    300,
    600,
    900,
    1800,
    2700,
    3600,
  ]; // 5, 10, 15, 30, 45, 60 minutes

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    if (_remainingSeconds > 0) {
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _stopTimer();
            _showTimerCompleteDialog(isDarkMode);
          }
        });
      });
    }
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
      _timer?.cancel();
    });
  }

  void _resumeTimer() {
    if (_isPaused) {
      _startTimer();
    }
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _timer?.cancel();
    });
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _totalSeconds;
      _timer?.cancel();
    });
  }

  void _setPresetTime(int seconds) {
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
      _isRunning = false;
      _isPaused = false;
      _timer?.cancel();
    });
  }

  void _showCustomTimeDialog(bool isDarkMode) {
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set Custom Time',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Hours',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    onChanged: (value) => hours = int.tryParse(value) ?? 0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Minutes',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    onChanged: (value) => minutes = int.tryParse(value) ?? 0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Seconds',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    onChanged: (value) => seconds = int.tryParse(value) ?? 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final totalSeconds = hours * 3600 + minutes * 60 + seconds;
              if (totalSeconds > 0) {
                _setPresetTime(totalSeconds);
              }
              Navigator.pop(context);
            },
            child: Text(
              'Set',
              style: TextStyle(color: isDarkMode ? Colors.blue : Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimerCompleteDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Timer Complete!',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        content: Text(
          'Your timer has finished!',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
            child: Text(
              'OK',
              style: TextStyle(color: isDarkMode ? Colors.blue : Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
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
        title: const Text('Timer'),
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
                  _buildTimeDisplay(isDarkMode),
                  const SizedBox(height: 40),
                  _buildControlButtons(isDarkMode),
                ],
              ),
            ),
            _buildPresetTimes(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(bool isDarkMode) {
    final progress = _totalSeconds > 0
        ? (_totalSeconds - _remainingSeconds) / _totalSeconds
        : 0.0;

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
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isRunning ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              Column(
                children: [
                  Icon(
                    Icons.timer,
                    size: 40,
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _isRunning
                        ? 'Running'
                        : _isPaused
                        ? 'Paused'
                        : 'Stopped',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isRunning
                          ? Colors.green
                          : _isPaused
                          ? Colors.orange
                          : (isDarkMode ? Colors.white70 : Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Reset Button
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(25),
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
            onPressed: _resetTimer,
            color: Colors.orange,
            iconSize: 30,
          ),
        ),

        // Start/Pause/Resume Button
        Container(
          decoration: BoxDecoration(
            color: _isRunning ? Colors.red : Colors.green,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: _isRunning
                ? _pauseTimer
                : (_isPaused ? _resumeTimer : _startTimer),
            color: Colors.white,
            iconSize: 40,
          ),
        ),

        // Stop Button
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _stopTimer,
            color: Colors.red,
            iconSize: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetTimes(bool isDarkMode) {
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
                  'Preset Times',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showCustomTimeDialog(isDarkMode),
                  icon: const Icon(Icons.add),
                  label: const Text('Custom'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
              ),
              itemCount: _presetTimes.length,
              itemBuilder: (context, index) {
                final seconds = _presetTimes[index];
                final minutes = seconds ~/ 60;
                return Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _totalSeconds == seconds
                          ? Colors.blue
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => _setPresetTime(seconds),
                    child: Text(
                      '${minutes}m',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _totalSeconds == seconds
                            ? Colors.blue
                            : (isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
