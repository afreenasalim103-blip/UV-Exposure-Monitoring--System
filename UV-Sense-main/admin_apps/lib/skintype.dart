import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class SkinType extends StatefulWidget {
  const SkinType({super.key});

  @override
  State<SkinType> createState() => _SkinTypeState();
}

class _SkinTypeState extends State<SkinType> {
  final TextEditingController typeController = TextEditingController();
  List skinList = [];
  bool isLoading = true;
  bool isFormVisible = false;
  int? editingId;

  final Color gold = const Color(0xFFC59A6D);
  final Color darkCard = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    fetchSkinTypes();
  }

  Future<void> fetchSkinTypes() async {
    final response = await supabase.from('tbl_skintype').select().order('type_id', ascending: false);
    setState(() {
      skinList = List.from(response);
      isLoading = false;
    });
  }

  Future<void> handleSubmit() async {
    final name = typeController.text.trim();
    if (name.isEmpty) return;

    if (editingId == null) {
      await supabase.from('tbl_skintype').insert({'skintype_name': name});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Type Added")));
    } else {
      await supabase.from('tbl_skintype').update({'skintype_name': name}).eq('type_id', editingId!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Type Updated")));
    }
    
    cancelForm();
    fetchSkinTypes();
  }

  void cancelForm() {
    setState(() {
      typeController.clear();
      editingId = null;
      isFormVisible = false;
    });
  }

  Future<void> delete(int id) async {
    await supabase.from('tbl_skintype').delete().eq('type_id', id);
    fetchSkinTypes();
  }

  void startEdit(int id, String name) {
    setState(() {
      typeController.text = name;
      editingId = id;
      isFormVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "Skin Identification",
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            /// Header
            Row(
              children: [
                Text("Dermatological Types", style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (!isFormVisible)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => isFormVisible = true),
                    icon: const Icon(Icons.face_retouching_natural_rounded),
                    label: const Text("NEW TYPE"),
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
                            controller: typeController,
                            autofocus: true,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Skin Type Identity...",
                              hintStyle: const TextStyle(color: Colors.white30),
                              prefixIcon: Icon(Icons.spa_rounded, color: gold, size: 20),
                              filled: true, fillColor: Colors.white.withOpacity(0.02),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: handleSubmit,
                          style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(editingId == null ? "SAVE TYPE" : "UPDATE TYPE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        TextButton(onPressed: cancelForm, child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
                      ],
                    ),
                  ],
                ),
              ),

            /// Active List
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: gold))
                  : skinList.isEmpty 
                    ? const Center(child: Text("No types identified.", style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                      itemCount: skinList.length,
                      itemBuilder: (context, index) {
                        final s = skinList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(color: darkCard, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.03))),
                          child: Row(
                            children: [
                              CircleAvatar(backgroundColor: gold.withOpacity(0.1), radius: 18, child: Icon(Icons.spa_rounded, color: gold, size: 16)),
                              const SizedBox(width: 20),
                              Text(s['skintype_name'] ?? "", style: GoogleFonts.outfit(color: Colors.white, fontSize: 15)),
                              const Spacer(),
                              IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent), onPressed: () => startEdit(s['type_id'], s['skintype_name'])),
                              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => delete(s['type_id'])),
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