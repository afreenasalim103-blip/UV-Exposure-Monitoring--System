import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class Level extends StatefulWidget {
  const Level({super.key});

  @override
  State<Level> createState() => _LevelState();
}

class _LevelState extends State<Level> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List levelList = [];
  bool isLoading = true;
  bool isFormVisible = false;
  int? editingId;

  final Color gold = const Color(0xFFC59A6D);
  final Color darkCard = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    fetchLevel();
  }

  Future<void> fetchLevel() async {
    final response = await supabase.from('tbl_level').select().order('level_id', ascending: false);
    setState(() {
      levelList = response;
      isLoading = false;
    });
  }

  Future<void> handleSubmit() async {
    if (nameController.text.isEmpty || descriptionController.text.isEmpty) return;
    
    final data = {
      'level_name': nameController.text.trim(),
      'level_description': descriptionController.text.trim(),
    };

    if (editingId == null) {
      await supabase.from('tbl_level').insert(data);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Level Created")));
    } else {
      await supabase.from('tbl_level').update(data).eq('level_id', editingId!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Level Updated")));
    }
    
    cancelForm();
    fetchLevel();
  }

  void cancelForm() {
    setState(() {
      nameController.clear();
      descriptionController.clear();
      editingId = null;
      isFormVisible = false;
    });
  }

  Future<void> delete(int id) async {
    await supabase.from('tbl_level').delete().eq('level_id', id);
    fetchLevel();
  }

  void startEdit(Map l) {
    setState(() {
      nameController.text = l['level_name'];
      descriptionController.text = l['level_description'];
      editingId = l['level_id'];
      isFormVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "UV Levels",
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            /// Header
            Row(
              children: [
                Text("Exposure Standards", style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (!isFormVisible)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => isFormVisible = true),
                    icon: const Icon(Icons.add_moderator),
                    label: const Text("CREATE LEVEL"),
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
                          child: Column(
                            children: [
                              TextField(
                                controller: nameController,
                                style: GoogleFonts.outfit(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Standard Label (e.g. Extreme)",
                                  hintStyle: const TextStyle(color: Colors.white30),
                                  prefixIcon: Icon(Icons.warning_amber_rounded, color: gold, size: 20),
                                  filled: true, fillColor: Colors.white.withOpacity(0.02),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextField(
                                controller: descriptionController,
                                style: GoogleFonts.outfit(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Health advice or threshold...",
                                  hintStyle: const TextStyle(color: Colors.white30),
                                  prefixIcon: Icon(Icons.description_rounded, color: gold, size: 20),
                                  filled: true, fillColor: Colors.white.withOpacity(0.02),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 25),
                        Column(
                          children: [
                            SizedBox(
                              height: 60, width: 140,
                              child: ElevatedButton(
                                onPressed: handleSubmit,
                                style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                                child: Text(editingId == null ? "SAVE" : "UPDATE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(onPressed: cancelForm, child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            /// List Grid
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: gold))
                  : levelList.isEmpty 
                    ? const Center(child: Text("No standards defined.", style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                      itemCount: levelList.length,
                      itemBuilder: (context, index) {
                        final l = levelList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                          decoration: BoxDecoration(color: darkCard, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.03))),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l['level_name'] ?? "", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 5),
                                    Text(l['level_description'] ?? "", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent), onPressed: () => startEdit(l)),
                              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => delete(l['level_id'])),
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