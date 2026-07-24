import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/complaint.dart';
import 'package:user_app/main.dart';
import 'package:user_app/my_orders.dart';
import 'package:user_app/editprofile.dart';
import 'package:user_app/changepassword.dart';
import 'package:user_app/subscription_page.dart';
import 'package:user_app/user_login.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  static const Color bgBlack  = Color(0xFF0A0A0F);
  static const Color glass    = Color(0xFF1E1E2E);
  static const Color gold     = Color(0xFFC59A6D);
  static const Color copper   = Color(0xFF7A4E2D);

  String name  = "";
  String email = "";
  String photo = "";
  String skinType = "";
  List<dynamic> uvLogs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }
  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      final data = await supabase
          .from('tbl_user')
          .select('user_name, user_email, user_photo, tbl_skintype(skintype_name)') // Joined select
          .eq('user_id', user!.id)
          .single();
      
      final logs = await supabase
          .from('tbl_uv_log')
          .select()
          .eq('user_id', user.id)
          .order('logged_at', ascending: false)
          .limit(5);

      setState(() {
        name     = data['user_name'] ?? "User";
        email    = data['user_email'] ?? "";
        photo    = data['user_photo'] ?? "";
        // Extract from nested object
        skinType = data['tbl_skintype']?['skintype_name'] ?? "Not set";
        uvLogs   = logs;
        loading  = false;
      });
    } catch (e) {
      debugPrint("Profile load error: $e");
      setState(() => loading = false);
    }
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return "Unknown";
    final dt = DateTime.parse(timestamp);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
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
      body: loading
          ? const Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2))
          : CustomScrollView(
              slivers: [
                /// ── PROFILE HEADER ──
                SliverToBoxAdapter(child: _buildHeader()),

                /// ── STAT CHIPS ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Row(
                      children: [
                        _buildStatChip(Icons.spa_rounded, "Skin Type", skinType),
                        const SizedBox(width: 12),
                        _buildStatChip(Icons.shield_outlined, "Status", "Active"),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _sectionLabel("Recent Exposure"),
                  ),
                ),
                SliverToBoxAdapter(child: _buildUvLogsSection()),

                /// ── GENERAL SECTION ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: _sectionLabel("General"),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _buildGroup([
                      _buildOption(Icons.shopping_bag_rounded, "My Orders", "View purchase history",
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrders()))),
                      _buildDivider(),
                      _buildOption(Icons.headset_mic_rounded, "Complaint / Support", "Report an issue",
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Complaint()))),
                      _buildDivider(),
                      _buildOption(Icons.card_membership_rounded, "My Subscription", "Manage your premium plan",
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage()))),
                    ]),
                  ),
                ),

                /// ── ACCOUNT SECTION ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _sectionLabel("Account"),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _buildGroup([
                      _buildOption(Icons.edit_rounded, "Edit Profile", "Update your details",
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfile()))),
                      _buildDivider(),
                      _buildOption(Icons.lock_reset_rounded, "Change Password", "Update your password",
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePassword()))),
                    ]),
                  ),
                ),

                /// ── SESSION ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _sectionLabel("Session"),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
                    child: _buildGroup([
                      _buildOption(Icons.logout_rounded, "Logout", "Sign out of your account",
                          _handleLogout, isDestructive: true),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: glass,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Logout", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to logout?", style: GoogleFonts.outfit(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const UserLogin()),
                  (r) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Logout", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [copper.withOpacity(.3), bgBlack],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [gold, copper]),
                  boxShadow: [BoxShadow(color: gold.withOpacity(.4), blurRadius: 25, spreadRadius: 2)],
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: glass,
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? const Icon(Icons.person, size: 50, color: gold) : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: gold, shape: BoxShape.circle,
                    border: Border.all(color: bgBlack, width: 2)),
                child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(name,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(email,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: glass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gold.withOpacity(.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: gold, size: 20),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
            Text(value,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          color: gold.withOpacity(.6),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.white.withOpacity(.05), indent: 20, endIndent: 20);

  Widget _buildOption(IconData icon, String title, String sub, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : gold;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          color: isDestructive ? Colors.redAccent : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(sub, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 22),
          ],
        ),
      ),
    );
  }
  Widget _buildUvLogsSection() {
    if (uvLogs.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: uvLogs.length,
        itemBuilder: (ctx, i) {
          final log = uvLogs[i];
          final uv = (log['uv_index'] ?? 0.0).toDouble();
          final color = _getUvColor(uv);
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: glass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("UV $uv", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(_getTimeAgo(log['logged_at']), style: const TextStyle(color: Colors.white24, fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(log['location_name'] ?? "Global", style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }
}