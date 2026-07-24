import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class Colour extends StatefulWidget {
  const Colour({super.key});

  @override
  State<Colour> createState() => _ColourState();
}

class _ColourState extends State<Colour> {
  final TextEditingController colourController = TextEditingController();
  List colourList = [];
  bool isLoading = true;
  bool isFormVisible = false;
  int? editingId;

  final Color gold = const Color(0xFFC59A6D);
  final Color darkCard = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    fetchColour();
  }

  Future<void> fetchColour() async {
    final response = await supabase.from('tbl_colour').select().order('colour_id', ascending: false);
    setState(() {
      colourList = response;
      isLoading = false;
    });
  }

  Future<void> handleSubmit() async {
    final name = colourController.text.trim();
    if (name.isEmpty) return;

    if (editingId == null) {
      await supabase.from('tbl_colour').insert({'colour_name': name});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Color Saved")));
    } else {
      await supabase.from('tbl_colour').update({'colour_name': name}).eq('colour_id', editingId!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Color Updated")));
    }
    
    cancelForm();
    fetchColour();
  }

  void cancelForm() {
    setState(() {
      colourController.clear();
      editingId = null;
      isFormVisible = false;
    });
  }

  Future<void> delete(int id) async {
    await supabase.from('tbl_colour').delete().eq('colour_id', id);
    fetchColour();
  }

  void startEdit(int id, String name) {
    setState(() {
      colourController.text = name;
      editingId = id;
      isFormVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "Design Assets",
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            /// Header
            Row(
              children: [
                Text("Theme Palette", style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (!isFormVisible)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => isFormVisible = true),
                    icon: const Icon(Icons.colorize_rounded),
                    label: const Text("NEW COLOR"),
                    style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            /// Form UI
            if (isFormVisible)
              Container(
                margin: const EdgeInsets.only(bottom: 30),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: gold.withOpacity(0.1), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: colourController,
                            autofocus: true,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Color Label (e.g. Matte Gold)...",
                              hintStyle: const TextStyle(color: Colors.white30),
                              prefixIcon: Icon(Icons.palette_rounded, color: gold, size: 20),
                              filled: true, fillColor: Colors.white.withOpacity(0.02),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: handleSubmit,
                          style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(editingId == null ? "ADD COLOR" : "UPDATE COLOR", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        TextButton(onPressed: cancelForm, child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
                      ],
                    ),
                  ],
                ),
              ),

            /// Data List
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: gold))
                  : colourList.isEmpty 
                    ? const Center(child: Text("No colors tracked.", style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                      itemCount: colourList.length,
                      itemBuilder: (context, index) {
                        final c = colourList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(color: darkCard, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.03))),
                          child: Row(
                            children: [
                              CircleAvatar(backgroundColor: gold.withOpacity(0.1), radius: 18, child: Icon(Icons.palette, color: gold, size: 16)),
                              const SizedBox(width: 20),
                              Text(c['colour_name'] ?? "", style: GoogleFonts.outfit(color: Colors.white, fontSize: 15)),
                              const Spacer(),
                              IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent), onPressed: () => startEdit(c['colour_id'], c['colour_name'])),
                              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => delete(c['colour_id'])),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}