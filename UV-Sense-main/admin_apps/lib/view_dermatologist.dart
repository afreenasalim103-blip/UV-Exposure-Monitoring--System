import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:admin_apps/verify_dermatologist_page.dart';
import 'package:admin_apps/add_dermatologist.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class AdminViewDermatologist extends StatefulWidget {
  const AdminViewDermatologist({super.key});

  @override
  State<AdminViewDermatologist> createState() => _AdminViewDermatologistState();
}

class _AdminViewDermatologistState extends State<AdminViewDermatologist> {
  List dermatologists = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDermatologists();
  }

  Future<void> fetchDermatologists() async {
    final response = await supabase.from('tbl_dermatologist').select();
    setState(() {
      dermatologists = response;
      loading = false;
    });
  }

  Future<void> deleteDoctor(int id) async {
    await supabase.from('tbl_dermatologist').delete().eq('dermatologist_id', id);
    fetchDermatologists();
  }

  Widget buildCard(Map data) {
    String photo = data['dermatologist_photo'] ?? "";
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
          child: photo.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(data['dermatologist_name'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(data['dermatologist_email'] ?? "", style: const TextStyle(color: Colors.white54)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => deleteDoctor(data['dermatologist_id']),
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyDermatologistPage(data: data))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SidebarWrapper(title: "Doctors", child: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC59A6D),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDermatologistPage())).then((_) => fetchDermatologists()),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SidebarWrapper(
        title: "Medical Experts",
        child: dermatologists.isEmpty 
          ? const Center(child: Text("Registry is empty", style: TextStyle(color: Colors.white30)))
          : ListView.builder(
              itemCount: dermatologists.length,
              itemBuilder: (ctx, i) => buildCard(dermatologists[i]),
            ),
      ),
    );
  }
}