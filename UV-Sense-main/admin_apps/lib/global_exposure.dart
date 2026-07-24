import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_apps/main.dart';
import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:intl/intl.dart';

class GlobalExposure extends StatefulWidget {
  const GlobalExposure({super.key});

  @override
  State<GlobalExposure> createState() => _GlobalExposureState();
}

class _GlobalExposureState extends State<GlobalExposure> {
  final Color gold = const Color(0xFFC59A6D);
  final Color bgBlack = const Color(0xFF0A0A0F);
  final Color darkCard = const Color(0xFF1A1A1A);

  bool _isLoading = true;
  List<dynamic> _logs = [];

  double _globalAvgUv = 0.0;
  int _totalTrackingUsers = 0;
  int _highRiskIncidents = 0;

  @override
  void initState() {
    super.initState();
    _fetchGlobalData();
  }

  Future<void> _fetchGlobalData() async {
    setState(() => _isLoading = true);
    try {
      final res = await supabase.from('tbl_uv_log').select('*, tbl_user(*)').order('logged_at', ascending: false).limit(100);
      
      if (res.isNotEmpty) {
        double totalUv = 0;
        int highRisk = 0;
        Set<String> uniqueUsers = {};

        for (var item in res) {
          final uv = (item['uv_index'] ?? 0.0) as double;
          totalUv += uv;
          if (uv > 6.0) highRisk++;
          if (item['user_id'] != null) uniqueUsers.add(item['user_id'].toString());
        }

        setState(() {
          _logs = res;
          _globalAvgUv = totalUv / res.length;
          _highRiskIncidents = highRisk;
          _totalTrackingUsers = uniqueUsers.length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Global Logs: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "Global UV Exposure",
      child: Scaffold(
        backgroundColor: bgBlack,
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: gold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top stats
                    Row(
                      children: [
                        Expanded(child: _buildStatBox("Active Trackers", "$_totalTrackingUsers", Icons.people_alt, Colors.blueAccent)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildStatBox("Global Avg UV", _globalAvgUv.toStringAsFixed(1), Icons.analytics, gold)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildStatBox("High Risk Incidents", "$_highRiskIncidents", Icons.warning_amber_rounded, Colors.redAccent)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text("📍 Recent Global Tracking Logs", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _logs.isEmpty 
                    ? const Text("No logs tracked yet.", style: TextStyle(color: Colors.white54))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _logs.length,
                        itemBuilder: (ctx, idx) {
                          final log = _logs[idx];
                          final user = log['tbl_user'] ?? {};
                          final date = DateTime.parse(log['logged_at']).toLocal();
                          final uv = (log['uv_index'] ?? 0.0) as double;
                          final uvColor = uv < 3 ? Colors.green : (uv < 6 ? Colors.orange : Colors.redAccent);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: darkCard,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: uvColor.withOpacity(0.2),
                                child: Text("${uv.toInt()}", style: TextStyle(color: uvColor, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(log['location_name'] ?? 'Unknown Location', style: const TextStyle(color: Colors.white)),
                              subtitle: Text("User: ${user['user_name'] ?? 'Unknown'} • ${DateFormat('MMM dd, hh:mm a').format(date)}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              trailing: Icon(Icons.location_on, color: gold.withOpacity(0.5), size: 16),
                            ),
                          );
                        },
                      )
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatBox(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 28),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}
