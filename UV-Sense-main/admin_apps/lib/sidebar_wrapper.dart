import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_apps/main.dart';

// ✅ REQUIRED IMPORTS ONLY
import 'package:admin_apps/admin_home.dart';
import 'package:admin_apps/level.dart';
import 'package:admin_apps/category.dart';
import 'package:admin_apps/skintype.dart';
import 'package:admin_apps/addproduct.dart';
import 'package:admin_apps/myproducts.dart';
import 'package:admin_apps/view_booking.dart';
import 'package:admin_apps/view_dermatologist.dart';
import 'package:admin_apps/view_users.dart';
import 'package:admin_apps/view_complaints.dart';
import 'package:admin_apps/manage_subscriptions.dart';
import 'package:admin_apps/manage_uv_recommendations.dart';
import 'package:admin_apps/manage_chatbot_faq.dart';
import 'package:admin_apps/global_exposure.dart';

class SidebarWrapper extends StatefulWidget {
  final Widget child;
  final String title;

  const SidebarWrapper({super.key, required this.child, required this.title});

  @override
  State<SidebarWrapper> createState() => _SidebarWrapperState();
}

class _SidebarWrapperState extends State<SidebarWrapper> {
  static bool isExpanded = true;

  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);
  final Color sidebarColor = const Color(0xFF151515);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: Row(
        children: [

          /// 🔥 SIDEBAR (PREMIUM UI)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isExpanded ? 260 : 90,
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: sidebarColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 20,
                  offset: const Offset(5, 10),
                ),
              ],
            ),

            child: Column(
              children: [
                const SizedBox(height: 25),

                /// HEADER
                _buildSidebarHeader(),

                const SizedBox(height: 25),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [

                      _buildSidebarItem(Icons.dashboard_rounded, "Dashboard", const AdminHome()),
                      _buildSidebarItem(Icons.warning_amber_rounded, "UV Levels", const Level()),
                      _buildSidebarItem(Icons.sunny_snowing, "UV Guide", const ManageUvRecommendations()),
                      _buildSidebarItem(Icons.analytics_outlined, "Global Exposure", const GlobalExposure()),
                      _buildSidebarItem(Icons.smart_toy_rounded, "Chatbot QA", const ManageChatbotFaq()),
                      _buildSidebarItem(Icons.category_rounded, "Categories", const Category()),
                      _buildSidebarItem(Icons.face_rounded, "Skin Types", const SkinType()),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                        child: Text(
                          "ACCOUNT",
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      _buildSidebarItem(Icons.add_business_rounded, "Add Product", const AddProduct()),
                      _buildSidebarItem(Icons.inventory_2_rounded, "My Products", const MyProducts()),
                      _buildSidebarItem(Icons.shopping_bag_rounded, "Orders", const AdminViewBooking()),
                      _buildSidebarItem(Icons.medical_services_rounded, "Dermatologists", const AdminViewDermatologist()),
                      _buildSidebarItem(Icons.people_alt_rounded, "Users", const AdminViewUsers()),
                      _buildSidebarItem(Icons.chat_bubble_rounded, "Complaints", const ViewComplaints()),
                      _buildSidebarItem(Icons.card_membership_rounded, "Subscriptions", const ManageSubscriptions()),
                    ],
                  ),
                ),

                /// COLLAPSE BUTTON
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_double_arrow_left
                        : Icons.keyboard_double_arrow_right,
                    color: Colors.white24,
                  ),
                  onPressed: () {
                    setState(() => isExpanded = !isExpanded);
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),

          /// 🔥 MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 5),
                    decoration: BoxDecoration(
                      color: darkCard,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 HEADER
  Widget _buildSidebarHeader() {
    return isExpanded
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, color: gold, size: 22),
              const SizedBox(width: 10),
              Text(
                "UVORA",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          )
        : Icon(Icons.shield_rounded, color: gold);
  }

  /// 🔹 SIDEBAR ITEM
  Widget _buildSidebarItem(IconData icon, String title, Widget page) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: Icon(icon, color: Colors.white60, size: 18),

      title: isExpanded
          ? Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 13,
              ),
            )
          : null,

      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  /// 🔹 TOP BAR
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),

      child: Row(
        children: [
          Text(
            widget.title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          TextButton.icon(
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            label: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}