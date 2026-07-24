import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:user_app/exposure_report_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/main.dart';
import 'package:user_app/viewproducts.dart';
import 'package:user_app/skin_scanner_page.dart';
import 'package:user_app/chatbot_page.dart';
import 'package:user_app/uv_map_discovery.dart';
import 'package:user_app/subscription_page.dart';
import 'package:user_app/view_dermatologist.dart';
import 'package:user_app/notification_service.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with SingleTickerProviderStateMixin {
  static const Color bgBlack = Color(0xFF0A0A0F);
  static const Color darkCard = Color(0xFF141420);
  static const Color gold = Color(0xFFC59A6D);
  static const Color copper = Color(0xFF7A4E2D);
  static const Color glass = Color(0xFF1E1E2E);
  static const Color accent = Color(0xFF6C63FF);

  double uvIndex = 0.0;
  String temperature = "--";
  String locationName = "Detecting location...";
  bool isLoading = true;
  List<dynamic> recommendedProducts = [];
  int? userSkinType;
  String? userName;
  String? userSkinTypeName;
  Map<String, dynamic>? enhancedSuggestions;
  bool isSubscribed = false;
  bool isSunscreenApplied = false;
  DateTime? applyTime;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? "";

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _initLocationAndWeather();
    _loadUserName();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('tbl_user')
            .select('user_name, skintype_id')
            .eq('user_id', user.id)
            .single();

        // Subscription check
        final sub = await supabase
            .from('tbl_user_subscription')
            .select()
            .eq('user_id', user.id)
            .eq('subscription_status', 'active')
            .maybeSingle();

        if (data['skintype_id'] != null) {
          try {
            final stData = await supabase.from('tbl_skintype').select('skintype_name').eq('skintype_id', data['skintype_id']).single();
            userSkinTypeName = stData['skintype_name'] as String?;
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            userName = data['user_name'];
            userSkinType = data['skintype_id'] != null
                ? (data['skintype_id'] as num).toInt()
                : null;
            isSubscribed = sub != null;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _initLocationAndWeather() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await _fetchWeather(pos.latitude, pos.longitude);
    } catch (e) {
      _fetchWeather(20.5937, 78.9629); // Default India
    }
  }

  Future<void> _logUV(double lat, double lon, String city, double uv) async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('tbl_uv_log').insert({
          'user_id': user.id,
          'latitude': lat,
          'longitude': lon,
          'uv_index': uv,
          'location_name': city,
          'logged_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      // 1. Get Temperature & City
      final weatherUrl =
          "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";
      final weatherRes = await http.get(Uri.parse(weatherUrl));

      // 2. Get UV Index (Separate call for 2.5 keys)
      final uvUrl =
          "https://api.openweathermap.org/data/2.5/uvi?lat=$lat&lon=$lon&appid=$apiKey";
      final uvRes = await http.get(Uri.parse(uvUrl));

      if (weatherRes.statusCode == 200) {
        final wData = json.decode(weatherRes.body);
        final city = await _getCityName(lat, lon);

        double currentUv = 0.0;
        if (uvRes.statusCode == 200) {
          final uvData = json.decode(uvRes.body);
          currentUv = (uvData['value'] ?? 0).toDouble();
        }

        if (mounted) {
          setState(() {
            temperature = wData['main']['temp'].round().toString();
            uvIndex = currentUv;
            locationName = city;
          });
          _logUV(lat, lon, city, currentUv);
          await _fetchRecommendedProducts();
          _fetchRecommendations();
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Weather/UV Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<String> _getCityName(double lat, double lon) async {
    try {
      final url =
          "https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey";
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data.isNotEmpty) return data[0]['name'];
      }
    } catch (_) {}
    return "Unknown";
  }

  Future<void> _fetchRecommendations() async {
    try {
      String targetProfile = 'All';
      if (userSkinTypeName != null) {
        String lowerT = userSkinTypeName!.toLowerCase();
        if (lowerT.contains('type 1') || lowerT.contains('type 2') || lowerT.contains('type i') || lowerT.contains('type ii')) {
          if (!lowerT.contains('iii')) targetProfile = 'Fitzpatrick 1-2';
        } else if (lowerT.contains('type 3') || lowerT.contains('type 4') || lowerT.contains('type 5') || lowerT.contains('type 6') || lowerT.contains('iii') || lowerT.contains('iv') || lowerT.contains('v')) {
          targetProfile = 'Fitzpatrick 3-6';
        }
      }

      var res = await supabase
          .from('tbl_uv_recommendation')
          .select()
          .lte('min_uv', uvIndex)
          .gte('max_uv', uvIndex)
          .eq('skin_profile', targetProfile)
          .limit(1);

      if (res.isEmpty) {
        res = await supabase
            .from('tbl_uv_recommendation')
            .select()
            .lte('min_uv', uvIndex)
            .gte('max_uv', uvIndex)
            .eq('skin_profile', 'All')
            .limit(1);
      }

      if (res.isNotEmpty && mounted) {
        final data = res.first;
        setState(() {
          enhancedSuggestions = {
            "sunscreen": {
              "spf": data['sunscreen_spf'] ?? "SPF 30+",
              "type": data['sunscreen_type'] ?? "Broad Spectrum",
              "details": data['sunscreen_details'] ?? "Reapply every 3 hours."
            },
            "dress": {
              "color": data['dress_color'] ?? "Any",
              "type": data['dress_type'] ?? "Comfortable wear"
            },
            "safety_tips": (data['safety_tips'] as String?)
                    ?.split(',')
                    .map((e) => e.trim())
                    .toList() ??
                ["Stay hydrated"]
          };
          isLoading = false;
        });
      } else {
        _setFallbackSuggestions();
      }
    } catch (e) {
      debugPrint("Database Fetch Error: $e");
      _setFallbackSuggestions();
    }
  }

  void _setFallbackSuggestions() {
    if (!mounted) return;
    setState(() {
      enhancedSuggestions = {
        "sunscreen": {
          "spf": "SPF 30+",
          "type": "Broad Spectrum",
          "details": "Apply every 2 hours."
        },
        "dress": {"color": "Light shades", "type": "Cotton/Breathable"},
        "safety_tips": ["Stay in shade during peak hours", "Wear sunglasses"]
      };
      isLoading = false;
    });
  }

  Future<void> _fetchRecommendedProducts() async {
    try {
      final level = _getUvLevel(uvIndex);
      final levelRes = await supabase
          .from('tbl_level')
          .select('level_id')
          .ilike('level_name', '%$level%')
          .limit(1);

      // 1. Exact Match (UV + SkinType)
      var query = supabase
          .from('tbl_product')
          .select('*, tbl_product_skintype!inner(skintype_id)');
      if (levelRes.isNotEmpty) {
        query = query.eq('level_id', levelRes[0]['level_id']);
      }
      if (userSkinType != null) {
        query = query.eq('tbl_product_skintype.skintype_id', userSkinType!);
      }

      var products = await query.limit(8);

      // 2. Similar Products (UV Level only) if no exact match
      if (products.isEmpty && levelRes.isNotEmpty) {
        products = await supabase
            .from('tbl_product')
            .select('*, tbl_product_skintype!inner(skintype_id)')
            .eq('level_id', levelRes[0]['level_id'])
            .limit(8);
      }

      // 3. Last fallback (General products)
      if (products.isEmpty) {
        products = await supabase
            .from('tbl_product')
            .select('*, tbl_product_skintype!inner(skintype_id)')
            .limit(8);
      }

      setState(() => recommendedProducts = products);
    } catch (e) {
      debugPrint("Recommendation Error: $e");
    }
  }

  String _getUvLevel(double uv) {
    if (uv <= 2) return "Low";
    if (uv <= 5) return "Moderate";
    if (uv <= 7) return "High";
    if (uv <= 10) return "Very High";
    return "Extreme";
  }

  Color _getUvColor(double uv) {
    if (uv <= 2) return Colors.greenAccent;
    if (uv <= 5) return Colors.yellowAccent;
    if (uv <= 7) return Colors.orangeAccent;
    if (uv <= 10) return Colors.redAccent;
    return Colors.purpleAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
                center: const Alignment(-0.8, -0.6),
                radius: 1.2,
                colors: [gold.withOpacity(0.05), bgBlack]),
          ),
          child: RefreshIndicator(
            color: gold,
            onRefresh: _initLocationAndWeather,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildUVHeroCard())),
                SliverToBoxAdapter(
                    child: _buildSuggestionSection("Smart Protection",
                        Icons.shield_rounded, _buildSunscreenAdvice())),
                SliverToBoxAdapter(
                    child: _buildSuggestionSection("Lifestyle & Safety",
                        Icons.checkroom_rounded, _buildDressAdvice())),
                SliverToBoxAdapter(child: _buildRecommendedHeader()),
                SliverToBoxAdapter(child: _buildRecommendedList()),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                        child: _buildDoctorBanner())),
              ],
            ),
          ),
        ),
      ),
      // bottomNavigationBar: _buildBottomNav(), // ❌ REMOVED: Redundant bottom bar
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  userName != null
                      ? "Hello, ${userName!.split(' ')[0]} 👋"
                      : "Welcome 👋",
                  style:
                      GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 4),
              Text("UVORA",
                  style: GoogleFonts.outfit(
                      color: gold,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.analytics_outlined,
                    color: Colors.blueAccent),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExposureReportPage())),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: glass,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: gold.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.location_on, color: gold, size: 14),
                  const SizedBox(width: 6),
                  Text(locationName,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11))
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildActionItem("Scan", Icons.perm_camera_mic_rounded, gold, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SkinScannerPage()));
          }),
          const SizedBox(width: 12),
          _buildActionItem(
              "AI Assistant",
              Icons.auto_awesome_rounded,
              accent,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatbotPage()))),
          const SizedBox(width: 12),
          _buildActionItem("Map", Icons.map_rounded, Colors.tealAccent, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UVMapDiscovery()));
          }),
        ],
      ),
    );
  }

  void _showUnlockDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: glass,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Premium Feature 💎",
            style:
                GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold)),
        content: Text(
            "Unlock Skin Scanner and Dermatologist Consultation by joining our premium community.",
            style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Maybe Later",
                  style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SubscriptionPage()));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text("Go Premium",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
      String title, IconData icon, Color color, VoidCallback onTap) {
    bool isLocked = title == "Scan" && !isSubscribed;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Icon(isLocked ? Icons.lock_outline_rounded : icon,
                color: isLocked ? Colors.white24 : color, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    color: isLocked ? Colors.white24 : color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))
          ]),
        ),
      ),
    );
  }

  Widget _buildUVHeroCard() {
    final color = _getUvColor(uvIndex);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
            colors: [color.withOpacity(0.2), darkCard],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1), blurRadius: 40, spreadRadius: 2)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$temperature°C",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: color.withOpacity(0.5))),
                child: Text("UV INDEX ${uvIndex.toStringAsFixed(1)}",
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                      value: (uvIndex / 11).clamp(0, 1),
                      strokeWidth: 8,
                      backgroundColor: Colors.white12,
                      color: color)),
              Text(_getUvLevel(uvIndex),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionSection(String title, IconData icon, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: glass.withOpacity(0.7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: gold, size: 18),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      color: gold, fontWeight: FontWeight.bold, fontSize: 16))
            ]),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSunscreenAdvice() {
    final sun = enhancedSuggestions?['sunscreen'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (userSkinType == null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.blueAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Common Tips Applied",
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 2),
                    Text("Scan your skin for personalized advice.",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SkinScannerPage())),
                child: const Text("SCAN NOW",
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ],
          ),
        ),
      Row(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: gold, borderRadius: BorderRadius.circular(8)),
            child: Text(sun != null ? (sun['spf'] ?? 'SPF 30+') : 'SPF 30+',
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12))),
        const SizedBox(width: 12),
        Text(sun != null ? (sun['type'] ?? 'Broad Spectrum') : 'Broad Spectrum',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),
      Text(
          sun != null
              ? (sun['details'] ?? 'Stay protected from UV rays')
              : 'Protect your skin based on current UV levels.',
          style: const TextStyle(
              color: Colors.white70, fontSize: 13, height: 1.5)),
      const SizedBox(height: 16),

      // LOG APPLICATION BUTTON
      InkWell(
        onTap: () {
          if (!isSunscreenApplied) {
            _handleSunscreenApplied();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSunscreenApplied
                ? Colors.green.withOpacity(0.2)
                : gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: isSunscreenApplied
                    ? Colors.greenAccent
                    : gold.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSunscreenApplied
                    ? Icons.check_circle_rounded
                    : Icons.add_moderator_rounded,
                color: isSunscreenApplied ? Colors.greenAccent : gold,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                isSunscreenApplied ? "Sunscreen Applied" : "Log Sunscreen Use",
                style: TextStyle(
                  color: isSunscreenApplied ? Colors.greenAccent : gold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      if (isSunscreenApplied)
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            "Reapply reminder set for a quick 2 minutes test.",
            style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontStyle: FontStyle.italic),
          ),
        ),
    ]);
  }

  void _handleSunscreenApplied() async {
    // For testing notification, set to 1 minute
    const int durationMinutes = 1;

    // Schedule notification
    await NotificationService()
        .scheduleReapplyNotification(minutes: durationMinutes);

    if (mounted) {
      setState(() {
        isSunscreenApplied = true;
        applyTime = DateTime.now();
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF141420),
          title: const Text("Success! 🧴",
              style: TextStyle(
                  color: Color(0xFFC59A6D), fontWeight: FontWeight.bold)),
          content: const Text(
              "Sunscreen logged successfully! We have set a loud alert to remind you in 1 minute strictly for testing purposes.",
              style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Got it!",
                  style: TextStyle(color: Colors.blueAccent)),
            )
          ],
        ),
      );
    }
  }

  Widget _buildDressAdvice() {
    final dress = enhancedSuggestions?['dress'];
    final List tips = (enhancedSuggestions?['safety_tips'] as List?) ??
        ["Seek shade", "Wear sunglasses"];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          "Optimal Color: ${dress != null ? (dress['color'] ?? 'Light shades') : 'Light shades'}",
          style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(
          "Style: ${dress != null ? (dress['type'] ?? 'Breathable') : 'Breathable'}",
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
      const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: Colors.white10)),
      ...tips
          .map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, color: gold, size: 14),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(t.toString(),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)))
              ])))
          ,
    ]);
  }

  Widget _buildRecommendedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("CURATED PRODUCTS",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2)),
        TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ViewProducts())),
            child: const Text("SEE ALL",
                style: TextStyle(color: gold, fontSize: 12))),
      ]),
    );
  }

  Widget _buildRecommendedList() {
    if (isLoading) {
      return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: gold)));
    }
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: recommendedProducts.length,
        itemBuilder: (ctx, i) => _buildProductCard(recommendedProducts[i]),
      ),
    );
  }

  Widget _buildProductCard(Map p) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
          color: glass,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: p['user_photo'] != null
                    ? Image.network(p['user_photo'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: darkCard))
                    : Container(color: darkCard))),
        Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['product_name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text("₹${p['price']}",
                  style: const TextStyle(
                      color: gold, fontWeight: FontWeight.w900, fontSize: 16)),
            ])),
      ]),
    );
  }

  Widget _buildDoctorBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [copper, gold]),
          borderRadius: BorderRadius.circular(30)),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("DERMATOLOGY EXPERTS",
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Personalized skin consultation",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.1)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () {
                if (isSubscribed) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UserViewDermatologist()));
                } else {
                  _showUnlockDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: bgBlack,
                  foregroundColor: gold,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              child: const Text("Book Trial")),
        ])),
        const Icon(Icons.medical_information_rounded,
            color: Colors.black26, size: 80),
      ]),
    );
  }
}
