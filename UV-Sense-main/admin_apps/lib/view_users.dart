import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class AdminViewUsers extends StatefulWidget {
  const AdminViewUsers({super.key});

  @override
  State<AdminViewUsers> createState() => _AdminViewUsersState();
}

class _AdminViewUsersState extends State<AdminViewUsers> {
  List users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await supabase.from('tbl_user').select().order('user_id');
      setState(() {
        users = response;
        loading = false;
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
      setState(() => loading = false);
    }
  }

  Future<void> toggleStatus(String id, int currentStatus) async {
    int newStatus = currentStatus == 1 ? 0 : 1;
    await supabase.from('tbl_user').update({'user_status': newStatus}).eq('user_id', id);
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SidebarWrapper(title: "Users", child: Center(child: CircularProgressIndicator(color: Color(0xFFC59A6D))));

    return SidebarWrapper(
      title: "User Management",
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          int status = user['user_status'] ?? 1; // 1 for active, 0 for blocked

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(user['user_photo'] ?? "https://via.placeholder.com/150"),
              ),
              title: Text(
                user['user_name'] ?? 'Unknown User',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['user_email'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 1 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      status == 1 ? "ACTIVE" : "BLOCKED",
                      style: TextStyle(color: status == 1 ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => toggleStatus(user['user_id'], status),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == 1 ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                  foregroundColor: status == 1 ? Colors.redAccent : Colors.greenAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(status == 1 ? "Block" : "Unblock"),
              ),
            ),
          );
        },
      ),
    );
  }
}