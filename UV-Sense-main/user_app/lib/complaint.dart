import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Complaint extends StatefulWidget {
  const Complaint({super.key});

  @override
  State<Complaint> createState() => _ComplaintState();
}

class _ComplaintState extends State<Complaint> {

  /// Colors
  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);
  final Color copper = const Color(0xFF7A4E2D);
  final Color glass = const Color(0xFF262626);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  List complaints = [];
  bool isLoading = true;

  /// INIT
  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  /// FETCH COMPLAINTS
  Future<void> fetchComplaints() async {
    final supabase = Supabase.instance.client;

    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final data = await supabase
          .from('tbl_complaint')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        complaints = data;
        isLoading = false;
      });

    } catch (e) {
      print("Error fetching complaints: $e");
      setState(() => isLoading = false);
    }
  }

  /// SUBMIT
  Future<void> submitComplaint() async {

    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;

    try {

      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      await supabase.from('tbl_complaint').insert({
        'user_id': user.id,
        'complaint_title': titleController.text.trim(),
        'complaint_content': contentController.text.trim(),
        'complaint_status': 0,
      });

      await fetchComplaints(); // 🔥 refresh list

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complaint Submitted Successfully!")),
      );

      titleController.clear();
      contentController.clear();

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
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

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(25),

          child: Column(

            children: [

              /// FORM CARD
              Container(

                padding: const EdgeInsets.all(25),

                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: gold.withOpacity(.4)),
                ),

                child: Form(
                  key: _formKey,
                  child: Column(

                    children: [

                      const Text(
                        "Submit Complaint",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// TITLE
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Title",
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: glass,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter title" : null,
                      ),

                      const SizedBox(height: 15),

                      /// CONTENT
                      TextFormField(
                        controller: contentController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Complaint Content",
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: glass,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter content" : null,
                      ),

                      const SizedBox(height: 20),

                      /// BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                          ),
                          onPressed: submitComplaint,
                          child: const Text(
                            "Submit",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// LIST TITLE
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "My Complaints",
                  style: TextStyle(
                    color: gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              /// LIST
              isLoading
                  ? const CircularProgressIndicator()
                  : complaints.isEmpty
                      ? const Text(
                          "No complaints yet",
                          style: TextStyle(color: Colors.white38),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: complaints.length,
                          itemBuilder: (context, index) {

                            final c = complaints[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: glass,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: gold.withOpacity(.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    c['complaint_title'] ?? "",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    c['complaint_content'] ?? "",
                                    style: const TextStyle(color: Colors.white70),
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [

                                      Text(
                                        (c['complaint_status'].toString() == "1") ? "Resolved" : "Pending",
                                        style: TextStyle(
                                          color: (c['complaint_status'].toString() == "1")
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      Text(
                                        (c['created_at'] ?? "")
                                            .toString()
                                            .substring(0, 10),
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}