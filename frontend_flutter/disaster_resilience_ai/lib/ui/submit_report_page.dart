import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:disaster_resilience_ai/services/api_service.dart';

class SubmitReportPage extends StatefulWidget {
  const SubmitReportPage({super.key, required this.accessToken});

  final String accessToken;

  @override
  State<SubmitReportPage> createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends State<SubmitReportPage> {
  static const _types = [
    _ReportType('flood',             'Water Rising',      Icons.water_drop,              Colors.blue),
    _ReportType('blocked_road',      'Road Blocked',      Icons.block,                   Colors.deepOrange),
    _ReportType('landslide',         'Landslide',         Icons.landscape,               Colors.brown),
    _ReportType('medical_emergency', 'Medical Emergency', Icons.medical_services_rounded, Colors.red),
  ];

  final ApiService _api          = ApiService();
  final _descController          = TextEditingController();
  final _picker                  = ImagePicker();

  String? _selectedType;
  bool    _vulnerableHelp = false;
  bool    _loading        = false;
  bool    _locating       = false;
  double  _lat            = 3.8077;
  double  _lon            = 103.3260;
  String  _locationName   = 'Fetching location...';
  XFile?  _pickedImage;

  // ── Theme helpers ──────────────────────────────────────────────────────────
  bool   get _isDark      => Theme.of(context).brightness == Brightness.dark;
  Color  get _bg          => _isDark ? const Color(0xFF0F140F) : const Color(0xFFF0F2F5);
  Color  get _card        => _isDark ? const Color(0xFF1B251B) : Colors.white;
  Color  get _cardBorder  => _isDark ? const Color(0xFF334236) : const Color(0xFFE2E8F0);
  Color  get _textPrimary => _isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1E293B);
  Color  get _textSub     => _isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
  Color  get _textMuted   => _isDark ? const Color(0xFF64748B) : Colors.grey.shade400;
  Color  get _inputFill   => _isDark ? const Color(0xFF1E2720) : Colors.white;
  static const Color _green = Color(0xFF2E7D32);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.deniedForever &&
          perm != LocationPermission.denied) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lon = pos.longitude;
          });
        }
        await _reverseGeocode(pos.latitude, pos.longitude);
      } else {
        if (mounted) {
          setState(() => _locationName =
              'Near ${_lat.toStringAsFixed(4)}, ${_lon.toStringAsFixed(4)}');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationName =
            'Near ${_lat.toStringAsFixed(4)}, ${_lon.toStringAsFixed(4)}');
      }
    }
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'DisasterResilienceApp/1.0',
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data    = jsonDecode(resp.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final city  = (address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? '') as String;
          final state = (address['state'] ?? '') as String;
          final name  = city.isNotEmpty
              ? (state.isNotEmpty ? '$city, $state' : city)
              : 'Near ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
          if (mounted) setState(() => _locationName = name);
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _locationName =
          'Near ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}');
    }
  }

  // ── Image ──────────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 1920);
      if (image != null && mounted) setState(() => _pickedImage = image);
    } catch (_) {}
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an incident type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _api.submitReport(
        accessToken:     widget.accessToken,
        reportType:      _selectedType!,
        description:     _descController.text.trim(),
        latitude:        _lat,
        longitude:       _lon,
        locationName:    _locationName,
        vulnerablePerson: _vulnerableHelp,
      );

      if (_pickedImage != null) {
        final reportId = result['id'] as String?;
        if (reportId != null) {
          try {
            final ext  = _pickedImage!.name.split('.').last.toLowerCase();
            final mime = ext == 'jpg' || ext == 'jpeg'
                ? 'image/jpeg'
                : ext == 'png'
                    ? 'image/png'
                    : ext == 'webp'
                        ? 'image/webp'
                        : ext == 'gif'
                            ? 'image/gif'
                            : 'image/jpeg';
            await _api.uploadReportMedia(
              accessToken: widget.accessToken,
              reportId:    reportId,
              imageFile:   _pickedImage!,
              mimeType:    mime,
            );
          } catch (_) {}
        }
      }

      if (mounted) {
        showDialog(
          context:           context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: _green, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Report Submitted',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary),
                ),
              ],
            ),
            content: Text(
              'Your report is under review by our team. It will appear on the community feed once approved.',
              style: TextStyle(color: _textSub, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                      color: _green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Submit Report',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page title ───────────────────────────────────────────
            Text(
              'What are you reporting?',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the incident type to notify the\ncommunity.',
              style:
                  TextStyle(color: _textSub, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),

            // ── Incident type grid ───────────────────────────────────
            GridView.count(
              crossAxisCount:   2,
              shrinkWrap:       true,
              physics:          const NeverScrollableScrollPhysics(),
              mainAxisSpacing:  16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: _types.map(_buildTypeCard).toList(),
            ),
            const SizedBox(height: 24),

            // ── Description ──────────────────────────────────────────
            Text(
              'Description',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines:   3,
              style:      TextStyle(color: _textPrimary),
              decoration: InputDecoration(
                hintText:  'Describe what you see...',
                hintStyle: TextStyle(color: _textMuted),
                filled:    true,
                fillColor: _inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Photo attachment ─────────────────────────────────────
            Text(
              'Attach Photo',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPhotoSection(),
            const SizedBox(height: 24),

            // ── Vulnerable person toggle ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isDark
                    ? const Color(0xFF2A1515)
                    : const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDark
                      ? const Color(0xFF4A2020)
                      : const Color(0xFFFFCDD2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.share_location,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vulnerable Person Help',
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Priority rescue alert',
                          style:
                              TextStyle(color: _textSub, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value:       _vulnerableHelp,
                    onChanged:   (val) =>
                        setState(() => _vulnerableHelp = val),
                    thumbColor:  WidgetStateProperty.all(Colors.white),
                    trackColor:  WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.red.shade400
                          : _isDark
                              ? const Color(0xFF334236)
                              : Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Current location ─────────────────────────────────────
            Text(
              'Current Location',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? const Color(0xFF1E2720)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _cardBorder),
                    boxShadow: _isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _locating
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _isDark
                                    ? const Color(0xFF4CAF50)
                                    : Colors.green.shade700,
                              ),
                            )
                          : Icon(
                              Icons.location_on_outlined,
                              color: _isDark
                                  ? const Color(0xFF4CAF50)
                                  : Colors.green.shade700,
                              size: 16,
                            ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _locationName,
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_loading || _locating) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      _isDark ? const Color(0xFF1B3A1B) : Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _loading
                    ? const SizedBox(
                        width:  18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Send Incident Report',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                label: _loading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.send_outlined),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Photo section ──────────────────────────────────────────────────────────

  Widget _buildPhotoSection() {
    if (_pickedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _pickedImage!.path,
              height:  180,
              width:   double.infinity,
              fit:     BoxFit.cover,
            ),
          ),
          Positioned(
            top:   8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _pickedImage = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color:  _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickImage(ImageSource.camera),
              borderRadius: const BorderRadius.only(
                topLeft:    Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        color: _textSub, size: 28),
                    const SizedBox(height: 6),
                    Text('Camera',
                        style: TextStyle(
                            color: _textSub, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 60, color: _cardBorder),
          Expanded(
            child: InkWell(
              onTap: () => _pickImage(ImageSource.gallery),
              borderRadius: const BorderRadius.only(
                topRight:    Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined,
                        color: _textSub, size: 28),
                    const SizedBox(height: 6),
                    Text('Gallery',
                        style: TextStyle(
                            color: _textSub, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Type card ──────────────────────────────────────────────────────────────

  Widget _buildTypeCard(_ReportType type) {
    final isSelected = _selectedType == type.key;
    return InkWell(
      onTap:         () => setState(() => _selectedType = type.key),
      borderRadius:  BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? type.color : _cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: _isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isSelected ? 0.08 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: type.color
                    .withValues(alpha: isSelected ? 0.2 : (_isDark ? 0.12 : 0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, color: type.color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? type.color : _textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportType {
  final String   key;
  final String   label;
  final IconData icon;
  final Color    color;

  const _ReportType(this.key, this.label, this.icon, this.color);
}
