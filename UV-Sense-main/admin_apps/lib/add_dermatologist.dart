import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class AddDermatologistPage extends StatefulWidget {
  const AddDermatologistPage({super.key});

  @override
  State<AddDermatologistPage> createState() => _AddDermatologistPageState();
}

class _AddDermatologistPageState extends State<AddDermatologistPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  Uint8List? photoBytes;
  Uint8List? certBytes;
  String? photoName;
  String? certName;

  bool isLoading = false;

  Future<void> _pickFile(bool isPhoto) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        if (isPhoto) {
          photoBytes = result.files.first.bytes;
          photoName = result.files.first.name;
        } else {
          certBytes = result.files.first.bytes;
          certName = result.files.first.name;
        }
      });
    }
  }

  Future<void> _addDermatologist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (photoBytes == null) {
        throw "Please upload both profile photo .";
      }

      final String photoTs =
          "${DateTime.now().millisecondsSinceEpoch}_p_$photoName";

      await supabase.storage
          .from('dermatologist_docs')
          .uploadBinary(photoTs, photoBytes!);

      final photoUrl = supabase.storage
          .from('dermatologist_docs')
          .getPublicUrl(photoTs);

      await supabase.from('tbl_dermatologist').insert({
        'dermatologist_name': nameController.text.trim(),
        'dermatologist_email': emailController.text.trim(),
        'dermatologist_contact': contactController.text.trim(),
        'dermatologist_address': addressController.text.trim(),
        'dermatologist_photo': photoUrl,
        'dermatologist_status': 'accepted',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dermatologist added successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFC59A6D);
    const Color darkCard = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Add Dermatologist", style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Name", Icons.person),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Email", Icons.email),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: contactController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Contact Number", Icons.phone),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: addressController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDecoration("Address", Icons.location_on),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 25),

              /// FILE PICKERS
              _buildFileUploadCard(
                "Profile Photo",
                photoBytes != null,
                () => _pickFile(true),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _addDermatologist,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "ADD DERMATOLOGIST",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileUploadCard(
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    const Color gold = Color(0xFFC59A6D);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.green : Colors.white24),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.cloud_upload_outlined,
              color: isSelected ? Colors.green : gold,
            ),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(color: Colors.white70)),
            const Spacer(),
            if (isSelected)
              const Text(
                "SELECTED",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: const Color(0xFFC59A6D)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC59A6D)),
      ),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
    );
  }
}
