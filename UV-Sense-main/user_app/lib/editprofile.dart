import 'package:flutter/material.dart';
import 'package:user_app/main.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {

  /// Luxury Colors
  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);
  final Color copper = const Color(0xFF7A4E2D);
  final Color glass = const Color(0xFF262626);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  String? gender;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      final data = await supabase.from('tbl_user').select().eq('user_id', user!.id).single();
      setState(() {
        nameController.text = data['user_name'] ?? '';
        emailController.text = data['user_email'] ?? '';
        contactController.text = data['user_contact'] ?? '';
        gender = data['user_gender'];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty"), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final user = supabase.auth.currentUser;
      await supabase.from('tbl_user').update({
        'user_name': nameController.text.trim(),
        'user_contact': contactController.text.trim(),
        'user_gender': gender,
      }).eq('user_id', user!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
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
    if (loading) {
      return Scaffold(
        backgroundColor: bgBlack,
        body: Center(child: CircularProgressIndicator(color: gold)),
      );
    }

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
                  BoxShadow(
                    color: gold.withOpacity(.25),
                    blurRadius: 40,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(.7),
                    blurRadius: 25,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),

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
                    child: const Icon(Icons.edit, color: Colors.black, size: 35),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Edit Profile",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),

                  const SizedBox(height: 30),

                  /// NAME
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

                  const SizedBox(height: 20),

                  /// EMAIL (read-only)
                  TextFormField(
                    controller: emailController,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white54),
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: Icon(Icons.email, color: gold.withOpacity(.5)),
                      filled: true,
                      fillColor: glass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// CONTACT
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

                  const SizedBox(height: 20),

                  /// GENDER DROPDOWN
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    dropdownColor: darkCard,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Gender",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: Icon(Icons.person_outline, color: gold),
                      filled: true,
                      fillColor: glass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male", style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: "Female", child: Text("Female", style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: "Other", child: Text("Other", style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (value) => setState(() => gender = value),
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
                      onPressed: saving ? null : _updateProfile,
                      child: saving
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              "SAVE CHANGES",
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
    );
  }
}