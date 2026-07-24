import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';

class UserViewDermatologist extends StatefulWidget {
  const UserViewDermatologist({super.key});

  @override
  State<UserViewDermatologist> createState() => _UserViewDermatologistState();
}

class _UserViewDermatologistState extends State<UserViewDermatologist> {
  static const Color bgBlack  = Color(0xFF0A0A0F);
  static const Color glass    = Color(0xFF1E1E2E);
  static const Color gold     = Color(0xFFC59A6D);
  static const Color copper   = Color(0xFF7A4E2D);

  List dermatologists = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDermatologists();
  }

  Future<void> fetchDermatologists() async {
    try {
      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_status', 'accepted');
      setState(() { dermatologists = response; loading = false; });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: CustomScrollView(
        slivers: [
          /// ── APP BAR ──
          SliverAppBar(
            backgroundColor: bgBlack,
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [copper.withOpacity(.35), bgBlack],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Find Your",
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
                        Text("Dermatologist",
                            style: GoogleFonts.outfit(
                                color: gold, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),

      /// ── LIST ──
      if (loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2)),
            )
          else if (dermatologists.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.medical_services_outlined, size: 80, color: gold.withOpacity(.3)),
                    const SizedBox(height: 16),
                    Text("No Dermatologists Available",
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildDoctorCard(dermatologists[i]),
                  childCount: dermatologists.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold.withOpacity(.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            /// Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: glass,
                  backgroundImage: data['dermatologist_photo'] != null
                      ? NetworkImage(data['dermatologist_photo'])
                      : null,
                  child: data['dermatologist_photo'] == null
                      ? const Icon(Icons.person, color: gold, size: 30)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: glass, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            /// Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['dermatologist_name'] ?? '',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: Colors.white38, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['dermatologist_email'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final phone = data['dermatologist_contact'];
                        if (phone != null && phone.isNotEmpty) {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: phone,
                          );
                          await launchUrl(launchUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Phone number not available")),
                          );
                        }
                      },
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: Text("Call Now",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}