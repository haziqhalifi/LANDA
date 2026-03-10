import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class AuthResult {
  final String accessToken;
  final String userId;
  final String username;
  final String email;

  const AuthResult({
    required this.accessToken,
    required this.userId,
    required this.username,
    required this.email,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthResult(
      accessToken: json['access_token'] as String,
      userId: user['id'] as String,
      username: user['username'] as String,
      email: user['email'] as String,
    );
  }
}

class ApiService {
  // ── IMPORTANT: Update BACKEND_HOST for your environment ─────────────────────
  // For Android Emulator: use '10.0.2.2'       (routes to host localhost)
  // For Real Android Device: use your PC's Wi-Fi IP (run ipconfig to find it)
  //   Current Wi-Fi IP: 10.87.52.44
  // For web browser: use 'localhost'
  // ──────────────────────────────────────────────────────────────────────────
  static const String _backendHost = '10.87.52.44'; // Real device Wi-Fi IP
  static const int _backendPort = 8000;

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$_backendPort';
    return 'http://$_backendHost:$_backendPort';
  }

  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (_) {}
    return 'Request failed with status ${response.statusCode}';
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<AuthResult> signUp({required String username, required String email, required String password}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    if (response.statusCode == 201) return AuthResult.fromJson(jsonDecode(response.body));
    throw Exception(_extractErrorMessage(response));
  }

  Future<AuthResult> signIn({required String email, required String password}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) return AuthResult.fromJson(jsonDecode(response.body));
    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> me(String accessToken) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/auth/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }

  // ── Warnings ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchNearbyWarnings({required double latitude, required double longitude}) async {
    final uri = Uri.parse('$baseUrl/api/v1/warnings/nearby/').replace(
      queryParameters: {'latitude': latitude.toString(), 'longitude': longitude.toString()},
    );
    final response = await _client.get(uri);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch nearby warnings: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> fetchWarnings({bool activeOnly = true, String? hazardType, String? alertLevel}) async {
    final params = <String, String>{'active_only': activeOnly.toString()};
    if (hazardType != null) params['hazard_type'] = hazardType;
    if (alertLevel != null) params['alert_level'] = alertLevel;
    final uri = Uri.parse('$baseUrl/api/v1/warnings').replace(queryParameters: params);
    final response = await _client.get(uri);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch warnings: ${response.statusCode}');
  }

  // ── Location & Device ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateLocation({required String accessToken, required double latitude, required double longitude}) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/v1/devices/me/location'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update location: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> registerDevice({required String accessToken, String? fcmToken, String? phoneNumber}) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/v1/devices/me/device'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({if (fcmToken != null) 'fcm_token': fcmToken, if (phoneNumber != null) 'phone_number': phoneNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to register device: ${response.statusCode}');
  }

  // ── Map ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchMapData({String? hazardType}) async {
    final params = <String, String>{};
    if (hazardType != null) params['hazard_type'] = hazardType;
    final uri = Uri.parse('$baseUrl/api/v1/risk-map').replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch map data: ${response.statusCode}');
  }

  Future<List<Map<String, double>>> fetchRoute({required double startLat, required double startLon, required double endLat, required double endLon}) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson';
    try {
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry']['coordinates'] as List;
          return geometry.map((point) => {'lat': (point[1] as num).toDouble(), 'lng': (point[0] as num).toDouble()}).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Community Reports ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitReport({
    required String accessToken,
    required String reportType,
    required String description,
    required String locationName,
    required double latitude,
    required double longitude,
    bool vulnerablePerson = false,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/reports/submit'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'report_type': reportType, 'description': description, 'location_name': locationName, 'latitude': latitude, 'longitude': longitude, 'vulnerable_person': vulnerablePerson}),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> fetchNearbyReports({required String accessToken, required double latitude, required double longitude, double radiusKm = 20, String? reportType}) async {
    final params = <String, String>{'latitude': latitude.toString(), 'longitude': longitude.toString(), 'radius_km': radiusKm.toString()};
    if (reportType != null) params['report_type'] = reportType;
    final uri = Uri.parse('$baseUrl/api/v1/reports/nearby/list').replace(queryParameters: params);
    final response = await _client.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch reports: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> vouchReport(String accessToken, String reportId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/reports/$reportId/vouch'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> unvouchReport(String accessToken, String reportId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/v1/reports/$reportId/vouch'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }

  Future<void> markHelpful(String accessToken, String reportId) async {
    await _client.post(Uri.parse('$baseUrl/api/v1/reports/$reportId/helpful'), headers: {'Authorization': 'Bearer $accessToken'});
  }

  Future<void> unmarkHelpful(String accessToken, String reportId) async {
    await _client.delete(Uri.parse('$baseUrl/api/v1/reports/$reportId/helpful'), headers: {'Authorization': 'Bearer $accessToken'});
  }

  // ── Personal Preparedness ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchChecklist(String accessToken) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/preparedness/checklist'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch checklist: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> addChecklistItem({required String accessToken, required String itemName, String category = 'general', String notes = ''}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/preparedness/checklist'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'item_name': itemName, 'category': category, 'notes': notes}),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> toggleChecklistItem(String accessToken, String itemId, bool completed) async {
    final uri = Uri.parse('$baseUrl/api/v1/preparedness/checklist/$itemId/toggle').replace(queryParameters: {'completed': completed.toString()});
    final response = await _client.patch(uri, headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to toggle item: ${response.statusCode}');
  }

  Future<void> deleteChecklistItem(String accessToken, String itemId) async {
    await _client.delete(Uri.parse('$baseUrl/api/v1/preparedness/checklist/$itemId'), headers: {'Authorization': 'Bearer $accessToken'});
  }

  Future<Map<String, dynamic>> fetchPreparednessScore(String accessToken) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/preparedness/score'), headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch score: ${response.statusCode}');
  }

  Future<List<dynamic>> fetchEducationalTopics(String accessToken) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/preparedness/education'), headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to fetch educational topics: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> fetchEducationalTopic(String accessToken, String topicId) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/preparedness/education/$topicId'), headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Topic not found');
  }

  Future<void> markTopicViewed(String accessToken, String topicId) async {
    await _client.post(Uri.parse('$baseUrl/api/v1/preparedness/education/$topicId/view'), headers: {'Authorization': 'Bearer $accessToken'});
  }

  Future<List<dynamic>> fetchNearbyEvacuationCentres({required String accessToken, required double latitude, required double longitude, double radiusKm = 20}) async {
    final uri = Uri.parse('$baseUrl/api/v1/preparedness/evacuation-centres/nearby').replace(
      queryParameters: {'latitude': latitude.toString(), 'longitude': longitude.toString(), 'radius_km': radiusKm.toString()},
    );
    final response = await _client.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to fetch evacuation centres: ${response.statusCode}');
  }

  // ── Family Groups ─────────────────────────────────────────────────────────

  Future<List<dynamic>> fetchFamilyGroups(String accessToken) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/family/groups'), headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to fetch family groups: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createFamilyGroup({required String accessToken, required String name, List<Map<String, String>> members = const []}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/family/groups'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'name': name, 'members': members}),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }

  Future<void> deleteFamilyGroup({required String accessToken, required String groupId}) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/v1/family/groups/$groupId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 204) throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> renameFamilyGroup({required String accessToken, required String groupId, required String name}) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/v1/family/groups/$groupId/rename'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> addFamilyMember({required String accessToken, required String groupId, required String name, String phoneNumber = '', String relationship = ''}) async {
    final uri = Uri.parse('$baseUrl/api/v1/family/members').replace(queryParameters: {'group_id': groupId});
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'name': name, 'phone_number': phoneNumber, 'relationship': relationship}),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }

  Future<void> deleteFamilyMember({required String accessToken, required String memberId}) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/v1/family/members/$memberId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 204) throw Exception(_extractErrorMessage(response));
  }

  /// status: "safe" | "needs_help" | "unknown"
  Future<Map<String, dynamic>> familyCheckin({required String accessToken, required String memberId, required String status}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/family/checkin'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'member_id': memberId, 'status': status}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchProfile(String accessToken) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/profile/me'), headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> updateProfile({required String accessToken, required Map<String, dynamic> profileData}) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/v1/profile/me'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode(profileData),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(_extractErrorMessage(response));
  }
}
