import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class SkinScannerPage extends StatefulWidget {
  const SkinScannerPage({super.key});

  @override
  State<SkinScannerPage> createState() => _SkinScannerPageState();
}

class _SkinScannerPageState extends State<SkinScannerPage> {
  File? _image;
  bool _isLoading = false;
  String? _result;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
      });
    }
  }

  Future<void> _analyzeSkin() async {
    if (_image == null) return;

    setState(() => _isLoading = true);

    try {
      final backendUrl =
          dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000/api/predict/';
      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _image!.path,
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);

        setState(() {
          _result =
              "DIAGNOSIS COMPLETE ✨\n\nCATEGORY: ${data['category'].toUpperCase()}\n${data['name']}\n\n${data['description']}";
        });

        final user = supabase.auth.currentUser;
        if (user != null) {
          // 1. Find the type_id for this category name
          final skinTypeData = await supabase
              .from('tbl_skintype')
              .select('type_id')
              .ilike('skintype_name', data['category'].toString())
              .maybeSingle();

          if (skinTypeData != null) {
            await supabase
                .from('tbl_user')
                .update({'skintype_id': skinTypeData['type_id']})
                .eq('user_id', user.id);
          }
        }
      } else {
        setState(() => _result = "Error: Backend returned ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _result =
          "Error: Could not connect to backend. Make sure the Django server is running and the IP address is correct. ($e)");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFC59A6D);
    const Color glass = Color(0xFF1E1E2E);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text("SKIN ANALYZER",
            style: GoogleFonts.outfit(
                color: gold, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            _buildImageCarrier(gold),
            const SizedBox(height: 32),
            _buildActionButtons(gold, glass),
            const SizedBox(height: 24),
            if (_image != null) _buildAnalyzeButton(gold),
            const SizedBox(height: 40),
            if (_result != null) _buildResultCard(gold, glass),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarrier(Color gold) {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: gold.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: gold.withOpacity(0.05), blurRadius: 30)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_image == null)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face_retouching_natural_rounded,
                    color: gold.withOpacity(0.3), size: 80),
                const SizedBox(height: 20),
                Text("Align your face for detection",
                    style: GoogleFonts.outfit(
                        color: Colors.white24, fontSize: 13, letterSpacing: 1)),
              ],
            )
          else
            ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.file(_image!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity)),
          if (_isLoading) _buildScanningOverlay(gold),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay(Color gold) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
          color: Colors.black45, borderRadius: BorderRadius.circular(32)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: gold, strokeWidth: 2),
            const SizedBox(height: 20),
            Text("AI PROCESSING...",
                style: GoogleFonts.outfit(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color gold, Color glass) {
    return Row(
      children: [
        Expanded(
            child: _buildButton("CAMERA", Icons.camera_rounded, gold,
                Colors.black, () => _pickImage(ImageSource.camera))),
        const SizedBox(width: 16),
        Expanded(
            child: _buildButton("GALLERY", Icons.photo_library_rounded, glass,
                Colors.white, () => _pickImage(ImageSource.gallery))),
      ],
    );
  }

  Widget _buildButton(
      String label, IconData icon, Color bg, Color text, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
      style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: text,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    );
  }

  Widget _buildAnalyzeButton(Color gold) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _analyzeSkin,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        child: const Text("INITIALIZE ANALYSIS",
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildResultCard(Color gold, Color glass) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: glass.withOpacity(0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: gold.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, color: gold, size: 24),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: gold, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  (_result?.contains("CATEGORY: ") ?? false)
                      ? _result!.split("CATEGORY: ")[1].split("\n")[0]
                      : "SKIN ANALYSIS",
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(_result ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 15, height: 1.6)),
          const SizedBox(height: 24),
          Text("ML INSIGHTS APPLIED",
              style: GoogleFonts.outfit(
                  color: gold.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        ],
      ),
    );
  }
}
