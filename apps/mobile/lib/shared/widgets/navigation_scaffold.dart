import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../core/theme/app_theme.dart';

class NavigationScaffold extends StatelessWidget {
  final Widget child;

  const NavigationScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onTap(context, index),
        backgroundColor: AppColors.backgroundCard,
        selectedItemColor: AppColors.accentRed,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: false, // Inactive: icon only
        showSelectedLabels: true, // Active: icon + label
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.search),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.calendar),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.trophy),
            label: 'Compete',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/discover')) return 1;
    if (location.startsWith('/book')) return 2;
    if (location.startsWith('/compete')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/discover');
        break;
      case 2:
        context.go('/book');
        break;
      case 3:
        context.go('/compete');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
