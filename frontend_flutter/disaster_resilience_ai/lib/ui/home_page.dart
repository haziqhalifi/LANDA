import 'package:flutter/material.dart';
import 'package:disaster_resilience_ai/services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _api = ApiService();
  String _status = 'Tap the button to check backend status';
  bool _loading = false;

  Future<void> _pingBackend() async {
    setState(() => _loading = true);
    try {
      final result = await _api.ping();
      setState(() => _status = 'Backend says: ${result['message']}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disaster Resilience AI')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _pingBackend,
                      icon: const Icon(Icons.wifi_tethering),
                      label: const Text('Ping Backend'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
