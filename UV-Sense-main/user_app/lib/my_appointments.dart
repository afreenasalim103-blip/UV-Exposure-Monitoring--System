import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class UserMyAppointments extends StatefulWidget {
  const UserMyAppointments({super.key});

  @override
  State<UserMyAppointments> createState() => _UserMyAppointmentsState();
}

class _UserMyAppointmentsState extends State<UserMyAppointments> {
  static const Color bgBlack = Color(0xFF0A0A0F);
  static const Color glass   = Color(0xFF1E1E2E);
  static const Color gold    = Color(0xFFC59A6D);
  static const Color copper  = Color(0xFF7A4E2D);

  List appointments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    final user = supabase.auth.currentUser;

    final response = await supabase
        .from('tbl_appointment')
        .select('''
          appointment_date,
          appointment_time,
          appointment_status,
          tbl_dermatologist(
            dermatologist_name,
            dermatologist_photo
          )
        ''')
        .eq('user_id', user!.id)
        .order('appointment_date', ascending: false);

    setState(() {
      appointments = response;
      loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return const Color(0xFF4CAF50);
      case 'rejected': return const Color(0xFFF44336);
      default: return const Color(0xFFFF9800);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,

      body: CustomScrollView(
        slivers: [

          /// APP BAR
          SliverAppBar(
            backgroundColor: bgBlack,
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            iconTheme: const IconThemeData(color: gold),

            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [copper.withOpacity(.3), bgBlack],
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
                        Text(
                          "My Appointments",
                          style: GoogleFonts.outfit(
                            color: gold,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// LOADING
          if (loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: gold),
              ),
            )

          /// EMPTY
          else if (appointments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  "No Appointments",
                  style: GoogleFonts.outfit(color: Colors.white38),
                ),
              ),
            )

          /// LIST
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildCard(appointments[i]),
                  childCount: appointments.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Map data) {
    final doctor = data['tbl_dermatologist'];
    final status = data['appointment_status'] ?? 'pending';
    final statusColor = _statusColor(status);

    final date = data['appointment_date']?.toString().split('T')[0] ?? '';
    final time = data['appointment_time'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withOpacity(.2)),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Row(
          children: [

            /// AVATAR
            CircleAvatar(
              radius: 30,
              backgroundColor: glass,
              backgroundImage: doctor['dermatologist_photo'] != null
                  ? NetworkImage(doctor['dermatologist_photo'])
                  : null,
              child: doctor['dermatologist_photo'] == null
                  ? const Icon(Icons.person, color: gold)
                  : null,
            ),

            const SizedBox(width: 12),

            /// INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor['dermatologist_name'] ?? '',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$date • $time",
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            /// ✅ FIXED STATUS (NO OVERFLOW)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(status), color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: GoogleFonts.outfit(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}