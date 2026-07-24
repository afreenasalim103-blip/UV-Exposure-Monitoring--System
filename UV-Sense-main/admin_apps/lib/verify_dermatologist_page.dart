import 'package:flutter/material.dart';
import 'main.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyDermatologistPage extends StatelessWidget {
  final Map data;

  const VerifyDermatologistPage({super.key, required this.data});

  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);

  Future<void> updateStatus(BuildContext context, String status) async {
    await supabase
        .from('tbl_dermatologist')
        .update({'dermatologist_status': status})
        .eq('dermatologist_id', data['dermatologist_id']);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Verify Dermatologist",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),

          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(30),

            decoration: BoxDecoration(
              color: darkCard,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: gold.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: gold.withOpacity(0.15), blurRadius: 30),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// PROFILE SECTION
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: gold.withOpacity(0.2),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: (data['dermatologist_photo'] != null)
                              ? NetworkImage(data['dermatologist_photo'])
                              : null,
                          child: (data['dermatologist_photo'] == null)
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        data['dermatologist_name'],
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// INFO CARD
                _buildInfo("Email", data['dermatologist_email']),
                const SizedBox(height: 10),
                _buildInfo("Contact", data['dermatologist_contact']),

                const SizedBox(height: 30),

                /// CERTIFICATE TITLE
                Text(
                  "Medical Certificate",
                  style: GoogleFonts.outfit(
                    color: gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                /// CERTIFICATE IMAGE
                // if (data['dermatologist_certificate'] != null)
                //   GestureDetector(
                //     onTap: () {
                //       showDialog(
                //         context: context,
                //         builder: (_) => Dialog(
                //           backgroundColor: Colors.black,
                //           child: InteractiveViewer(
                //             child: Image.network(
                //               data['dermatologist_certificate']!,
                //             ),
                //           ),
                //         ),
                //       );
                //     },
                //     child: Container(
                //       height: 250,
                //       width: double.infinity,
                //       decoration: BoxDecoration(
                //         borderRadius: BorderRadius.circular(20),
                //         border: Border.all(color: gold.withOpacity(0.3)),
                //       ),
                //       child: ClipRRect(
                //         borderRadius: BorderRadius.circular(20),
                //         child: Image.network(
                //           data['dermatologist_certificate']!,
                //           fit: BoxFit.cover,
                //           errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
                //         ),
                //       ),
                //     ),
                //   )
                // else
                //   const Center(child: Text("No certificate uploaded", style: TextStyle(color: Colors.white24))),
                const SizedBox(height: 40),

                /// ACTION BUTTONS
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Close View",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 INFO TILE
  Widget _buildInfo(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
