import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:user_app/main.dart';

class ExposureReportPage extends StatefulWidget {
  const ExposureReportPage({super.key});

  @override
  State<ExposureReportPage> createState() => _ExposureReportPageState();
}

class _ExposureReportPageState extends State<ExposureReportPage> {
  final Color gold = const Color(0xFFC59A6D);
  final Color bgBlack = const Color(0xFF0A0A0F);
  final Color darkCard = const Color(0xFF141420);
  
  bool _isLoading = true;
  List<dynamic> _logs = [];

  double _avgUv = 0.0;
  double _maxUv = 0.0;
  int _highRiskCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final String uid = supabase.auth.currentUser!.id;
      final res = await supabase
          .from('tbl_uv_log')
          .select()
          .eq('user_id', uid)
          .order('logged_at', ascending: false);
      
      if (res.isNotEmpty) {
        double total = 0;
        double maxTemp = 0;
        int highRisk = 0;
        for (var item in res) {
          final uv = (item['uv_index'] ?? 0.0) as double;
          total += uv;
          if (uv > maxTemp) maxTemp = uv;
          if (uv > 6.0) highRisk++;
        }
        
        setState(() {
          _logs = res;
          _avgUv = total / res.length;
          _maxUv = maxTemp;
          _highRiskCount = highRisk;
        });
      }
    } catch (e) {
      debugPrint("Error fetching UV logs: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        title: Text("My UV Exposure Report", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC59A6D)))
          : _logs.isEmpty
              ? const Center(child: Text("No UV history tracking data found.", style: TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      Row(
                        children: [
                          Expanded(child: _buildStatBox("Avg UV", _avgUv.toStringAsFixed(1), Icons.analytics)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildStatBox("Max UV", _maxUv.toStringAsFixed(1), Icons.wb_sunny_rounded)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildStatBox("High Risk", "$_highRiskCount", Icons.warning_amber_rounded, color: Colors.orangeAccent)),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Text("Exposure Timeline", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _logs.length,
                        itemBuilder: (ctx, idx) {
                          final log = _logs[idx];
                          final date = DateTime.parse(log['logged_at']).toLocal();
                          final uv = (log['uv_index'] ?? 0.0) as double;
                          final uvColor = uv < 3 ? Colors.green : (uv < 6 ? Colors.orange : Colors.redAccent);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: darkCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: uvColor.withOpacity(0.2),
                                child: Text("${uv.toInt()}", style: TextStyle(color: uvColor, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(log['location_name'] ?? 'Unknown Location', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(date), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatBox(String title, String val, IconData icon, {Color color = const Color(0xFFC59A6D)}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
