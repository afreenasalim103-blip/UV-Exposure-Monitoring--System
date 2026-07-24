import 'dart:typed_data';
import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:admin_apps/main.dart';

class AddGallery extends StatefulWidget {
  final int productId;

  const AddGallery({super.key, required this.productId});

  @override
  State<AddGallery> createState() => _AddGalleryState();
}

class _AddGalleryState extends State<AddGallery> {

  Uint8List? imageBytes;
  String? fileName;

  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);
  final Color copper = const Color(0xFF7A4E2D);
  final Color glass = const Color(0xFF262626);

  bool isLoading = false;

  /// PICK IMAGE
  Future<void> pickImage() async {

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {

      setState(() {
        imageBytes = result.files.first.bytes;
        fileName = result.files.first.name;
      });

    }
  }

  /// INSERT INTO SUPABASE
  Future<void> insertGallery() async {

    if (imageBytes == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {

      final filePath = "gallery/${DateTime.now().millisecondsSinceEpoch}_$fileName";

      await supabase.storage
          .from('product_gallery')
          .uploadBinary(filePath, imageBytes!);

      final imageUrl =
          supabase.storage.from('product_gallery').getPublicUrl(filePath);

      await supabase.from('tbl_gallery').insert({
        'product_id': widget.productId,
        'photo': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gallery Image Added")),
        );
      }

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "Product Gallery",
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: darkCard,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: gold.withOpacity(.5)),
              boxShadow: [
                BoxShadow(color: gold.withOpacity(.25), blurRadius: 40),
                BoxShadow(color: Colors.black.withOpacity(.7), blurRadius: 25, offset: const Offset(0, 15)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 60, width: 60,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [gold, copper])),
                  child: const Icon(Icons.collections_outlined, size: 28, color: Colors.black),
                ),
                const SizedBox(height: 15),
                const Text("Add Gallery Photo", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 180, width: double.infinity,
                    decoration: BoxDecoration(color: glass, borderRadius: BorderRadius.circular(15), border: Border.all(color: gold.withOpacity(.2))),
                    child: imageBytes == null
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 35, color: gold.withOpacity(.5)), const SizedBox(height: 10), const Text("Select Product Image", style: TextStyle(color: Colors.white24, fontSize: 13))])
                        : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(imageBytes!, fit: BoxFit.cover)),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity, height: 45,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : insertGallery,
                    style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("Upload to Gallery", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}