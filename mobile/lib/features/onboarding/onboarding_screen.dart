import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

// ─── Data ──────────────────────────────────────────────────────────────────────

class _Page {
  final IconData icon;
  final String title;
  final String body;
  final Color heroStart;
  final Color heroEnd;

  const _Page({
    required this.icon,
    required this.title,
    required this.body,
    required this.heroStart,
    required this.heroEnd,
  });
}

const _pages = [
  _Page(
    icon: Icons.directions_car_rounded,
    title: 'Share the Road',
    body: 'Connect with verified colleagues and classmates for safe, trusted carpooling every day.',
    heroStart: AppTheme.primary,
    heroEnd: Color(0xFF1E40AF),
  ),
  _Page(
    icon: Icons.verified_user_rounded,
    title: 'Know Before\nYou Go',
    body: 'Every user is ID-verified. Browse driver profiles, ratings, and real-time routes before you book.',
    heroStart: AppTheme.primary,
    heroEnd: Color(0xFF1E40AF),
  ),
  _Page(
    icon: Icons.people_alt_rounded,
    title: 'Ride with People\nYou Trust',
    body: 'Split fuel costs with verified co-workers. Complete your profile and start your first ride today.',
    heroStart: AppTheme.primary,
    heroEnd: AppTheme.tertiary,
  ),
];

// ─── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_current];
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [page.heroStart, page.heroEnd],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ─── Skip button ─────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _current < _pages.length - 1
                      ? TextButton(
                          onPressed: _complete,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.8),
                          ),
                          child: const Text('Skip'),
                        )
                      : const SizedBox(height: 40),
                ),
              ),

              // ─── PageView with hero icon ──────────────────────────────────
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _HeroPage(page: _pages[i]),
                ),
              ),

              // ─── White bottom card ────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey(_current),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pages[_current].title,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _pages[_current].body,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Dots + CTA row
                      Row(
                        children: [
                          // Dots
                          Row(
                            children: List.generate(_pages.length, (i) {
                              final isActive = i == _current;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.only(right: 6),
                                width: isActive ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? page.heroStart
                                      : AppTheme.divider,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),

                          const Spacer(),

                          // CTA button
                          SizedBox(
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [page.heroStart, page.heroEnd]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: page.heroStart.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _next,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _current < _pages.length - 1
                                          ? 'Next'
                                          : 'Get Started',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _current < _pages.length - 1
                                          ? Icons.arrow_forward_rounded
                                          : Icons.rocket_launch_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero page widget ─────────────────────────────────────────────────────────

class _HeroPage extends StatelessWidget {
  final _Page page;
  const _HeroPage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              Icon(page.icon, size: 68, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
