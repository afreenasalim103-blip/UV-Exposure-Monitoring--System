import 'package:admin_apps/admin_home.dart';
import 'package:admin_apps/data_store.dart';
import 'package:admin_apps/main.dart';
import 'package:flutter/material.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _loading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Luxury Colors (same used in other screens)
  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);
  final Color copper = const Color(0xFF7A4E2D);
  final Color glass = const Color(0xFF262626);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {

    if (_formKey.currentState!.validate()) {

      setState(() => _loading = true);

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        final response = await supabase
            .from('tbl_admin')
            .select()
            .eq('admin_email', email)
            .eq('admin_password', password)
            .maybeSingle();

        if (mounted && response != null) {

          setState(() => _loading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Successful!")),
          );

          DataStore.adminId = response['id'];

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHome()),
          );
        } else {
          if (mounted) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid Email or Password")),
            );
          }
        }

      } catch (e) {

        if (mounted) {
          setState(() => _loading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login Failed: ${e.toString()}")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        /// Luxury Gradient Background
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

                  /// Gold Glow
                  BoxShadow(
                    color: gold.withOpacity(.25),
                    blurRadius: 40,
                    spreadRadius: 1,
                  ),

                  /// Depth Shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(.7),
                    blurRadius: 25,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),

              child: Form(

                key: _formKey,

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
                      "Admin Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                      ),
                    ),

                    const SizedBox(height: 35),

                    /// Email Field
                    TextFormField(

                      controller: _emailController,

                      validator: (value) =>
                          (value == null || value.isEmpty)
                              ? "Email is required"
                              : null,

                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(

                        hintText: "Enter your email",

                        hintStyle: const TextStyle(
                          color: Colors.white38,
                        ),

                        prefixIcon: Icon(Icons.email_outlined, color: gold),

                        filled: true,

                        fillColor: glass,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// Password Field
                    TextFormField(

                      controller: _passwordController,

                      obscureText: _obscurePassword,

                      validator: (value) =>
                          (value == null || value.isEmpty)
                              ? "Password is required"
                              : null,

                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(

                        hintText: "Enter your password",

                        hintStyle: const TextStyle(
                          color: Colors.white38,
                        ),

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

                    const SizedBox(height: 35),

                    /// Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(

                        onPressed: _loading ? null : _handleLogin,

                        style: ElevatedButton.styleFrom(

                          backgroundColor: gold,

                          elevation: 12,

                          shadowColor: gold.withOpacity(.6),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),

                        child: _loading

                            ? const CircularProgressIndicator(
                                color: Colors.black)

                            : const Text(
                                "Log In",
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
      ),
    );
  }
}