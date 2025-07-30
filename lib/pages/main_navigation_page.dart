import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'weather_page.dart';
import 'songs_page.dart';
import 'utils_page.dart';
import 'auth/login_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SongsPage(),
    const WeatherPage(),
    const UtilsPage(),
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(icon: Icons.music_note, title: "Songs", color: Colors.purple),
    BottomNavItem(icon: Icons.cloud, title: "Weather", color: Colors.blue),
    BottomNavItem(icon: Icons.build, title: "Utils", color: Colors.teal),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginPage();
        }

        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Scaffold(
              backgroundColor: themeProvider.isDarkMode
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFFF5F5F5),
              body: Stack(
                children: [
                  // Main content with dynamic padding
                  _DynamicContentPadding(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: _screens,
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        _navItems.length,
                        (index) =>
                            _buildNavItem(index, themeProvider.isDarkMode),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavItem(int index, bool isDarkMode) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? item.color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected
                  ? item.color
                  : (isDarkMode ? Colors.white70 : Colors.grey),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? item.color
                    : (isDarkMode ? Colors.white70 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _DynamicContentPadding({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 20.0, // Space for bottom navigation only
      ),
      child: child,
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String title;
  final Color color;

  BottomNavItem({required this.icon, required this.title, required this.color});
}
