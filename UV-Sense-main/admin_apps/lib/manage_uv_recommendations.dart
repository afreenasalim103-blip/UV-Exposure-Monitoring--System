import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_apps/main.dart';
import 'package:admin_apps/sidebar_wrapper.dart';

class ManageUvRecommendations extends StatefulWidget {
  const ManageUvRecommendations({super.key});

  @override
  State<ManageUvRecommendations> createState() => _ManageUvRecommendationsState();
}

class _ManageUvRecommendationsState extends State<ManageUvRecommendations> {
  final Color gold = const Color(0xFFC59A6D);
  final Color darkCard = const Color(0xFF141420);
  final Color glass = const Color(0xFF1E1E2E);
  final Color bgBlack = const Color(0xFF0A0A0F);

  List<dynamic> recommendations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() => isLoading = true);
    try {
      final res = await supabase.from('tbl_uv_recommendation').select().order('min_uv', ascending: true);
      setState(() {
        recommendations = res;
      });
    } catch (e) {
      debugPrint("Error fetching recommendations: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _autoPopulate() async {
    setState(() => isLoading = true);
    final defaults = [
      {
        'min_uv': 0.0, 'max_uv': 2.9, 'skin_profile': 'All',
        'sunscreen_spf': 'Optional', 'sunscreen_type': 'N/A', 'sunscreen_details': 'Minimal risk. Enjoy the outdoors safely.',
        'dress_color': 'Any', 'dress_type': 'Comfortable wear', 'safety_tips': 'No specific protection needed'
      },
      {
        'min_uv': 3.0, 'max_uv': 5.9, 'skin_profile': 'Fitzpatrick 1-2',
        'sunscreen_spf': 'SPF 30+', 'sunscreen_type': 'Broad Spectrum', 'sunscreen_details': 'Reapply every 2 hours.',
        'dress_color': 'Light', 'dress_type': 'Hat, sunglasses', 'safety_tips': 'Seek shade during midday'
      },
      {
        'min_uv': 3.0, 'max_uv': 5.9, 'skin_profile': 'Fitzpatrick 3-6',
        'sunscreen_spf': 'SPF 15+', 'sunscreen_type': 'Broad Spectrum', 'sunscreen_details': 'Reapply every 3 hours.',
        'dress_color': 'Any', 'dress_type': 'Hat, sunglasses', 'safety_tips': 'Standard sun protection'
      },
      {
        'min_uv': 6.0, 'max_uv': 7.9, 'skin_profile': 'Fitzpatrick 1-2',
        'sunscreen_spf': 'SPF 50+', 'sunscreen_type': 'Mineral/Water Resistant', 'sunscreen_details': 'Strictly reapply every 90 mins.',
        'dress_color': 'UV Blocking', 'dress_type': 'Wide Hat, Sunglasses', 'safety_tips': 'Reduce exposure by 50%'
      },
      {
        'min_uv': 6.0, 'max_uv': 7.9, 'skin_profile': 'Fitzpatrick 3-6',
        'sunscreen_spf': 'SPF 30+', 'sunscreen_type': 'Broad Spectrum', 'sunscreen_details': 'Reapply every 2 hours.',
        'dress_color': 'Breathable', 'dress_type': 'Hat, Sunglasses', 'safety_tips': 'Seek shade 10AM-4PM'
      },
      {
        'min_uv': 8.0, 'max_uv': 10.9, 'skin_profile': 'All',
        'sunscreen_spf': 'SPF 50+', 'sunscreen_type': 'Mineral/Chemical', 'sunscreen_details': 'Essential! Reapply every 2 hours.',
        'dress_color': 'Dark/UPF 50+', 'dress_type': 'Maximum Shade Clothing', 'safety_tips': 'Very High Risk. Minimize outdoor activity.'
      },
      {
        'min_uv': 11.0, 'max_uv': 20.0, 'skin_profile': 'All',
        'sunscreen_spf': 'SPF 50+ / SPF 100', 'sunscreen_type': 'Mineral', 'sunscreen_details': 'Exposed skin burns in minutes.',
        'dress_color': 'Dark/UPF 50+', 'dress_type': 'Full Coverage', 'safety_tips': 'Extreme Risk. Stay indoors if possible.'
      }
    ];

    try {
      for (var item in defaults) {
        await supabase.from('tbl_uv_recommendation').insert(item);
      }
      _fetchRecommendations();
    } catch (e) {
      debugPrint("Error auto populating: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteRecommendation(int id) async {
    try {
      await supabase.from('tbl_uv_recommendation').delete().eq('id', id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted successfully', style: TextStyle(color: gold)), backgroundColor: glass));
      _fetchRecommendations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e', style: const TextStyle(color: Colors.red))));
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    final TextEditingController minUvCtrl = TextEditingController(text: item?['min_uv']?.toString() ?? '');
    final TextEditingController maxUvCtrl = TextEditingController(text: item?['max_uv']?.toString() ?? '');
    final TextEditingController profileCtrl = TextEditingController(text: item?['skin_profile']?.toString() ?? '');
    final TextEditingController spfCtrl = TextEditingController(text: item?['sunscreen_spf']?.toString() ?? '');
    final TextEditingController scTypeCtrl = TextEditingController(text: item?['sunscreen_type']?.toString() ?? '');
    final TextEditingController scDetailsCtrl = TextEditingController(text: item?['sunscreen_details']?.toString() ?? '');
    final TextEditingController colorCtrl = TextEditingController(text: item?['dress_color']?.toString() ?? '');
    final TextEditingController dressTypeCtrl = TextEditingController(text: item?['dress_type']?.toString() ?? '');
    final TextEditingController tipsCtrl = TextEditingController(text: item?['safety_tips']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCard,
        title: Text(item == null ? "Add Recommendation" : "Edit Recommendation", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _buildTextField(minUvCtrl, "Min UV")),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(maxUvCtrl, "Max UV")),
                ],
              ),
              _buildTextField(profileCtrl, "Skin Profile (e.g. All, Fitzpatrick 1-2)"),
              _buildTextField(spfCtrl, "Sunscreen SPF (e.g. SPF 30+)"),
              _buildTextField(scTypeCtrl, "Sunscreen Type (e.g. Broad Spectrum)"),
              _buildTextField(scDetailsCtrl, "Sunscreen Details"),
              _buildTextField(colorCtrl, "Dress Color"),
              _buildTextField(dressTypeCtrl, "Dress Type"),
              _buildTextField(tipsCtrl, "Safety Tips (Comma separated)"),
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
                  'min_uv': double.tryParse(minUvCtrl.text) ?? 0.0,
                  'max_uv': double.tryParse(maxUvCtrl.text) ?? 0.0,
                  'skin_profile': profileCtrl.text.isEmpty ? 'All' : profileCtrl.text,
                  'sunscreen_spf': spfCtrl.text,
                  'sunscreen_type': scTypeCtrl.text,
                  'sunscreen_details': scDetailsCtrl.text,
                  'dress_color': colorCtrl.text,
                  'dress_type': dressTypeCtrl.text,
                  'safety_tips': tipsCtrl.text,
                };
                
                if (item == null) {
                  await supabase.from('tbl_uv_recommendation').insert(data);
                } else {
                  await supabase.from('tbl_uv_recommendation').update(data).eq('id', item['id']);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _fetchRecommendations();
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

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
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
      title: "UV Recommendations",
      child: Scaffold(
        backgroundColor: bgBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: _autoPopulate,
              icon: const Icon(Icons.api_rounded, color: Colors.blueAccent),
              label: const Text("Auto-Populate API Defaults", style: TextStyle(color: Colors.blueAccent)),
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
            : recommendations.isEmpty
                ? Center(
                    child: Text("No recommendations found. Add some to get started.", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: recommendations.length,
                    itemBuilder: (context, index) {
                      final item = recommendations[index];
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
                                  Text("UV: ${item['min_uv']} - ${item['max_uv']} | Profile: ${item['skin_profile']}",
                                      style: GoogleFonts.outfit(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text("🛡️ ${item['sunscreen_spf']} (${item['sunscreen_type']})", style: const TextStyle(color: Colors.white70)),
                                  Text("👕 ${item['dress_color']} ${item['dress_type']}", style: const TextStyle(color: Colors.white70)),
                                  Text("💡 ${item['safety_tips']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () => _showAddEditDialog(item: item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deleteRecommendation(item['id']),
                                ),
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
