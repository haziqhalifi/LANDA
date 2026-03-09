import 'package:flutter/material.dart';
import 'package:disaster_resilience_ai/models/profile_model.dart';
import 'package:disaster_resilience_ai/services/api_service.dart';
import 'package:disaster_resilience_ai/theme/app_theme.dart';
import 'package:disaster_resilience_ai/ui/edit_profile_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.accessToken,
    required this.username,
    required this.email,
    required this.onLogout,
  });

  final String accessToken;
  final String username;
  final String email;
  final VoidCallback onLogout;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ApiService _api = ApiService();
  UserProfile? _profile;
  bool _loading = true;
  String? _error;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.fetchProfile(widget.accessToken);
      if (mounted) {
        setState(() {
          _profile = UserProfile.fromJson(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          accessToken: widget.accessToken,
          profile: _profile ?? UserProfile(userId: ''),
        ),
      ),
    );

    if (result == true) {
      _fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF2D5927);
    final theme = Theme.of(context);
    final themeController = AppThemeScope.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = theme.scaffoldBackgroundColor;
    final surface = isDark ? const Color(0xFF1B251B) : Colors.white;
    final subtleSurface = isDark
        ? const Color(0xFF233124)
        : const Color(0xFFF1F5F9);
    final border = isDark ? const Color(0xFF334236) : const Color(0xFFE2E8F0);
    final secondaryText = isDark
        ? const Color(0xFFA7B5A8)
        : const Color(0xFF64748B);
    final tertiaryText = isDark
        ? const Color(0xFF8A9A8B)
        : const Color(0xFF94A3B8);
    final titleColor = theme.colorScheme.onSurface;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading profile: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final profile = _profile!;
    final displayName = profile.fullName?.isNotEmpty == true
        ? profile.fullName!
        : widget.username;
    final emergencyName = profile.emergencyContactName ?? 'Emergency Contact';
    final emergencyLabel = [
      if (profile.emergencyContactRelationship?.isNotEmpty == true)
        profile.emergencyContactRelationship!,
      if (profile.emergencyContactPhone?.isNotEmpty == true)
        profile.emergencyContactPhone!,
    ].join(' • ');
    final resilienceId =
        'RAI-${profile.userId.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase().padLeft(4, '0').substring(0, 4)}';

    return Scaffold(
      backgroundColor: pageBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    'Your Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: _editProfile,
                    icon: const Icon(Icons.settings_outlined),
                    color: isDark
                        ? const Color(0xFFA7B5A8)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withAlpha(38),
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFFE6EFE5),
                          child: Text(
                            widget.username.isNotEmpty
                                ? widget.username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: primary,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: InkWell(
                          onTap: _editProfile,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.location_on, size: 15, color: primary),
                      SizedBox(width: 4),
                      Text(
                        'Dengkil, Selangor',
                        style: TextStyle(
                          color: primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Resilience ID: $resilienceId',
                      style: const TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withAlpha(46),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Preparedness',
                                style: TextStyle(
                                  color: Color(0xCCE8F5E9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.verified, color: Colors.white, size: 14),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '85%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: 0.85,
                            minHeight: 5,
                            color: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Contacts',
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.emergency, color: primary, size: 14),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '3 Active',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Last verified: 2 days ago',
                          style: TextStyle(color: tertiaryText, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add New',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: primary,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildContactTile(
              icon: Icons.person,
              title: emergencyName,
              subtitle: emergencyLabel.isNotEmpty
                  ? emergencyLabel
                  : 'Primary contact • Not available',
              surface: surface,
              subtleSurface: subtleSurface,
              border: border,
              secondaryText: secondaryText,
              tertiaryText: tertiaryText,
            ),
            const SizedBox(height: 10),
            _buildContactTile(
              icon: Icons.health_and_safety,
              title: 'Local Community Center',
              subtitle: 'Medical support • Emergency line',
              surface: surface,
              subtleSurface: subtleSurface,
              border: border,
              secondaryText: secondaryText,
              tertiaryText: tertiaryText,
            ),
            const SizedBox(height: 24),
            const Text(
              'Preparedness Checklist',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary.withAlpha(12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withAlpha(28)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChecklistItem(
                    checked: true,
                    title: 'Emergency Kit Ready',
                    subtitle:
                        'Water, non-perishables, and first-aid kit verified.',
                  ),
                  SizedBox(height: 14),
                  _ChecklistItem(
                    checked: true,
                    title: 'Offline Maps Downloaded',
                    subtitle: 'Regional maps available without internet.',
                  ),
                  SizedBox(height: 14),
                  _ChecklistItem(
                    checked: false,
                    title: 'Document Backup',
                    subtitle:
                        'Scan and upload identity documents for security.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Settings',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingItem(
              icon: Icons.notifications,
              'Notifications',
              subtitle: 'Push & SMS alerts',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) =>
                    setState(() => _notificationsEnabled = value),
                activeTrackColor: primary.withAlpha(120),
                activeThumbColor: primary,
              ),
            ),
            _buildSettingItem(
              icon: Icons.translate,
              'Language',
              subtitle: 'English (Bahasa available)',
            ),
            _buildSettingItem(
              icon: Icons.dark_mode,
              'Dark Mode',
              trailing: Switch(
                value: themeController.isDarkMode,
                onChanged: (value) {
                  themeController.setDarkMode(value);
                },
                activeTrackColor: primary.withAlpha(120),
                activeThumbColor: primary,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: widget.onLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFFFF1F2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFDC2626)),
                    SizedBox(width: 10),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Text(
                'Medical: Blood ${profile.bloodType ?? "N/A"} • '
                'Allergies: ${profile.allergies.isEmpty ? "None" : profile.allergies}',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryText,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Resilience AI v1.0.0',
                style: TextStyle(
                  color: isDark ? const Color(0xFF8A9A8B) : Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color surface,
    required Color subtleSurface,
    required Color border,
    required Color secondaryText,
    required Color tertiaryText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: subtleSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: secondaryText, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: tertiaryText),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title, {
    required IconData icon,
    String? subtitle,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1B251B) : Colors.white;
    final iconColor = isDark
        ? const Color(0xFFA7B5A8)
        : const Color(0xFF475569);
    final subtitleColor = isDark
        ? const Color(0xFFA7B5A8)
        : const Color(0xFF64748B);
    final tertiaryText = isDark
        ? const Color(0xFF8A9A8B)
        : const Color(0xFF94A3B8);

    return InkWell(
      onTap: trailing == null ? _editProfile : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: tertiaryText),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.checked,
    required this.title,
    required this.subtitle,
  });

  final bool checked;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF2D5927);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            checked ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 19,
            color: checked ? primary : const Color(0xFFCBD5E1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: checked
                      ? (isDark
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFF0F172A))
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: checked
                      ? (isDark
                            ? const Color(0xFFA7B5A8)
                            : const Color(0xFF64748B))
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
