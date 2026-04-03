import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';

final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res =
        await DioClient.instance.get(ApiConstants.notifications);
    return (res.data as List).cast<Map<String, dynamic>>();
  } catch (_) {
    return [];
  }
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _markRead();
  }

  Future<void> _markRead() async {
    try {
      await DioClient.instance.patch(ApiConstants.markNotificationsRead);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ─── Gradient header ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.tertiary],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => context.pop(),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Your latest updates',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Content ─────────────────────────────────────────────────
          Expanded(
            child: state.when(
              data: (notifications) => RefreshIndicator(
                onRefresh: () => ref.refresh(notificationsProvider.future),
                child: notifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_none_outlined,
                                      size: 56, color: AppTheme.textHint),
                                  SizedBox(height: 16),
                                  Text('No notifications yet',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary)),
                                  SizedBox(height: 6),
                                  Text('Booking updates will appear here',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _NotificationCard(notification: notifications[i]),
                      ),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 40, color: AppTheme.textHint),
                    const SizedBox(height: 12),
                    Text(e.toString(),
                        style:
                            const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.invalidate(notificationsProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.tertiary,
                        side: const BorderSide(color: AppTheme.tertiary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  const _NotificationCard({required this.notification});

  IconData _icon(String? type) {
    switch (type) {
      case 'BOOKING_CONFIRMED':
        return Icons.check_circle_outline;
      case 'BOOKING_CANCELLED':
        return Icons.cancel_outlined;
      case 'BOOKING_REQUEST':
        return Icons.person_add_outlined;
      case 'RIDE_STARTING':
        return Icons.directions_car_outlined;
      case 'RIDE_COMPLETED':
        return Icons.flag_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _color(String? type) {
    switch (type) {
      case 'BOOKING_CONFIRMED':
        return AppTheme.secondary;
      case 'BOOKING_CANCELLED':
        return AppTheme.error;
      case 'BOOKING_REQUEST':
        return AppTheme.warning;
      case 'RIDE_STARTING':
      case 'RIDE_COMPLETED':
        return AppTheme.primary;
      default:
        return AppTheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String?;
    final message = notification['message'] as String? ?? '';
    final isRead = notification['isRead'] as bool? ?? true;
    final createdAt = notification['createdAt'] as String?;
    final color = _color(type);

    String timeAgo = '';
    if (createdAt != null) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = DateFormat('MMM d').format(dt);
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isRead ? AppTheme.surface : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: isRead
            ? null
            : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon(type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  if (timeAgo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint),
                    ),
                  ],
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
