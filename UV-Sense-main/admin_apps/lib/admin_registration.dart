import 'package:admin_apps/admin_login.dart';
import 'package:admin_apps/main.dart';
import 'package:flutter/material.dart';

class AdminRegistration extends StatefulWidget {
  const AdminRegistration({super.key});

  @override
  State<AdminRegistration> createState() => _AdminRegistrationState();
}

class _AdminRegistrationState extends State<AdminRegistration> {

  /// Luxury Colors
  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);
  final Color copper = const Color(0xFF7A4E2D);
  final Color glass = const Color(0xFF262626);

  TextEditingController nameController = TextEditingController();
  TextEditingController emailControler = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController contactController = TextEditingController();

  bool _obscurePassword = true;

  Future<void> adminReg() async {
    try {
      final name = nameController.text.trim();
      final email = emailControler.text.trim();
      final password = passwordController.text;
      final contact = contactController.text.trim();

      final String uniqueId = "admin_${DateTime.now().millisecondsSinceEpoch}";

      await supabase.from('tbl_admin').insert({
        "id": uniqueId,
        "admin_name": name,
        "admin_email": email,
        "admin_password": password,
        "admin_contact": contact
      });

      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminLogin()));
      }

    } catch (e) {
      print("Error $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        /// Luxury Background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bgBlack,
              const Color(0xFF141414),
              copper.withOpacity(.5),
              const Color(0xFF141414),
              bgBlack,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(

          child: SingleChildScrollView(

            padding: const EdgeInsets.all(30),

            child: Container(

              constraints: const BoxConstraints(maxWidth: 420),

              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 40,
              ),

              decoration: BoxDecoration(

                color: darkCard,

                borderRadius: BorderRadius.circular(30),

                border: Border.all(
                  color: gold.withOpacity(.5),
                ),

                boxShadow: [

                  /// Gold glow
                  BoxShadow(
                    color: gold.withOpacity(.25),
                    blurRadius: 40,
                    spreadRadius: 1,
                  ),

                  /// Shadow depth
                  BoxShadow(
                    color: Colors.black.withOpacity(.7),
                    blurRadius: 25,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// Header Icon
                  Container(

                    height: 80,
                    width: 80,

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,

                      gradient: LinearGradient(
                        colors: [gold, copper],
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: gold.withOpacity(.6),
                          blurRadius: 35,
                        )
                      ],
                    ),

                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.black,
                      size: 35,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Title
                  const Text(
                    "Admin Registration",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.3,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Name
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Name",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: Icon(Icons.person, color: gold),
                      filled: true,
                      fillColor: glass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// Email
                  TextFormField(
                    controller: emailControler,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: Icon(Icons.email_outlined, color: gold),
                      filled: true,
                      fillColor: glass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// Contact
                  TextFormField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Contact",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: Icon(Icons.phone, color: gold),
                      filled: true,
                      fillColor: glass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// Password
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: Icon(Icons.lock_outline, color: gold),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: gold,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: glass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        adminReg();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        elevation: 12,
                        shadowColor: gold.withOpacity(.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "SUBMIT",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}