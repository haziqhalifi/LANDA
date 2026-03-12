import 'package:flutter/material.dart';

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0F140F) : const Color(0xFFF0F2F5);
    final appBarBg = isDark ? const Color(0xFF1B251B) : Colors.white;
    final titleColor = isDark
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF1E293B);
    final divider = isDark
        ? const Color(0xFF334236)
        : const Color(0xFF2D5927).withAlpha(26);
    final sectionTitle = isDark
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF1E293B);
    final tipBg = isDark ? const Color(0xFF3A2F16) : const Color(0xFFFFF8E1);
    final tipBorder = isDark ? const Color(0xFF7C6630) : Colors.amber[200]!;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Emergency Contacts',
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: divider,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SOS Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[700]!, Colors.red[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.sos, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Emergency SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to alert all emergency contacts\nand nearest rescue teams',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ACTIVATE SOS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Official Emergency Numbers
            Text(
              'Official Emergency Lines',
              style: TextStyle(
                color: sectionTitle,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildContactCard(
              context: context,
              icon: Icons.local_police,
              iconColor: Colors.blue[700]!,
              bgColor: Colors.blue[50]!,
              name: 'Police (PDRM)',
              phone: '999',
              subtitle: 'National Emergency Line',
            ),
            _buildContactCard(
              context: context,
              icon: Icons.local_fire_department,
              iconColor: Colors.red[700]!,
              bgColor: Colors.red[50]!,
              name: 'Fire & Rescue',
              phone: '994',
              subtitle: 'Bomba Malaysia',
            ),
            _buildContactCard(
              context: context,
              icon: Icons.medical_services,
              iconColor: const Color(0xFF2E7D32),
              bgColor: const Color(0xFFE8F5E9),
              name: 'Ambulance',
              phone: '999',
              subtitle: 'Medical Emergency',
            ),
            _buildContactCard(
              context: context,
              icon: Icons.flood,
              iconColor: Colors.orange[700]!,
              bgColor: Colors.orange[50]!,
              name: 'NADMA Hotline',
              phone: '03-8064 2400',
              subtitle: 'National Disaster Management',
            ),
            _buildContactCard(
              context: context,
              icon: Icons.water,
              iconColor: Colors.teal[700]!,
              bgColor: Colors.teal[50]!,
              name: 'DID Flood Info',
              phone: '1800-88-6722',
              subtitle: 'Dept. of Irrigation & Drainage',
            ),

            const SizedBox(height: 28),

            // Local Community Contacts
            Text(
              'Local Community Contacts',
              style: TextStyle(
                color: sectionTitle,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildContactCard(
              context: context,
              icon: Icons.person,
              iconColor: const Color(0xFF2E7D32),
              bgColor: const Color(0xFFE8F5E9),
              name: 'Ketua Kampung - En. Razak',
              phone: '+60 12-345 6789',
              subtitle: 'Village Chief, Kg. Melayu',
            ),
            _buildContactCard(
              context: context,
              icon: Icons.groups,
              iconColor: Colors.purple[700]!,
              bgColor: Colors.purple[50]!,
              name: 'JPAM Volunteer Team',
              phone: '+60 13-987 6543',
              subtitle: 'Civil Defence Volunteers',
            ),
            _buildContactCard(
              context: context,
              icon: Icons.local_hospital,
              iconColor: Colors.red[700]!,
              bgColor: Colors.red[50]!,
              name: 'Klinik Kesihatan Kuantan',
              phone: '+60 9-573 3333',
              subtitle: 'Nearest Health Clinic',
            ),

            const SizedBox(height: 28),

            // Quick Tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tipBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tipBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tip',
                          style: TextStyle(
                            color: isDark ? Colors.amber[200] : Colors.amber[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Save these contacts offline. SMS fallback works when there is no internet.',
                          style: TextStyle(
                            color: isDark ? Colors.amber[100] : Colors.amber[800],
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String name,
    required String phone,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B251B) : Colors.white;
    final cardTitle = isDark
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF1E293B);
    final subtitleColor = isDark
        ? const Color(0xFF9AA79B)
        : Colors.grey[500]!;
    final phoneColor = isDark ? const Color(0xFF9EDB94) : const Color(0xFF2E7D32);
    final callChipBg = isDark
        ? const Color(0xFF2D5927).withAlpha(56)
        : const Color(0xFFE8F5E9);
    final iconChipBg = isDark ? iconColor.withAlpha(48) : bgColor;
    final iconChipBorder = isDark
        ? iconColor.withAlpha(120)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(64)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconChipBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconChipBorder),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: cardTitle,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                phone,
                style: TextStyle(
                  color: phoneColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: callChipBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.phone,
                  color: phoneColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
