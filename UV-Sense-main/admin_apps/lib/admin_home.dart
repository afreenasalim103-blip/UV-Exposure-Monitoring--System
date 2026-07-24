import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:admin_apps/main.dart';
import 'package:geolocator/geolocator.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color gold = const Color(0xFFC59A6D);
  final Color darkCard = const Color(0xFF1A1A1A);

  int userCount = 0;
  int doctorCount = 0;
  int productCount = 0;
  int orderCount = 0;
  double avgUv = 0.0;
  List uvData = [];
  bool isLoading = true;
  
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(20.5937, 78.9629); // Default India

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchGlobalUv();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition();
        setState(() {
          _currentCenter = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_currentCenter, 10);
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _fetchStats() async {
    try {
      final userRes = await supabase.from('tbl_user').select('user_id');
      final doctorRes = await supabase
          .from('tbl_dermatologist')
          .select('dermatologist_id');
      final productRes = await supabase
          .from('tbl_product')
          .select('product_id');
      final orderRes = await supabase
          .from('tbl_booking')
          .select('id')
          .neq('booking_status', 0);

      setState(() {
        userCount = userRes.length;
        doctorCount = doctorRes.length;
        productCount = productRes.length;
        orderCount = orderRes.length;
      });
    } catch (e) {
      debugPrint("Stats error: $e");
    }
  }

  String currentTemp = "--";
  String weatherDesc = "Loading...";

  String aiInsight = "Analyzing system data...";
  bool isAiThinking = false;

  Future<void> _fetchAiInsight() async {
    setState(() => isAiThinking = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate thinking
    
    try {
      String insight = "";
      if (avgUv > 8) {
        insight = "High UV detected globally. Suggest sending a push notification to users to stay hydrated and apply sunscreen.";
      } else if (orderCount > 100) {
        insight = "Order volume is high. Consider checking inventory for top products.";
      } else if (userCount > 1000) {
        insight = "User base is growing steadily. System health optimal.";
      } else {
        insight = "Stability maintained. No critical flags.";
      }

      setState(() {
        aiInsight = insight;
        isAiThinking = false;
      });
    } catch (e) {
      setState(() {
        aiInsight = "Efficiency optimal. System monitoring active.";
        isAiThinking = false;
      });
    }
  }

  Future<void> _fetchGlobalUv() async {
    try {
      final localRes = await http.get(
        Uri.parse('https://wttr.in/Kochi?format=j1'),
      );
      if (localRes.statusCode == 200) {
        final data = json.decode(localRes.body);
        setState(() {
          currentTemp = data['current_condition'][0]['temp_C'];
          weatherDesc = data['current_condition'][0]['weatherDesc'][0]['value'];
          avgUv = double.tryParse(data['current_condition'][0]['uvIndex']) ?? 0;
        });
        _fetchAiInsight();
      }
      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("UV error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SidebarWrapper(
        title: "Dashboard",
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: gold),
              const SizedBox(height: 15),
              Text(
                "Powering up UVORA Engine...",
                style: GoogleFonts.outfit(
                  color: gold.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SidebarWrapper(
      title: "Dashboard",
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => isLoading = true);
          await _fetchStats();
          await _fetchGlobalUv();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildSoftStatCard(
                      "Total Users",
                      userCount.toString(),
                      "+3%",
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildSoftStatCard(
                      "Dermatologists",
                      doctorCount.toString(),
                      "+12%",
                      Icons.medical_services,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildSoftStatCard(
                      "Active Products",
                      productCount.toString(),
                      "+5%",
                      Icons.inventory_2,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildSoftStatCard(
                      "Monthly Revenue",
                      "₹${(orderCount * 499)}",
                      "+1.5%",
                      Icons.payments,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 2. Main Analytics & Map
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildAiMindCard(),
                        const SizedBox(height: 25),
                        _buildLiveUvMap(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 25),
                  Expanded(flex: 1, child: _buildWelcomeCard()),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiMindCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color.fromARGB(255, 247, 190, 6),
                size: 24,
              ),
              const SizedBox(width: 15),
              Text(
                "UVORA MIND",
                style: GoogleFonts.outfit(
                  color: gold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (isAiThinking)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 245, 162, 9),
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            aiInsight,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveUvMap() {
    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  tileBuilder: (context, tileWidget, tile) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        -1, 0, 0, 0, 255,
                        0,-1, 0, 0, 255,
                        0, 0,-1, 0, 255,
                        0, 0, 0, 1, 0,
                      ]),
                      child: tileWidget,
                    );
                  },
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: gold.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("UV INTENSITY INDEX", style: GoogleFonts.outfit(color: gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    _buildLegendItem("0-2 Low", Colors.green),
                    _buildLegendItem("3-5 Moderate", Colors.yellow),
                    _buildLegendItem("6-7 High", Colors.orange),
                    _buildLegendItem("8-10 Very High", Colors.red),
                    _buildLegendItem("11+ Extreme", Colors.purple),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSoftStatCard(
    String title,
    String value,
    String percentage,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white30,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      percentage,
                      style: GoogleFonts.outfit(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      height: 550,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "UVORA Engine",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Real-time tracking: $currentTemp°C | UV Index: ${avgUv.toInt()}.\nEnterprise dashboard active.",
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const Spacer(),
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gold.withOpacity(0.8), gold.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.rocket_launch_rounded,
                color: Colors.black,
                size: 80,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
