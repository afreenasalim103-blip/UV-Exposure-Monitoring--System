import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_apps/main.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;

  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);

  List categoryList = [];
  List skinCategoriesList = []; // New list for dynamic skin types
  List<int> selectedSkinTypeIds = []; // Now storing IDs
  List levelList = [];

  int? selectedCategoryId;
  int? selectedLevelId;

  bool isSubmitting = false;
  bool isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    try {
      final catRes = await supabase.from('tbl_category').select().order('category_name');
      final skinRes = await supabase.from('tbl_skintype').select().order('skintype_name');
      final levelRes = await supabase.from('tbl_level').select().order('level_name');

      setState(() {
        categoryList = catRes;
        skinCategoriesList = skinRes;
        levelList = levelRes;
        isInitialLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => isInitialLoading = false);
    }
  }

  Future<void> pickImage() async {
    try {
      file_picker.FilePickerResult? result = await file_picker.FilePicker.platform.pickFiles(
        type: file_picker.FileType.image,
        withData: true,
      );
      if (result == null) return;

      setState(() {
        pickedImage = result.files.first;
        imageBytes = pickedImage!.bytes;
      });
    } catch (e) {
      debugPrint("Picker Error: $e");
    }
  }

  Future<void> insertProduct() async {
    final name = nameController.text.trim();
    final priceStr = priceController.text.trim();
    final double? price = double.tryParse(priceStr);

    if (name.isEmpty ||
        selectedCategoryId == null ||
        selectedSkinTypeIds.isEmpty || // Changed check
        price == null ||
        imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and upload an image")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final String extension = pickedImage?.extension ?? 'jpg';
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.$extension";

      await supabase.storage.from('product_images').uploadBinary(fileName, imageBytes!);
      final imageUrl = supabase.storage.from('product_images').getPublicUrl(fileName);

      // 1. Insert Product and get ID
      final productData = await supabase.from('tbl_product').insert({
        'product_name': name,
        'product_description': descriptionController.text.trim(),
        'category_id': selectedCategoryId,
        'level_id': selectedLevelId,
        'price': price,
        'photo': imageUrl,
        'spf_rating': spfController.text.trim(),
      }).select('product_id').single();

      final int productId = productData['product_id'];

      // 2. Insert Skin Types into junction table
      final List<Map<String, dynamic>> multiSkinTypes = selectedSkinTypeIds.map((sid) => {
        'product_id': productId,
        'skintype_id': sid,
      }).toList();

      await supabase.from('tbl_product_skintype').insert(multiSkinTypes);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product Launched Successfully")),
        );
      }
    } catch (e) {
      debugPrint("Insert Error: $e");
      setState(() => isSubmitting = false);
    }
  }

  final TextEditingController spfController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (isInitialLoading) {
      return const SidebarWrapper(
        title: "Loading...",
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SidebarWrapper(
      title: "Inventory Creation",
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(50),
          child: Column(
            children: [
              Text(
                "Create Premium Product",
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Define detailed metrics for the new inventory item",
                style: TextStyle(color: Colors.white30, fontSize: 14),
              ),
              const SizedBox(height: 40),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// IMAGE CARD
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 550,
                        decoration: BoxDecoration(
                          color: darkCard,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: gold.withOpacity(0.2)),
                        ),
                        child: imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.memory(imageBytes!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, color: gold, size: 50),
                                  const SizedBox(height: 15),
                                  Text(
                                    "Upload Product Image",
                                    style: TextStyle(color: gold.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 40),

                  /// FORM CARD
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: darkCard,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        children: [
                          _buildField(nameController, "Product Title", Icons.label_outline_rounded),
                          const SizedBox(height: 20),
                          _buildField(descriptionController, "Detailed Description...", Icons.notes_rounded, maxLines: 3),
                          const SizedBox(height: 20),

                          /// CATEGORY + SKIN
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  "Select Category",
                                  selectedCategoryId,
                                  categoryList,
                                  (v) => setState(() => selectedCategoryId = v),
                                  'category_id',
                                  'category_name',
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Target Skin Categories", style: TextStyle(color: Colors.white30, fontSize: 12)),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: skinCategoriesList.map((item) {
                                        final sid = item['type_id'];
                                        final sname = item['skintype_name'];
                                        bool isSel = selectedSkinTypeIds.contains(sid);
                                        return FilterChip(
                                          label: Text(sname, style: TextStyle(color: isSel ? Colors.black : Colors.white24, fontSize: 10)),
                                          selected: isSel,
                                          selectedColor: gold,
                                          backgroundColor: Colors.white.withOpacity(0.05),
                                          onSelected: (val) {
                                            setState(() {
                                              if (val) {
                                                selectedSkinTypeIds.add(sid);
                                              } else {
                                                selectedSkinTypeIds.remove(sid);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// UV LEVEL + SPF
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  "UV Intensity",
                                  selectedLevelId,
                                  levelList,
                                  (v) => setState(() => selectedLevelId = v),
                                  'level_id',
                                  'level_name',
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildField(spfController, "SPF Rating", Icons.wb_sunny_rounded),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  priceController,
                                  "Retail Price (INR)",
                                  Icons.currency_rupee_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),


                          /// BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : insertProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: gold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: isSubmitting
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : Text(
                                      "LAUNCH PRODUCT",
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: gold.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    int? value,
    List items,
    Function(int?) onChanged,
    String idKey,
    String nameKey,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      dropdownColor: darkCard,
      style: const TextStyle(color: Colors.white),

      items: items.map<DropdownMenuItem<int>>((item) {
        return DropdownMenuItem<int>(
          value: item[idKey],
          child: Text(
            item[nameKey],
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),

      onChanged: onChanged,

      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}