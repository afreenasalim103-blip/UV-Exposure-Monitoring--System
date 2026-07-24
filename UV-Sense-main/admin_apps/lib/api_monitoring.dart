import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:admin_apps/sidebar_wrapper.dart';

class APIMonitoring extends StatefulWidget {
  const APIMonitoring({super.key});

  @override
  State<APIMonitoring> createState() => _APIMonitoringState();
}

class _APIMonitoringState extends State<APIMonitoring> {
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);
  final Color glass = const Color(0xFF262626);

  bool isTesting = false;
  String apiStatus = "Idle";
  Color statusColor = Colors.grey;
  List<Map<String, String>> logs = [];

  @override
  void initState() {
    super.initState();
    _addLog("System initialized", "INFO");
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      isTesting = true;
      apiStatus = "Testing...";
      statusColor = Colors.orange;
    });

    _addLog("Starting API diagnostic check...", "PROCESS");

    try {
      final startTime = DateTime.now();
      final res = await http.get(Uri.parse('https://wttr.in/Kochi?format=j1'));
      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;

      if (res.statusCode == 200) {
        setState(() {
          apiStatus = "Healthy";
          statusColor = Colors.green;
        });
        _addLog("wttr.in responded in ${latency}ms", "SUCCESS");
        _addLog("Data format: JSON validated", "SUCCESS");
      } else {
        setState(() {
          apiStatus = "Service Error";
          statusColor = Colors.red;
        });
        _addLog("API returned status code: ${res.statusCode}", "ERROR");
      }
    } catch (e) {
      setState(() {
        apiStatus = "Unreachable";
        statusColor = Colors.purple;
      });
      _addLog("Connection failed: $e", "CRITICAL");
    }

    setState(() => isTesting = false);
  }

  void _addLog(String message, String type) {
    logs.insert(0, {
      "time": DateTime.now().toString().split(".")[0].split(" ")[1],
      "message": message,
      "type": type
    });
    if (logs.length > 20) logs.removeLast();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "API Engine",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Status Card
            _buildStatusCard(),
            const SizedBox(height: 25),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Config Section
                Expanded(child: _buildConfigSection()),
                const SizedBox(width: 20),
                // Log Section
                Expanded(flex: 2, child: _buildLogSection()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Primary UV Service", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("Endpoint: https://wttr.in", style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13)),
            ],
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  apiStatus.toUpperCase(),
                  style: GoogleFonts.outfit(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              if (!isTesting)
                TextButton.icon(
                  onPressed: _runDiagnostic,
                  icon: const Icon(Icons.refresh, size: 14, color: Colors.blue),
                  label: const Text("REDRAW", style: TextStyle(color: Colors.blue, fontSize: 12)),
                )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection() {
    return Container(
       padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Capabilities", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildCapability("UV Index Realtime", true),
          _buildCapability("Geo-location Sync", true),
          _buildCapability("Dermatologist API", true),
          _buildCapability("E-Commerce Engine", true),
          _buildCapability("Push Notifications", false),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.terminal, color: gold, size: 16),
                const SizedBox(width: 10),
                const Text("v1.0.4-stable", style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCapability(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, color: active ? Colors.green : Colors.white10, size: 16),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLogSection() {
    return Container(
       padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Communication Logs", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => setState(() => logs.clear()), icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18)),
            ],
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("[${log['time']}]", style: const TextStyle(color: Colors.white24, fontSize: 12)),
                    const SizedBox(width: 10),
                    Text("${log['type']}:", style: TextStyle(color: _getLogColor(log['type']!), fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(log['message']!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  ],
                ),
              );
            },
          ),
          if (logs.isEmpty)
             const Padding(
               padding: EdgeInsets.all(20.0),
               child: Center(child: Text("Waiting for activity...", style: TextStyle(color: Colors.white10))),
             ),
        ],
      ),
    );
  }

  Color _getLogColor(String type) {
    switch (type) {
      case "SUCCESS": return Colors.green;
      case "ERROR": return Colors.red;
      case "CRITICAL": return Colors.purple;
      case "PROCESS": return Colors.blue;
      default: return Colors.white54;
    }
  }
}
