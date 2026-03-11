import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:disaster_resilience_ai/models/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _reverseGeoUrl =
      'https://nominatim.openstreetmap.org/reverse';

  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,weathercode,windspeed_10m,relative_humidity_2m',
        'daily':
            'weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum',
        'timezone': 'Asia/Kuala_Lumpur',
        'forecast_days': '7',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch weather (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherData.fromJson(json);
  }

  Future<String?> fetchLocationName({
    required double latitude,
    required double longitude,
  }) async {
    try {
    final uri = Uri.parse(_reverseGeoUrl).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'accept-language': 'en',
      },
    );

    final response = await http.get(uri, headers: {
      'User-Agent': 'DisasterResilienceApp/1.0',
    }).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      return null;
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final address = json['address'] as Map<String, dynamic>?;
    if (address == null) return null;

    final city = (address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'])
        ?.toString();
    final state = address['state']?.toString();

    final parts = [
      if (city != null && city.isNotEmpty) city,
      if (state != null && state.isNotEmpty) state,
    ];

    if (parts.isEmpty) {
      return null;
    }
    return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
        queryParameters: {
          'q': query.trim(),
          'format': 'json',
          'countrycodes': 'my',
          'limit': '6',
          'accept-language': 'en',
        },
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'DisasterResilienceApp/1.0',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) {
        final parts = (e['display_name'] as String).split(',');
        final name = parts.take(2).map((s) => s.trim()).join(', ');
        return {
          'name': name,
          'lat': double.parse(e['lat'].toString()),
          'lon': double.parse(e['lon'].toString()),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
