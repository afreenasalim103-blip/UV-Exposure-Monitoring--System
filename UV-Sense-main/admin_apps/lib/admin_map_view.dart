import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class AdminMapView extends StatefulWidget {
  const AdminMapView({super.key});

  @override
  State<AdminMapView> createState() => _AdminMapViewState();
}

class _AdminMapViewState extends State<AdminMapView> {
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final response = await supabase.from('tbl_uv_log').select();
      
      final Set<Marker> markers = {};
      for (var log in response) {
        markers.add(
          Marker(
            markerId: MarkerId(log['log_id'].toString()),
            position: LatLng(log['latitude'], log['longitude']),
            infoWindow: InfoWindow(
              title: "UV Index: ${log['uv_index']}",
              snippet: "Location: ${log['location_name']}",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerHue(log['uv_index'].toDouble()),
            ),
          ),
        );
      }

      setState(() {
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching logs: $e");
      setState(() => _isLoading = false);
    }
  }

  double _getMarkerHue(double uv) {
    if (uv <= 2) return BitmapDescriptor.hueGreen;
    if (uv <= 5) return BitmapDescriptor.hueYellow;
    if (uv <= 7) return BitmapDescriptor.hueOrange;
    if (uv <= 10) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueViolet;
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFC59A6D);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("GEO-SPECTRAL UV MAP", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchLogs)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(20.5937, 78.9629),
                zoom: 5,
              ),
              markers: _markers,
              myLocationEnabled: true,
              mapType: MapType.normal,
              onMapCreated: (controller) => controller.setMapStyle(_darkMapStyle),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
    );
  }

  static const String _darkMapStyle = '''
  [
    { "elementType": "geometry", "stylers": [ { "color": "#212121" } ] },
    { "elementType": "labels.icon", "stylers": [ { "visibility": "off" } ] },
    { "elementType": "labels.text.fill", "stylers": [ { "color": "#757575" } ] },
    { "elementType": "labels.text.stroke", "stylers": [ { "color": "#212121" } ] },
    { "featureType": "administrative", "elementType": "geometry", "stylers": [ { "color": "#757575" } ] },
    { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#000000" } ] }
  ]
  ''';
}
