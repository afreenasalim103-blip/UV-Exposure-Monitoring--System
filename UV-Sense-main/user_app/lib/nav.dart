import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/myprofile.dart';
import 'package:user_app/view_dermatologist.dart';
import 'package:user_app/userhomepage.dart';
import 'viewproducts.dart';

import 'package:user_app/subscription_page.dart';
import 'package:user_app/main.dart';

class Navpage extends StatefulWidget {
  const Navpage({super.key});

  @override
  State<Navpage> createState() => _NavpageState();
}

class _NavpageState extends State<Navpage> {
  static const Color bgBlack = Color(0xFF0A0A0F);
  static const Color glass   = Color(0xFF1E1E2E);
  static const Color gold    = Color(0xFFC59A6D);

  int _selectedIndex = 0;
  bool isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final sub = await supabase
            .from('tbl_user_subscription')
            .select()
            .eq('user_id', user.id)
            .eq('subscription_status', 'active')
            .maybeSingle();
        if (mounted) {
          setState(() {
            isSubscribed = sub != null;
          });
        }
      }
    } catch (_) {}
  }

  final List<Widget> _pages = const [
    UserHomePage(),
    ViewProducts(),
    UserViewDermatologist(),
    MyProfile(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded,                 label: "Home"),
    _NavItem(icon: Icons.storefront_rounded,            label: "Products"),
    _NavItem(icon: Icons.local_hospital_rounded,        label: "Doctors"),
    _NavItem(icon: Icons.person_rounded,                label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: glass,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(.07))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) => _buildNavItem(i)),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isActive = _selectedIndex == index;
    final item = _navItems[index];

    return GestureDetector(
      onTap: () {
         if (index == 2 && !isSubscribed) {
           _showUnlockDialog();
         } else {
           setState(() => _selectedIndex = index);
         }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? gold.withOpacity(.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: gold.withOpacity(.3)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: isActive ? gold : Colors.white38, size: 22),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: GoogleFonts.outfit(
                  color: gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: glass,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Premium Feature 💎", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold)),
        content: Text("Dermatologist sessions are reserved for our premium members. Unlock expert care now.", style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Maybe Later", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Go Premium", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
