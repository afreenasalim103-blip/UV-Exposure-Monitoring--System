import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_apps/main.dart';
import 'package:admin_apps/sidebar_wrapper.dart';

class ManageChatbotFaq extends StatefulWidget {
  const ManageChatbotFaq({super.key});

  @override
  State<ManageChatbotFaq> createState() => _ManageChatbotFaqState();
}

class _ManageChatbotFaqState extends State<ManageChatbotFaq> {
  final Color gold = const Color(0xFFC59A6D);
  final Color darkCard = const Color(0xFF141420);
  final Color glass = const Color(0xFF1E1E2E);
  final Color bgBlack = const Color(0xFF0A0A0F);

  List<dynamic> faqs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    setState(() => isLoading = true);
    try {
      final res = await supabase.from('tbl_chatbot_faq').select().order('keyword', ascending: true);
      setState(() {
        faqs = res;
      });
    } catch (e) {
      debugPrint("Error fetching FAQs: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _autoPopulate() async {
    setState(() => isLoading = true);
    final apiQAs = [
      {'keyword': 'How often should I apply sunscreen?', 'answer': 'According to WHO & API Standards: Apply sunscreen with at least SPF 30 every day, and strictly reapply every 2 hours (or after swimming).'},
      {'keyword': 'What is the UV Index?', 'answer': 'The UV Index is a global standard scale from 0 to 11+. 0-2 is Low, 3-5 is Moderate, 6-7 is High, 8-10 is Very High, and 11+ is Extreme risk.'},
      {'keyword': 'What should I do if I get a sunburn?', 'answer': 'Cool the skin with damp towels, apply aloe vera or hydrocortisone, avoid the sun completely, and drink plenty of water to prevent dehydration.'},
      {'keyword': 'What is the Fitzpatrick Skin Type scale?', 'answer': 'The Fitzpatrick Scale (1-6) measures how skin responds to UV. Types 1-2 burn easily and rarely tan. Types 5-6 rarely burn and tan easily.'},
      {'keyword': 'Who are you?', 'answer': 'Hi there! I am powered by WHO/OpenUV guidelines. Ask me about sun safety or your skin type.'},
      {'keyword': 'Do I need sunscreen indoors?', 'answer': 'Yes, if you sit near windows! UVA rays, which cause aging and skin damage, can penetrate standard glass.'},
      {'keyword': 'Is SPF 100 twice as good as SPF 50?', 'answer': 'No. SPF 50 blocks 98% of UVB rays, while SPF 100 blocks 99%. No sunscreen blocks 100%.'},
      {'keyword': 'What does Board Spectrum mean?', 'answer': 'Broad spectrum means the sunscreen protects against both UVA (aging) and UVB (burning) rays.'},
      {'keyword': 'What should I wear for high UV?', 'answer': 'Opt for a wide-brimmed hat, UV-blocking sunglasses, and tightly-woven long-sleeved clothing.'},
      {'keyword': 'How do I know if a mole is dangerous?', 'answer': 'Use the ABCDE rule: Asymmetry, Border irregularity, Color changes, Diameter over 6mm, and Evolving size or shape. See a dermatologist immediately if concerned.'},
    ];

    try {
      for (var item in apiQAs) {
        await supabase.from('tbl_chatbot_faq').insert(item);
      }
      _fetchFaqs();
    } catch (e) {
      debugPrint("Error auto populating: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteFaq(int id) async {
    try {
      await supabase.from('tbl_chatbot_faq').delete().eq('id', id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted successfully', style: TextStyle(color: gold)), backgroundColor: glass));
      _fetchFaqs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e', style: const TextStyle(color: Colors.red))));
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    final TextEditingController keywordCtrl = TextEditingController(text: item?['keyword']?.toString() ?? '');
    final TextEditingController answerCtrl = TextEditingController(text: item?['answer']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCard,
        title: Text(item == null ? "Add Chatbot QA" : "Edit Chatbot QA", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(keywordCtrl, "Full Question (e.g. 'What is UV?')", maxLines: 2),
              _buildTextField(answerCtrl, "Response/Answer", maxLines: 5),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
            onPressed: () async {
              try {
                final data = {
                  'keyword': keywordCtrl.text.trim(),
                  'answer': answerCtrl.text.trim(),
                };
                
                if (item == null) {
                  await supabase.from('tbl_chatbot_faq').insert(data);
                } else {
                  await supabase.from('tbl_chatbot_faq').update(data).eq('id', item['id']);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _fetchFaqs();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(item == null ? "Save" : "Update"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: glass,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "Chatbot Q&A",
      child: Scaffold(
        backgroundColor: bgBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: _autoPopulate,
              icon: const Icon(Icons.api_rounded, color: Colors.blueAccent),
              label: const Text("Auto-Populate Core Knowledge", style: TextStyle(color: Colors.blueAccent)),
            ),
            const SizedBox(width: 15),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          onPressed: () => _showAddEditDialog(),
          child: const Icon(Icons.add),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : faqs.isEmpty
                ? Center(
                    child: Text("No Chatbot data found. Add some or generate defaults.", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      final item = faqs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: darkCard,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: gold.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Q: ${item['keyword']}", style: GoogleFonts.outfit(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text("A: ${item['answer']}", style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showAddEditDialog(item: item)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteFaq(item['id'])),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
