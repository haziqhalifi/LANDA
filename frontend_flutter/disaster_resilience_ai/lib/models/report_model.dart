/// Models for community flood/incident reports.

class Report {
  final String id;
  final String userId;
  final String reportType;
  final String description;
  final String locationName;
  final double latitude;
  final double longitude;
  final String status;
  final bool vulnerablePerson;
  final int vouchCount;
  final int helpfulCount;
  final double? distanceKm;
  final bool currentUserVouched;
  final bool currentUserHelpful;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Report({
    required this.id,
    required this.userId,
    required this.reportType,
    required this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.vulnerablePerson,
    required this.vouchCount,
    required this.helpfulCount,
    this.distanceKm,
    required this.currentUserVouched,
    required this.currentUserHelpful,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reportType: json['report_type'] as String,
      description: json['description'] as String,
      locationName: json['location_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String,
      vulnerablePerson: json['vulnerable_person'] as bool? ?? false,
      vouchCount: json['vouch_count'] as int? ?? 0,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      currentUserVouched: json['current_user_vouched'] as bool? ?? false,
      currentUserHelpful: json['current_user_helpful'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get typeLabel {
    switch (reportType) {
      case 'flood':
        return 'Water Rising';
      case 'blocked_road':
        return 'Road Blocked';
      case 'landslide':
        return 'Landslide';
      case 'medical_emergency':
        return 'Medical Emergency';
      default:
        return reportType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get severityLabel {
    if (vouchCount >= 5) return 'HIGH';
    if (vouchCount >= 2) return 'MEDIUM';
    return 'LOW';
  }
}

class ReportList {
  final List<Report> reports;
  final int total;

  const ReportList({required this.reports, required this.total});

  factory ReportList.fromJson(Map<String, dynamic> json) {
    final list = (json['reports'] as List<dynamic>? ?? [])
        .map((e) => Report.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReportList(reports: list, total: json['total'] as int? ?? list.length);
  }
}
