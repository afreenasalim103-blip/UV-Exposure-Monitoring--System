import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/complaint.dart';
import 'package:user_app/feedback.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const Color bgBlack  = Color(0xFF0A0A0F);
  static const Color glass    = Color(0xFF1E1E2E);
  static const Color gold     = Color(0xFFC59A6D);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgBlack,

        appBar: AppBar(
          backgroundColor: bgBlack,
          elevation: 0,
          title: Text(
            "Support",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorColor: gold,
            labelColor: gold,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: "Complaint"),
              Tab(text: "Feedback"),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            Complaint(),
            FeedbackPage(),
          ],
        ),
      ),
    );
  }
}