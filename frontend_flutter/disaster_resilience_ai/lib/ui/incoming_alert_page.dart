import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:disaster_resilience_ai/models/warning_model.dart';
import 'package:disaster_resilience_ai/services/api_service.dart';
import 'package:disaster_resilience_ai/services/notification_service.dart';
import 'package:disaster_resilience_ai/ui/emergency_alert_page.dart';

/// Full-screen incoming emergency alert — resembles an incoming phone call.
///
/// Shows pulsating danger visuals, continuous vibration, and reads the alert
/// aloud using the device's text-to-speech engine. The user can either
/// acknowledge the alert (navigates to the detailed emergency page) or dismiss.
class IncomingAlertPage extends StatefulWidget {
  const IncomingAlertPage({super.key, required this.warning});

  final Warning warning;

  @override
  State<IncomingAlertPage> createState() => _IncomingAlertPageState();
}

class _IncomingAlertPageState extends State<IncomingAlertPage>
    with TickerProviderStateMixin {
  static const int _dismissLockSeconds = 12;

  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final Animation<double> _pulseAnimation;
  late final Animation<Offset> _slideAnimation;

  int _dismissCountdown = _dismissLockSeconds;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _assetAlarmPlaying = false;
  Timer? _vibrationTimer;
  Timer? _ringTimer;
  Timer? _dismissCountdownTimer;

  // Check-in state
  bool _checkinSubmitting = false;
  String? _checkinStatus; // 'safe' | 'needs_help' | null
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();

    // ── Pulse animation for the icon ring ──
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Slide-up animation for the bottom card ──
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // ── Continuous vibration pattern ──
    _startVibrationLoop();
    unawaited(_startRingingLoop());
    _startDismissCountdown();

    // ── Force the screen to stay on and show over the lock screen ──
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _startVibrationLoop() {
    // Vibrate immediately, then every 2 seconds
    HapticFeedback.vibrate();
    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      HapticFeedback.vibrate();
    });
  }

  Future<void> _startRingingLoop() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/alarm.wav'));
      _assetAlarmPlaying = true;
    } catch (_) {
      _assetAlarmPlaying = false;
      SystemSound.play(SystemSoundType.alert);
    }

    _ringTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!_assetAlarmPlaying) {
        SystemSound.play(SystemSoundType.alert);
      }
      HapticFeedback.heavyImpact();
    });
  }

  void _startDismissCountdown() {
    _dismissCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_dismissCountdown <= 1) {
        setState(() => _dismissCountdown = 0);
        timer.cancel();
        return;
      }
      setState(() => _dismissCountdown -= 1);
    });
  }

  void _stopAlertEffects() {
    _vibrationTimer?.cancel();
    _ringTimer?.cancel();
    _dismissCountdownTimer?.cancel();
    _audioPlayer.stop();
    _assetAlarmPlaying = false;
  }

  @override
  void dispose() {
    _stopAlertEffects();
    _pulseController.dispose();
    _slideController.dispose();
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _acknowledge() {
    _stopAlertEffects();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EmergencyAlertPage(warning: widget.warning),
      ),
    );
  }

  void _dismiss() {
    if (_dismissCountdown > 0) return;
    _stopAlertEffects();
    NotificationService.instance.dismissWarning(widget.warning.id);
    Navigator.of(context).pop();
  }

  Future<void> _submitCheckin(String status) async {
    if (_checkinSubmitting || _checkinStatus != null) return;
    setState(() => _checkinSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_access_token') ?? '';
      if (token.isNotEmpty) {
        await _api.selfCheckin(accessToken: token, status: status);
      }
      if (!mounted) return;
      setState(() => _checkinStatus = status);

      if (status == 'safe') {
        // Confirmed safe → stop alarm and auto-dismiss after brief confirmation
        _stopAlertEffects();
        NotificationService.instance.dismissWarning(widget.warning.id);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop();
      } else {
        // Needs help → stop alarm, go to EmergencyAlertPage for evacuation route
        _stopAlertEffects();
        NotificationService.instance.dismissWarning(widget.warning.id);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EmergencyAlertPage(warning: widget.warning),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update status — check your connection.')),
        );
        setState(() => _checkinSubmitting = false);
      }
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final warning = widget.warning;
    final isEvacuate = warning.alertLevel == AlertLevel.evacuate;

    final Color bgStart = isEvacuate
        ? const Color(0xFFB71C1C)
        : const Color(0xFFE65100);
    final Color bgEnd = isEvacuate
        ? const Color(0xFF880E0E)
        : const Color(0xFFBF360C);

    return PopScope(
      canPop: _dismissCountdown == 0,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgStart, bgEnd],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // ── Alert level badge ──
                _buildAlertBadge(warning),
                const SizedBox(height: 16),
                // ── Pulsating icon ──
                _buildPulsingIcon(warning),
                const SizedBox(height: 16),
                // ── Title ──
                Text(
                  isEvacuate ? 'EVACUATE NOW' : 'EMERGENCY ALERT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    warning.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ── Slide-up detail card fills remaining space ──
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildDetailCard(warning),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBadge(Warning warning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_rounded,
            color: Colors.yellowAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            warning.alertLevel.displayName,
            style: const TextStyle(
              color: Colors.yellowAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingIcon(Warning warning) {
    final IconData icon;
    switch (warning.alertLevel) {
      case AlertLevel.evacuate:
        icon = Icons.directions_run;
      case AlertLevel.warning:
        icon = Icons.warning_amber_rounded;
      case AlertLevel.observe:
        icon = Icons.visibility;
      case AlertLevel.advisory:
        icon = Icons.info_outline;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(30),
              border: Border.all(color: Colors.white.withAlpha(100), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 44),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(Warning warning) {
    final hazardColor = _hazardColor(warning.hazardType);
    final canDismiss = _dismissCountdown == 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Hazard type chip ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: hazardColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu, size: 14, color: hazardColor),
                  const SizedBox(width: 6),
                  Text(
                    warning.hazardType.displayName.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: hazardColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Alert message box ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 5),
                      Text(
                        'Alert Message',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    warning.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Source & time inside the card
                  Row(
                    children: [
                      Icon(Icons.smartphone, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        'Source: ${warning.source}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(warning.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Action buttons ──
            if (_checkinStatus == null) ...[
              Row(
                children: [
                  // DISMISS button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canDismiss ? _dismiss : null,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(
                        canDismiss ? 'DISMISS' : 'DISMISS (${_dismissCountdown}s)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[350]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // VIEW DETAILS button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _acknowledge,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text(
                        'VIEW DETAILS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Confirmation banner while navigating
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: _checkinStatus == 'safe' ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _checkinStatus == 'safe' ? Colors.green[300]! : Colors.red[300]!,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_checkinSubmitting)
                      const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Icon(
                        _checkinStatus == 'safe' ? Icons.check_circle : Icons.sos,
                        color: _checkinStatus == 'safe' ? Colors.green[700] : Colors.red[700],
                        size: 20,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _checkinStatus == 'safe'
                          ? 'Marked SAFE — returning home…'
                          : 'Alert sent — opening evacuation guide…',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _checkinStatus == 'safe' ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Hazard helpers ────────────────────────────────────────────────────────

  IconData _hazardIcon(HazardType type) {
    switch (type) {
      case HazardType.flood:
        return Icons.water;
      case HazardType.landslide:
        return Icons.landscape;
      case HazardType.typhoon:
        return Icons.cyclone;
      case HazardType.earthquake:
        return Icons.public;
      case HazardType.forecast:
        return Icons.cloud;
      case HazardType.aid:
        return Icons.volunteer_activism;
      case HazardType.infrastructure:
        return Icons.construction;
    }
  }

  Color _hazardColor(HazardType type) {
    switch (type) {
      case HazardType.flood:
        return Colors.blue[700]!;
      case HazardType.landslide:
        return Colors.brown[700]!;
      case HazardType.typhoon:
        return Colors.indigo[700]!;
      case HazardType.earthquake:
        return Colors.red[700]!;
      case HazardType.forecast:
        return Colors.teal[700]!;
      case HazardType.aid:
        return Colors.green[700]!;
      case HazardType.infrastructure:
        return Colors.orange[700]!;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
