import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feature_hint.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(authProvider.notifier).init(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // ─── Gradient hero with avatar ───────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.tertiary],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(
                                    '${user.firstName[0]}${user.lastName[0]}',
                                    style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () => context.push('/profile/edit'),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.15),
                                      blurRadius: 6,
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.edit,
                                    size: 14, color: AppTheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _VerificationBadge(user: user),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Feature hint ─────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: FeatureHint(
                featureKey: 'profile',
                icon: Icons.person_outline,
                title: 'Your Profile',
                description:
                    'Complete your profile and submit for admin verification. Once verified, you can post rides.',
                color: AppTheme.primary,
              ),
            ),
          ),

          // ─── Content ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                children: [
                  // Stats row
                  _StatsRow(user: user),
                  const SizedBox(height: 16),

                  // Rejection banner
                  if (user.isRejected) ...[
                    _RejectionBanner(
                      reason: user.rejectionReason ??
                          'Your verification was declined.',
                      onResubmit: () => context.push('/profile/complete'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Complete profile CTA
                  if (!user.isVerified &&
                      !user.isRejected &&
                      !user.hasSubmittedProfile) ...[
                    _CompleteProfileBanner(
                        onTap: () => context.push('/profile/complete')),
                    const SizedBox(height: 12),
                  ],

                  // Account menu
                  _MenuSection(
                    title: 'Account',
                    items: [
                      _MenuItem(
                        icon: Icons.edit_outlined,
                        label: 'Edit Profile',
                        onTap: () => context.push('/profile/edit'),
                      ),
                      _MenuItem(
                        icon: Icons.directions_car_outlined,
                        label: 'My Vehicles',
                        onTap: () => context.push('/profile/vehicles'),
                      ),
                      _MenuItem(
                        icon: user.isVerified
                            ? Icons.verified_user_outlined
                            : user.isRejected
                                ? Icons.refresh_outlined
                                : user.hasSubmittedProfile
                                    ? Icons.hourglass_top_outlined
                                    : Icons.assignment_outlined,
                        label: user.isVerified
                            ? 'Verified'
                            : user.isRejected
                                ? 'Update & Resubmit'
                                : user.hasSubmittedProfile
                                    ? 'Under Review'
                                    : 'Complete Profile',
                        onTap: user.isVerified || user.hasSubmittedProfile
                            ? null
                            : () => context.push('/profile/complete'),
                        color: user.isVerified
                            ? AppTheme.secondary
                            : user.isRejected
                                ? AppTheme.error
                                : user.hasSubmittedProfile
                                    ? AppTheme.warning
                                    : AppTheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // App menu
                  _MenuSection(
                    title: 'App',
                    items: [
                      _MenuItem(
                        icon: Icons.info_outline,
                        label: 'About RideSync',
                        onTap: () => context.push('/about'),
                      ),
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        color: AppTheme.error,
                        onTap: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserModel user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          _Stat(
              value: '${user.trustScore.toStringAsFixed(0)}',
              label: 'Trust Score',
              color: AppTheme.primary),
          _divider(),
          _Stat(
              value: user.isProfessional ? 'Pro' : 'Student',
              label: 'Account Type',
              color: AppTheme.tertiary),
          if (user.companyEmail != null || user.universityEmail != null) ...[
            _divider(),
            _Stat(
                value: '✓',
                label: user.companyEmail != null ? 'Work Email' : 'Uni Email',
                color: AppTheme.secondary),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 36, color: AppTheme.divider,
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Menu section ─────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              return Column(
                children: [
                  items[i],
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 52),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textPrimary;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 18),
      ),
      title: Text(label,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: AppTheme.textHint, size: 18)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

// ─── Verification badge ───────────────────────────────────────────────────────

class _VerificationBadge extends StatelessWidget {
  final UserModel user;
  const _VerificationBadge({required this.user});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    if (user.isVerified) {
      color = AppTheme.secondary;
      icon = Icons.verified;
      label = 'Verified ${user.isProfessional ? 'Professional' : 'Student'}';
    } else if (user.isRejected) {
      color = AppTheme.error;
      icon = Icons.cancel_outlined;
      label = 'Verification Declined';
    } else if (user.hasSubmittedProfile) {
      color = AppTheme.warning;
      icon = Icons.hourglass_top_outlined;
      label = 'Under Review';
    } else {
      color = Colors.white70;
      icon = Icons.assignment_outlined;
      label = 'Profile Incomplete';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color == Colors.white70 ? Colors.white : Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─── Rejection banner ─────────────────────────────────────────────────────────

class _RejectionBanner extends StatelessWidget {
  final String reason;
  final VoidCallback onResubmit;
  const _RejectionBanner(
      {required this.reason, required this.onResubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cancel_outlined, color: AppTheme.error, size: 16),
              SizedBox(width: 8),
              Text('Verification Declined',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.error)),
            ],
          ),
          const SizedBox(height: 6),
          Text(reason,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onResubmit,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Update & Resubmit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Complete profile banner ──────────────────────────────────────────────────

class _CompleteProfileBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _CompleteProfileBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.tertiary]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.assignment_outlined, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complete your profile',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Required to book or post rides',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
