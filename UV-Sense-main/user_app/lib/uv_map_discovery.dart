import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:user_app/main.dart';

class UVMapDiscovery extends StatefulWidget {
  const UVMapDiscovery({super.key});

  @override
  State<UVMapDiscovery> createState() => _UVMapDiscoveryState();
}

class _UVMapDiscoveryState extends State<UVMapDiscovery> {
  LatLng _selectedLoc = const LatLng(20.5937, 78.9629); // Default India
  double _uvIndex = 0.0;
  Map<String, dynamic>? _suggestions;
  bool _isLoading = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      
      Position pos = await Geolocator.getCurrentPosition();
      LatLng currentPos = LatLng(pos.latitude, pos.longitude);
      
      setState(() {
        _selectedLoc = currentPos;
      });
      _mapController.move(currentPos, 12);
      _fetchUvForLocation(currentPos);
    } catch (e) {
      debugPrint("Location Init error: $e");
      _fetchUvForLocation(_selectedLoc);
    }
  }

  final String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? "";

  Future<void> _fetchUvForLocation(LatLng loc) async {
    setState(() => _isLoading = true);
    try {
      final url = "https://api.openweathermap.org/data/2.5/uvi?lat=${loc.latitude}&lon=${loc.longitude}&appid=$apiKey";
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _uvIndex = (data['value'] ?? 0).toDouble();

        List<Map<String, String>> recommendations = [];
        
        try {
          final res = await supabase
              .from('tbl_uv_recommendation')
              .select()
              .lte('min_uv', _uvIndex)
              .gte('max_uv', _uvIndex);

          if (res.isNotEmpty) {
            for (var data in res) {
              recommendations.add({
                "skin_type": data['skin_profile']?.toString() ?? "All",
                "sunscreen": data['sunscreen_spf']?.toString() ?? "SPF 30+",
                "dress": data['dress_color']?.toString() ?? "Normal",
                "tips": (data['safety_tips']?.toString().split(',').first ?? "Stay safe").trim()
              });
            }
          }
        } catch (e) {
          debugPrint("Failed to load UV recommendations from DB: $e");
        }

        // Fallback if DB is empty for this range
        if (recommendations.isEmpty) {
          if (_uvIndex < 8.0) {
            recommendations = [
              {"skin_type": "Fitzpatrick 1-2", "sunscreen": "SPF 50+ reapplied 3hrs", "dress": "Hat, sunglasses", "tips": "Avoid mid-day sun"},
              {"skin_type": "Fitzpatrick 3-4", "sunscreen": "SPF 30+", "dress": "Hat, sunglasses", "tips": "Seek shade during peak hours"},
              {"skin_type": "Fitzpatrick 5-6", "sunscreen": "SPF 15+", "dress": "Standard summer wear", "tips": "Low risk"}
            ];
          } else {
            recommendations = [
              {"skin_type": "All", "sunscreen": "SPF 50+ reapplied often", "dress": "Broad hat, UV clothing", "tips": "Extra protection needed"}
            ];
          }
        }
        
        if (mounted) {
          setState(() {
            _suggestions = {
              "recommendations": recommendations,
              "general_suggestions": ["Stay hydrated", "Seek shade during peak UV hours"]
            };
          });
        }
      }
    } catch (e) {
      debugPrint("Map UV Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFC59A6D);
    const Color glass = Color(0xFF1E1E2E);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("EXPLORER", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLoc,
              initialZoom: 4,
              onTap: (tapPosition, point) {
                setState(() => _selectedLoc = point);
                _fetchUvForLocation(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.user_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLoc,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.orangeAccent,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (_isLoading)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20), border: Border.all(color: gold.withOpacity(.3))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: gold, strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text("SYNCING SATELLITE DATA...", style: GoogleFonts.outfit(color: gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
          
          if (_suggestions != null) _buildFloatingPanel(gold, glass),
        ],
      ),
    );
  }

  Widget _buildFloatingPanel(Color gold, Color glass) {
    return Positioned(
      bottom: 20,
      left: 15,
      right: 15,
      child: Container(
        height: 350,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141420).withOpacity(0.98),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: gold.withOpacity(.2)),
          boxShadow: [BoxShadow(color: Colors.black, blurRadius: 40)],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("LOCAL ANALYSIS", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white24, size: 20), onPressed: () => setState(() => _suggestions = null)),
                ],
              ),
              const SizedBox(height: 10),
              Text("UV Index: ${_uvIndex.toStringAsFixed(1)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white10, height: 25),
              ...(_suggestions!['recommendations'] as List).map((rec) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec['skin_type'], style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text("🛡️ Sunscreen: ${rec['sunscreen']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("👕 Dress: ${rec['dress']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("💡 Tips: ${rec['tips']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color gold) {
    return Row(
      children: [
        Icon(icon, color: gold, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
