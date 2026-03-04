import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Service class for communicating with the FastAPI backend.
class ApiService {
  /// Base URL of the FastAPI server.
  /// - Web (Chrome/Edge): uses localhost directly.
  /// - Android emulator: 10.0.2.2 maps to the host machine's localhost.
  /// - Physical device: replace with your machine's LAN IP.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Ping the alerts service to verify connectivity.
  Future<Map<String, dynamic>> ping() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/alerts/ping'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Ping failed with status ${response.statusCode}');
  }

  /// Request a risk prediction from the backend.
  Future<Map<String, dynamic>> predictRisk(List<double> features) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/alerts/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'features': features}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Prediction failed with status ${response.statusCode}');
  }
}
