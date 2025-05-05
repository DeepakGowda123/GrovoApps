import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'farmer_dashboard_screen.dart';
import 'work_screen.dart';
import 'account_screen.dart';
import 'tools_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final User user;
  const MainNavigationScreen({super.key, required this.user});
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _screens;

  // Animation controller
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Colors
  final Color _primaryColor = const Color(0xFF4CAF50);
  final Color _textColor = const Color(0xFF424242);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // Initialize screens with their respective screen classes
    _screens = [
      FarmerDashboardScreen(user: widget.user),
      WorkScreen(user: widget.user),
      AccountScreen(user: widget.user),
      ToolsScreen(user: widget.user),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    // Reset and play fade animation
    _fadeController.reset();
    _fadeController.forward();

    _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CustomBottomNavigationBar(
            selectedIndex: _selectedIndex,
            onTap: _onTabTapped,
            primaryColor: _primaryColor,
            textColor: _textColor,
          ),
        ),
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final Color primaryColor;
  final Color textColor;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, 'Dashboard', Icons.dashboard_rounded),
          _buildNavItem(1, 'Work', Icons.work_rounded),
          _buildNavItem(2, 'Account', Icons.person_rounded),
          _buildNavItem(3, 'Tools', Icons.handyman_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final bool isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      splashColor: primaryColor.withOpacity(0.1),
      highlightColor: primaryColor.withOpacity(0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : textColor.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : textColor.withOpacity(0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}