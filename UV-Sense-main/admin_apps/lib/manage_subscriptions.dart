import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:admin_apps/main.dart';

class ManageSubscriptions extends StatefulWidget {
  const ManageSubscriptions({super.key});

  @override
  State<ManageSubscriptions> createState() => _ManageSubscriptionsState();
}

class _ManageSubscriptionsState extends State<ManageSubscriptions> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);

  List plans = [];
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    try {
      final res = await supabase.from('tbl_subscription_plan').select().order('created_at');
      setState(() {
        plans = res;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> addPlan() async {
    final name = nameController.text.trim();
    final desc = descController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    final duration = int.tryParse(durationController.text.trim());

    if (name.isEmpty || price == null || duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await supabase.from('tbl_subscription_plan').insert({
        'plan_name': name,
        'plan_description': desc,
        'plan_price': price,
        'plan_duration': duration,
      });

      nameController.clear();
      descController.clear();
      priceController.clear();
      durationController.clear();
      
      fetchPlans();
      setState(() => isSubmitting = false);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subscription Plan Added")),
        );
      }
    } catch (e) {
      debugPrint("Insert Error: $e");
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "Subscription Management",
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Subscription Plans",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddPlanDialog,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text("New Plan", style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: gold),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : plans.isEmpty
                      ? const Center(child: Text("No plans defined yet", style: TextStyle(color: Colors.white24)))
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: plans.length,
                          itemBuilder: (ctx, i) {
                            final plan = plans[i];
                            return Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: darkCard,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: gold.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan['plan_name'],
                                    style: GoogleFonts.outfit(color: gold, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    plan['plan_description'] ?? '',
                                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                                    maxLines: 2,
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "₹${plan['plan_price']}",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      Text(
                                        "${plan['plan_duration']} Days",
                                        style: const TextStyle(color: Colors.white24, fontSize: 12),
                                      ),
                                    ],
                                  ),
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

  void _showAddPlanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: darkCard,
        title: Text("Create Subscription Plan", style: GoogleFonts.outfit(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(nameController, "Plan Name", Icons.label),
              const SizedBox(height: 15),
              _buildField(descController, "Description", Icons.notes, maxLines: 2),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildField(priceController, "Price (INR)", Icons.currency_rupee, keyboardType: TextInputType.number)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildField(durationController, "Duration (Days)", Icons.timer, keyboardType: TextInputType.number)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: isSubmitting ? null : addPlan,
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            child: const Text("Create Plan", style: TextStyle(color: Colors.black)),
          ),
        ],
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
}
