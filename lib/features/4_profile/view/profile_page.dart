import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/glass_container.dart';
import '../cubit/profile_cubit.dart';
import '../../0_splash/view/onboarding_page.dart';
import '../../1_provisioning/view/provision_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(
        context.read<StorageService>(),
        context.read<ApiService>(),
      ),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  Future<List<dynamic>>? _subscriptionsFuture;
  Future<List<dynamic>>? _devicesFuture;
  Future<Map<String, bool>>? _deviceStatusFuture;

  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    _nameController = TextEditingController(text: storage.getUserName() ?? '');
    _phoneController = TextEditingController(
      text: storage.getUserPhone() ?? '',
    );
    _cityController = TextEditingController(text: storage.getUserCity() ?? '');

    final userId = storage.getUserIdFromDB();
    if (userId != null) {
      _subscriptionsFuture = context.read<ApiService>().getMySubscription(
        userId,
      );
      _devicesFuture = context.read<ApiService>().getMyDevices(userId).then((
        devices,
      ) {
        // Ambil semua device_id lalu fetch status online/offline secara paralel
        final ids = devices
            .map((d) => d['device_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        if (ids.isNotEmpty) {
          _deviceStatusFuture = context.read<ApiService>().getDeviceStatus(ids);
        } else {
          _deviceStatusFuture = Future.value({});
        }
        return devices;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong')));
      return;
    }
    context.read<ProfileCubit>().updateName(name);
  }

  void _handleLogout() {
    showAppDialog(
      context: context,
      title: 'Logout',
      content: 'Apakah Anda yakin ingin keluar? Semua data lokal akan dihapus.',
      textConfirm: 'Keluar',
      confirmColor: Colors.red,
      onConfirm: () async {
        await context.read<ProfileCubit>().logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OnboardingPage()),
            (route) => false,
          );
        }
      },
    );
  }

  void _handleContactSupport() async {
    final phoneNumber = '6283197391127'; // +62 831-9739-1127
    final message = Uri.encodeComponent(
      'Halo, saya membutuhkan bantuan mengenai aplikasi IoTernak.',
    );
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$message';

    final uri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka WhatsApp'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    }
  }

  // ================ WIDGETS ================

  Widget _buildAvatarSection() {
    final name = _nameController.text;
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join()
        : 'P';

    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1ABC9C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'Peternak',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _phoneController.text.isNotEmpty
                ? _phoneController.text
                : 'Belum ada nomor',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (_cityController.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _cityController.text,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil Pengguna',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _profileField(
            controller: _nameController,
            label: 'Nama Lengkap',
            icon: Icons.person_outline,
            readOnly: false,
          ),
          const SizedBox(height: 14),
          _profileField(
            controller: _phoneController,
            label: 'Nomor Telepon',
            icon: Icons.phone_android_outlined,
            readOnly: true,
          ),
          const SizedBox(height: 14),
          _profileField(
            controller: _cityController,
            label: 'Kota/Kabupaten',
            icon: Icons.location_city_outlined,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: GoogleFonts.inter(
            color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly
                ? Colors.grey.shade100
                : Colors.white.withOpacity(0.8),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesSection() {
    if (_devicesFuture == null) return const SizedBox.shrink();

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Perangkat Saya',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProvisionPage()),
                  ).then((_) {
                    setState(() {
                      final userId = context
                          .read<StorageService>()
                          .getUserIdFromDB();
                      if (userId != null) {
                        _devicesFuture = context
                            .read<ApiService>()
                            .getMyDevices(userId);
                      }
                    });
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<dynamic>>(
            future: Future.wait([
              _devicesFuture ?? Future.value([]),
              _subscriptionsFuture ?? Future.value([]),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              final data = snapshot.data ?? [[], []];
              final devices = data[0] as List<dynamic>;
              final subscriptions = data[1] as List<dynamic>;

              if (devices.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Belum ada perangkat yang ditambahkan',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return FutureBuilder<Map<String, bool>>(
                future: _deviceStatusFuture ?? Future.value({}),
                builder: (context, statusSnap) {
                  final statusMap = statusSnap.data ?? {};
                  return Column(
                    children: devices.map((d) {
                      final type = d['type']?.toString().toLowerCase() ?? '';
                      final deviceId = d['device_id']?.toString() ?? '';
                      // Status real: gunakan API device-status, fallback ke false (offline)
                      final isOnline = statusMap[deviceId] ?? false;
                      final isPakan =
                          type.contains('pakan') || type.contains('feeder');
                      final deviceName = isPakan ? 'IoPakan' : 'IoPeka';
                      final assetPath = isPakan
                          ? 'assets/icon/iopakan.png'
                          : 'assets/icon/iopeka.png';

                      // Cari data langganan berdasarkan device_id
                      final sub = subscriptions
                          .cast<Map<String, dynamic>?>()
                          .firstWhere(
                            (s) =>
                                s != null &&
                                s['device_id']?.toString() == deviceId,
                            orElse: () => null,
                          );

                      final expired = sub != null && sub['expired_date'] != null
                          ? sub['expired_date'].toString().split('T')[0]
                          : '-';
                      final duration = sub != null
                          ? '${sub['duration'] ?? '-'} Bulan'
                          : '-';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    assetPath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          deviceName,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        StatusChip(
                                          label: isOnline
                                              ? 'Online'
                                              : 'Offline',
                                          color: isOnline
                                              ? AppColors.statusGood
                                              : AppColors.statusDanger,
                                          icon: Icons.circle,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timelapse_outlined,
                                          size: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          duration,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.event_outlined,
                                          size: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Exp: $expired',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _subDetail({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ================ BUILD ================

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.statusGood,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {}); // Refresh avatar initials
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.statusDanger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.homeBackground),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, bottomPad + 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Profil Saya',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                _buildAvatarSection(),
                const SizedBox(height: 20),

                _buildEditForm(),
                const SizedBox(height: 16),

                // Save Button
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    return GestureDetector(
                      onTap: (state is ProfileLoading) ? null : _saveProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF1ABC9C)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: (state is ProfileLoading)
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Simpan Perubahan',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                _buildDevicesSection(),
                const SizedBox(height: 24),

                // WhatsApp Support Button
                GestureDetector(
                  onTap: _handleContactSupport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF25D366).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Hubungi Bantuan',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Logout
                GestureDetector(
                  onTap: _handleLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.statusDanger.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.statusDanger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppColors.statusDanger,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Keluar Akun',
                          style: GoogleFonts.inter(
                            color: AppColors.statusDanger,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
