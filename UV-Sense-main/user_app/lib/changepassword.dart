import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/main.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {

  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);
  final Color copper = const Color(0xFF7A4E2D);
  final Color glass = const Color(0xFF262626);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool hideNewPassword = true;
  bool hideConfirmPassword = true;
  bool saving = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: newPasswordController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bgBlack,
              const Color(0xFF141414),
              copper.withOpacity(.4),
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
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: darkCard,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: gold.withOpacity(.5)),
                boxShadow: [
                  BoxShadow(color: gold.withOpacity(.25), blurRadius: 40),
                  BoxShadow(color: Colors.black.withOpacity(.7), blurRadius: 25, offset: const Offset(0, 15)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [gold, copper]),
                        boxShadow: [BoxShadow(color: gold.withOpacity(.6), blurRadius: 35)],
                      ),
                      child: const Icon(Icons.lock_reset, color: Colors.black, size: 35),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Change Password",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),

                    const SizedBox(height: 30),

                    /// NEW PASSWORD
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: hideNewPassword,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Enter new password";
                        if (value.length < 6) return "Minimum 6 characters";
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "New Password",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.lock, color: gold),
                        suffixIcon: IconButton(
                          icon: Icon(hideNewPassword ? Icons.visibility_off : Icons.visibility, color: gold),
                          onPressed: () => setState(() => hideNewPassword = !hideNewPassword),
                        ),
                        filled: true,
                        fillColor: glass,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        errorStyle: const TextStyle(color: Colors.redAccent),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// CONFIRM PASSWORD
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: hideConfirmPassword,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value != newPasswordController.text) return "Passwords do not match";
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Confirm Password",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.lock_outline, color: gold),
                        suffixIcon: IconButton(
                          icon: Icon(hideConfirmPassword ? Icons.visibility_off : Icons.visibility, color: gold),
                          onPressed: () => setState(() => hideConfirmPassword = !hideConfirmPassword),
                        ),
                        filled: true,
                        fillColor: glass,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        errorStyle: const TextStyle(color: Colors.redAccent),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// SUBMIT
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          elevation: 12,
                          shadowColor: gold.withOpacity(.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: saving ? null : _changePassword,
                        child: saving
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                                "UPDATE PASSWORD",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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