import 'package:flutter/material.dart';
import 'package:disaster_resilience_ai/models/warning_model.dart';

class EmergencyAlertPage extends StatelessWidget {
  const EmergencyAlertPage({super.key, this.warning});

  /// If a real warning is passed, display its data.
  /// Otherwise, show a fallback "no active warnings" state.
  final Warning? warning;

  @override
  Widget build(BuildContext context) {
    if (warning == null) {
      return _buildNoWarningState(context);
    }
    return _buildWarningState(context, warning!);
  }

  /// Shown when no nearby warnings — a calm "all clear" view.
  Widget _buildNoWarningState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Warning Details',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF2E7D32),
                  size: 72,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'All Clear',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No active warnings near your location.\nStay safe and prepared.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'BACK TO DASHBOARD',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full emergency alert view with real warning data.
  Widget _buildWarningState(BuildContext context, Warning w) {
    final bgColor = _alertColor(w.alertLevel);
    final timeAgo = _timeAgo(w.createdAt);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency Alert',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showWarningDetails(context, w),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _alertIcon(w.alertLevel),
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            // Alert Level Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${w.alertLevel.displayName} • ${w.hazardType.displayName.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              w.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              w.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoChip(Icons.access_time, timeAgo),
                _buildInfoChip(Icons.radar, '${w.radiusKm} km radius'),
                _buildInfoChip(Icons.source, w.source),
              ],
            ),
            const SizedBox(height: 24),
            // Map Card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9).withAlpha(204),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    // Danger zone overlay
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: bgColor.withAlpha(51),
                          shape: BoxShape.circle,
                          border: Border.all(color: bgColor.withAlpha(128), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, color: bgColor, size: 32),
                            const SizedBox(height: 4),
                            Text(
                              '${w.radiusKm} km',
                              style: TextStyle(
                                color: bgColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Affected Area',
                              style: TextStyle(
                                color: bgColor.withAlpha(178),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Safe Zone
                    Positioned(
                      top: 30,
                      right: 30,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'SAFE ZONE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // User location
                    Positioned(
                      bottom: 40,
                      left: 40,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(77),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    // Coordinates overlay
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(128),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${w.location.latitude.toStringAsFixed(4)}, ${w.location.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: bgColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  w.alertLevel == AlertLevel.evacuate
                      ? Icons.directions_run
                      : Icons.navigation,
                  size: 28,
                ),
                label: Text(
                  w.alertLevel == AlertLevel.evacuate
                      ? 'EVACUATE NOW'
                      : 'VIEW SAFE ROUTES',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              w.alertLevel == AlertLevel.evacuate
                  ? 'TAP FOR TURN-BY-TURN NAVIGATION'
                  : 'TAP TO VIEW RECOMMENDED SAFE ROUTES',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _alertColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.advisory:
        return Colors.blue[700]!;
      case AlertLevel.observe:
        return Colors.amber[700]!;
      case AlertLevel.warning:
        return Colors.deepOrange[700]!;
      case AlertLevel.evacuate:
        return const Color(0xFFD32F2F);
    }
  }

  IconData _alertIcon(AlertLevel level) {
    switch (level) {
      case AlertLevel.advisory:
        return Icons.info_outline;
      case AlertLevel.observe:
        return Icons.visibility_outlined;
      case AlertLevel.warning:
        return Icons.warning_amber_rounded;
      case AlertLevel.evacuate:
        return Icons.directions_run;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showWarningDetails(BuildContext context, Warning w) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Warning Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ID', w.id.substring(0, 8)),
            _buildDetailRow('Hazard', w.hazardType.displayName),
            _buildDetailRow('Level', w.alertLevel.displayName),
            _buildDetailRow('Source', w.source),
            _buildDetailRow('Radius', '${w.radiusKm} km'),
            _buildDetailRow(
              'Coordinates',
              '${w.location.latitude.toStringAsFixed(4)}, ${w.location.longitude.toStringAsFixed(4)}',
            ),
            _buildDetailRow('Created', w.createdAt.toLocal().toString().substring(0, 19)),
            _buildDetailRow('Status', w.active ? 'Active' : 'Resolved'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
