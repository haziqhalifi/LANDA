import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:disaster_resilience_ai/models/report_model.dart';
import 'package:disaster_resilience_ai/services/api_service.dart';
import 'package:disaster_resilience_ai/ui/submit_report_page.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key, required this.accessToken});

  final String accessToken;

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  static const _filters = ['All', 'flood', 'blocked_road', 'landslide', 'medical_emergency'];
  static const _filterLabels = ['All', 'Flood', 'Road Block', 'Landslide', 'Medical'];
  static const _statusFilters = ['All', 'Verified', 'Pending', 'Most Vouched'];

  final ApiService _api = ApiService();
  List<Report> _reports = [];
  bool _loading = true;
  String? _error;
  String _activeFilter = 'All';
  String _statusFilter = 'All';
  double _userLat = 3.8077;
  double _userLon = 103.3260;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.deniedForever && perm != LocationPermission.denied) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
          );
          _userLat = pos.latitude;
          _userLon = pos.longitude;
        }
      }
    } catch (_) {
      // Keep fallback coords
    }
    if (mounted) _fetchReports();
  }

  Future<void> _vouchReport(Report report) async {
    try {
      if (report.currentUserVouched) {
        await _api.unvouchReport(widget.accessToken, report.id);
      } else {
        await _api.vouchReport(widget.accessToken, report.id);
      }
      _fetchReports();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.contains('Already vouched') ? 'You already vouched for this report' : msg),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchNearbyReports(
        accessToken: widget.accessToken,
        latitude: _userLat,
        longitude: _userLon,
        radiusKm: 50,
      );
      final list = ReportList.fromJson(data);
      if (mounted) {
        setState(() {
          _reports = list.reports;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  List<Report> get _filtered {
    var visible = _reports.where((r) => r.status != 'rejected').toList();
    if (_activeFilter != 'All') {
      visible = visible.where((r) => r.reportType == _activeFilter).toList();
    }
    if (_statusFilter == 'Verified') {
      visible = visible.where((r) => r.status == 'validated').toList();
    } else if (_statusFilter == 'Pending') {
      visible = visible.where((r) => r.status == 'pending').toList();
    } else if (_statusFilter == 'Most Vouched') {
      visible.sort((a, b) => b.vouchCount.compareTo(a.vouchCount));
    }
    return visible;
  }

  // Stats computed from live data
  int get _activeCount => _reports.where((r) => r.status == 'validated').length;
  int get _criticalCount => _reports.where((r) => r.vouchCount >= 5).length;
  int get _resolvedCount => _reports.where((r) => r.status == 'resolved').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        color: const Color(0xFF2E7D32),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Community Reports',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Real-time situational awareness from your community',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _buildStatCard('$_activeCount', 'Active\nReports', Colors.orange[700]!, Colors.orange[50]!),
                  const SizedBox(width: 12),
                  _buildStatCard('$_criticalCount', 'Critical\nAlerts', Colors.red[700]!, Colors.red[50]!),
                  const SizedBox(width: 12),
                  _buildStatCard('$_resolvedCount', 'Resolved\nToday', const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
                ],
              ),
              const SizedBox(height: 24),

              // Type filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_filters.length, (i) {
                    final isActive = _activeFilter == _filters[i];
                    return Padding(
                      padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeFilter = _filters[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF2E7D32) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? const Color(0xFF2E7D32) : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            _filterLabels[i],
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),

              // Status filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusFilters.map((f) {
                    final isActive = _statusFilter == f;
                    final color = f == 'Verified'
                        ? Colors.green
                        : f == 'Pending'
                            ? Colors.orange
                            : f == 'Most Vouched'
                                ? Colors.blue
                                : const Color(0xFF64748B);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _statusFilter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? color : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: isActive ? color : Colors.grey[600],
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Live feed label
              const Row(
                children: [
                  Icon(Icons.circle, color: Colors.red, size: 10),
                  SizedBox(width: 6),
                  Text(
                    'LIVE FEED',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Report list body
              _buildBody(),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmitReportPage(accessToken: widget.accessToken),
                      ),
                    );
                    _fetchReports(); // refresh after returning
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Submit New Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.wifi_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Could not load reports',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final visible = _filtered;

    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.green[300]),
              const SizedBox(height: 12),
              Text(
                'No reports in your area',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Pull to refresh or submit one if you see something.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: visible.map(_buildReportItem).toList(),
    );
  }

  Widget _buildReportItem(Report report) {
    final typeIcon = _iconFor(report.reportType);
    final typeColor = _colorFor(report.reportType);
    final timeAgo = _timeAgo(report.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${report.typeLabel} — ${report.locationName}',
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _buildSeverityBadge(report.severityLabel),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  report.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(timeAgo, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    if (report.distanceKm != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.near_me, size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(
                        '${report.distanceKm!.toStringAsFixed(1)} km',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _vouchReport(report),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: report.currentUserVouched ? Colors.blue[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: report.currentUserVouched ? Colors.blue[300]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              report.currentUserVouched ? Icons.thumb_up : Icons.thumb_up_outlined,
                              size: 13,
                              color: report.currentUserVouched ? Colors.blue[700] : Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              report.vouchCount > 0
                                  ? '${report.vouchCount} vouch${report.vouchCount == 1 ? '' : 'es'}'
                                  : 'Vouch',
                              style: TextStyle(
                                fontSize: 11,
                                color: report.currentUserVouched ? Colors.blue[700] : Colors.grey[500],
                                fontWeight: report.currentUserVouched ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (report.vulnerablePerson) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.priority_high, size: 13, color: Colors.red[400]),
                      Text(
                        'Priority',
                        style: TextStyle(color: Colors.red[400], fontSize: 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                _buildStatusBadge(report.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final config = switch (status) {
      'validated' => (Icons.verified, Colors.green[700]!, Colors.green[50]!, 'Verified'),
      'resolved'  => (Icons.check_circle, Colors.grey[600]!, Colors.grey[100]!, 'Resolved'),
      'pending'   => (Icons.hourglass_top, Colors.orange[700]!, Colors.orange[50]!, 'Pending Review'),
      _           => (Icons.hourglass_top, Colors.orange[700]!, Colors.orange[50]!, 'Pending Review'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(config.$1, size: 11, color: config.$2),
        const SizedBox(width: 3),
        Text(
          config.$4,
          style: TextStyle(color: config.$2, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSeverityBadge(String label) {
    final color = label == 'HIGH'
        ? Colors.red
        : label == 'MEDIUM'
            ? Colors.orange
            : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildStatCard(String count, String label, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'flood':
        return Icons.water_drop;
      case 'blocked_road':
        return Icons.block;
      case 'landslide':
        return Icons.landscape;
      case 'medical_emergency':
        return Icons.medical_services_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'flood':
        return Colors.blue[700]!;
      case 'blocked_road':
        return Colors.orange[700]!;
      case 'landslide':
        return Colors.brown[700]!;
      case 'medical_emergency':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
