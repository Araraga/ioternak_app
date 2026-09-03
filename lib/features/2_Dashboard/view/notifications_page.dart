import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/glass_container.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => NotificationCubit(
            api: context.read<ApiService>(),
            storage: context.read<StorageService>(),
          )..fetchNotifications(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  Color _typeColor(String? type) {
    switch (type) {
      case 'temperature':
        return AppColors.statusWarning;
      case 'gas':
        return AppColors.statusDanger;
      case 'weather':
        return AppColors.statusInfo;
      case 'feed':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'temperature':
        return Icons.thermostat;
      case 'gas':
        return Icons.cloud_queue;
      case 'weather':
        return Icons.wb_cloudy_outlined;
      case 'feed':
        return Icons.set_meal_outlined;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'temperature':
        return 'Suhu';
      case 'gas':
        return 'Gas/Amonia';
      case 'weather':
        return 'Cuaca';
      case 'feed':
        return 'Pakan';
      case 'system':
        return 'Sistem';
      default:
        return 'Notifikasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          ),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    // Mark all as read
                  },
                  child: Text(
                    'Tandai Semua',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.homeBackground),
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading || state is NotificationInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is NotificationError) {
              return _buildEmpty(
                icon: Icons.wifi_off_rounded,
                title: 'Gagal memuat notifikasi',
                subtitle: state.message,
              );
            }

            if (state is NotificationLoaded) {
              if (state.notifications.isEmpty) {
                return _buildEmpty(
                  icon: Icons.notifications_none_rounded,
                  title: 'Belum ada notifikasi',
                  subtitle: 'Notifikasi cuaca, suhu, dan gas akan muncul di sini',
                );
              }

              // Group by type
              final Map<String, List<dynamic>> grouped = {};
              for (var n in state.notifications) {
                final type = n['type'] ?? 'system';
                grouped.putIfAbsent(type, () => []).add(n);
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                  20,
                  40,
                ),
                children: grouped.entries.map((entry) {
                  return _buildGroup(context, entry.key, entry.value);
                }).toList(),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String type,
    List<dynamic> notifications,
  ) {
    final color = _typeColor(type);
    final icon = _typeIcon(type);
    final label = _typeLabel(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...notifications.map(
          (n) => _buildNotifItem(context, n, color, icon),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNotifItem(
    BuildContext context,
    dynamic notif,
    Color color,
    IconData icon,
  ) {
    final isRead = notif['is_read'] == true || notif['is_read'] == 1;
    final createdAt = notif['created_at'];
    String timeStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        timeStr = DateFormat('dd MMM, HH:mm', 'id_ID').format(dt);
      } catch (_) {
        timeStr = createdAt.toString();
      }
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          context.read<NotificationCubit>().markRead(notif['id'].toString());
        }
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(18),
        gradient: isRead
            ? null
            : LinearGradient(
                colors: [
                  color.withOpacity(0.08),
                  Colors.white.withOpacity(0.1),
                ],
              ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif['title'] ?? 'Notifikasi',
                    style: GoogleFonts.inter(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['body'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (timeStr.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
