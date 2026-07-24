import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {

  /// Luxury Colors
  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);
  final Color copper = const Color(0xFF7A4E2D);
  final Color glass = const Color(0xFF262626);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController contentController = TextEditingController();

  /// Submit Function
  void submitFeedback() {

    if (_formKey.currentState!.validate()) {

      String content = contentController.text;

      print("Feedback Submitted:");
      print("Content: $content");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Feedback Submitted Successfully!"),
        ),
      );

      contentController.clear();
    }
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
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

              constraints: const BoxConstraints(maxWidth: 600),

              padding: const EdgeInsets.all(35),

              decoration: BoxDecoration(

                color: darkCard,

                borderRadius: BorderRadius.circular(30),

                border: Border.all(color: gold.withOpacity(.5)),

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
                        Icons.feedback,
                        color: Colors.black,
                        size: 35,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Submit Feedback",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// Feedback Field
                    TextFormField(
                      controller: contentController,
                      maxLines: 6,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter your feedback",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.comment, color: gold),
                        filled: true,
                        fillColor: glass,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your feedback";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    /// Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(

                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          elevation: 12,
                          shadowColor: gold.withOpacity(.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),

                        onPressed: submitFeedback,

                        child: const Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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