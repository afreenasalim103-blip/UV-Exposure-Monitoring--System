import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  final TextEditingController categoryController = TextEditingController();
  List categoryList = [];
  bool isLoading = true;
  bool isFormVisible = false;
  int? editingId;

  final Color gold = const Color(0xFFC59A6D);
  final Color darkCard = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    fetchCategory();
  }

  Future<void> fetchCategory() async {
    final response = await supabase.from('tbl_category').select().order('category_id', ascending: false);
    setState(() {
      categoryList = response;
      isLoading = false;
    });
  }

  Future<void> handleSubmit() async {
    final name = categoryController.text.trim();
    if (name.isEmpty) return;

    if (editingId == null) {
      await supabase.from('tbl_category').insert({'category_name': name});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category Added")));
    } else {
      await supabase.from('tbl_category').update({'category_name': name}).eq('category_id', editingId!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category Updated")));
    }
    
    cancelForm();
    fetchCategory();
  }

  void cancelForm() {
    setState(() {
      categoryController.clear();
      editingId = null;
      isFormVisible = false;
    });
  }

  Future<void> delete(int id) async {
    await supabase.from('tbl_category').delete().eq('category_id', id);
    fetchCategory();
  }

  void startEdit(int id, String name) {
    setState(() {
      categoryController.text = name;
      editingId = id;
      isFormVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "Product Categories",
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            /// Header
            Row(
              children: [
                Text("Category Management", style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (!isFormVisible)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => isFormVisible = true),
                    icon: const Icon(Icons.add),
                    label: const Text("ADD NEW ITEM"),
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
                            controller: categoryController,
                            autofocus: true,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Enter Name...",
                              hintStyle: const TextStyle(color: Colors.white30),
                              prefixIcon: Icon(Icons.category_rounded, color: gold, size: 20),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.02),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: handleSubmit,
                          style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(editingId == null ? "SUBMIT ITEM" : "UPDATE ITEM", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        TextButton(onPressed: cancelForm, child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
                      ],
                    ),
                  ],
                ),
              ),

            /// List Table
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: gold))
                  : categoryList.isEmpty 
                    ? const Center(child: Text("No items available.", style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                      itemCount: categoryList.length,
                      itemBuilder: (context, index) {
                        final cat = categoryList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(color: darkCard, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.03))),
                          child: Row(
                            children: [
                              CircleAvatar(backgroundColor: gold.withOpacity(0.1), radius: 18, child: Icon(Icons.grid_view_rounded, color: gold, size: 16)),
                              const SizedBox(width: 20),
                              Text(cat['category_name'] ?? "", style: GoogleFonts.outfit(color: Colors.white, fontSize: 15)),
                              const Spacer(),
                              IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent), onPressed: () => startEdit(cat['category_id'], cat['category_name'])),
                              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => delete(cat['category_id'])),
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