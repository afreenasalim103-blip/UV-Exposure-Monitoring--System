import 'package:flutter/material.dart';
import 'package:admin_apps/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_apps/sidebar_wrapper.dart';

class ViewComplaints extends StatefulWidget {
  const ViewComplaints({super.key});

  @override
  State<ViewComplaints> createState() => _ViewComplaintsState();
}

class _ViewComplaintsState extends State<ViewComplaints> {
  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color gold = const Color(0xFFC59A6D);
  final Color darkCard = const Color(0xFF1A1A1A);

  List complaints = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await supabase
          .from('tbl_complaint')
          .select('*, tbl_user(user_name, user_photo)')
          .order('complaint_id', ascending: false);
      setState(() {
        complaints = response;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => loading = false);
    }
  }

  Future<void> updateReply(int id, String reply) async {
    await supabase.from('tbl_complaint').update({
      'complaint_reply': reply,
      'complaint_status': 1,
    }).eq('complaint_id', id);
    fetchComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "View Complaints",
      child: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC59A6D)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final item = complaints[index];
                final user = item['tbl_user'];
                final bool isReplied = item['complaint_status'].toString() != "0";

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gold.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: gold.withOpacity(0.3), width: 1.5),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(user?['user_photo'] ?? ""),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?['user_name'] ?? "Unknown User",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                item['complaint_date'] ?? "",
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isReplied ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isReplied ? "RESOLVED" : "PENDING",
                              style: TextStyle(
                                color: isReplied ? Colors.greenAccent : Colors.orangeAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(item['complaint_title'] ?? "", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(item['complaint_content'] ?? "", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.4)),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(color: Colors.white10, height: 1),
                      ),
                      
                      // ✅ CONDITIONAL REPLY OPTION
                      if (!isReplied)
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _showReplyDialog(int.parse(item['complaint_id'].toString())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.reply, size: 18),
                            label: Text("REPLY", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 14),
                                  const SizedBox(width: 8),
                                  Text("ADMIN RESPONSE", style: GoogleFonts.outfit(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['complaint_reply'] ?? "No reply recorded",
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showReplyDialog(int id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCard,
        title: Text("Send Reply", style: GoogleFonts.outfit(color: gold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Enter reply", hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              updateReply(id, controller.text);
              Navigator.pop(context);
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }
}
