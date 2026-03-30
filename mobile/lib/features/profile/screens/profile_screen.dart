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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const FeatureHint(
                featureKey: 'profile',
                icon: Icons.person_outline,
                title: 'Your Profile',
                description:
                    'Complete your profile and submit for admin verification. Once verified, you can post rides. Keep your info up to date.',
                color: AppTheme.primary,
              ),
              Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
            children: [
              // ─── Avatar & Name ────────────────────────────────────────
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        '${user.firstName[0]}${user.lastName[0]}',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.fullName,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              Text(
                user.email,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),

              // ─── Verification badge ───────────────────────────────────
              _VerificationBadge(user: user),

              // ─── Trust score ──────────────────────────────────────────
              const SizedBox(height: 20),
              _InfoCard(children: [
                _InfoRow(
                  icon: Icons.star_outline,
                  label: 'Trust Score',
                  value: '${user.trustScore.toStringAsFixed(0)}/100',
                ),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Account Type',
                  value: user.isProfessional ? 'Professional' : 'Student',
                ),
                if (user.companyEmail != null)
                  _InfoRow(
                    icon: Icons.business,
                    label: 'Company Email',
                    value: user.companyEmail!,
                    verified: true,
                  ),
                if (user.universityEmail != null)
                  _InfoRow(
                    icon: Icons.school,
                    label: 'University Email',
                    value: user.universityEmail!,
                    verified: true,
                  ),
              ]),

              const SizedBox(height: 16),

              // ─── Rejection reason banner ──────────────────────────────
              if (user.isRejected) ...[
                _RejectionBanner(
                  reason: user.rejectionReason ?? 'Your verification was declined.',
                  onResubmit: () => context.push('/profile/complete'),
                ),
                const SizedBox(height: 4),
              ],

              // ─── Complete profile CTA (if not yet submitted) ──────────
              if (!user.isVerified && !user.isRejected && !user.hasSubmittedProfile) ...[
                _CompleteProfileBanner(
                  onTap: () => context.push('/profile/complete'),
                ),
                const SizedBox(height: 4),
              ],

              // ─── Menu items ───────────────────────────────────────────
              const SizedBox(height: 16),
              _MenuCard(items: [
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
              ]),

              const SizedBox(height: 12),

              _MenuCard(items: [
                _MenuItem(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  color: AppTheme.error,
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ]),
            ],
          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool verified;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.textSecondary),
      title: Text(label,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary)),
      trailing: verified
          ? const Icon(Icons.check_circle, color: AppTheme.secondary, size: 16)
          : null,
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: items),
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
      leading: Icon(icon, color: c, size: 20),
      title: Text(label,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: AppTheme.textHint, size: 18)
          : null,
      onTap: onTap,
    );
  }
}

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
      color = const Color(0xFF64748B);
      icon = Icons.assignment_outlined;
      label = 'Profile Incomplete';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}

class _RejectionBanner extends StatelessWidget {
  final String reason;
  final VoidCallback onResubmit;
  const _RejectionBanner({required this.reason, required this.onResubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined,
                  color: AppTheme.error, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Verification Declined',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.error),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reason,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onResubmit,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Update & Resubmit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteProfileBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _CompleteProfileBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined,
                  color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complete your profile',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.primary)),
                  SizedBox(height: 2),
                  Text(
                    'Required to book or post rides',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
