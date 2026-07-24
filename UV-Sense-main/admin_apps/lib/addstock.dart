import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_apps/main.dart';

class AddStock extends StatefulWidget {
  final int productId;
  const AddStock({super.key, required this.productId});

  @override
  State<AddStock> createState() => _AddStockState();
}

class _AddStockState extends State<AddStock> {
  final TextEditingController countController = TextEditingController();

  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);

  bool isLoading = false;

  Future<void> updateStock() async {
    final countText = countController.text.trim();
    if (countText.isEmpty) return;

    setState(() => isLoading = true);

    try {
      int addedStock = int.parse(countText);

      /// 1. Insert into stock log
      await supabase.from('tbl_stock').insert({
        'product_id': widget.productId,
        'stock_count': addedStock,
      });

      /// 2. Get current stock
      final productRes = await supabase
          .from('tbl_product')
          .select('stock')
          .eq('product_id', widget.productId)
          .single();

      int currentStock = productRes['stock'] ?? 0;

      /// 3. Update total stock
      await supabase.from('tbl_product').update({
        'stock': currentStock + addedStock
      }).eq('product_id', widget.productId);

      /// Clear input
      countController.clear();

      /// ✅ SHOW POPUP MESSAGE
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: darkCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.greenAccent),
                const SizedBox(width: 8),
                Text(
                  "Success",
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
              ],
            ),
            content: const Text(
              "Stock added successfully",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close popup
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      debugPrint("Stock Error: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "Stock Management",
      child: Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ICON
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_business_rounded,
                    color: gold, size: 40),
              ),

              const SizedBox(height: 25),

              /// TITLE
              Text(
                "Replenish Inventory",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Enter the number of units to add to current stock",
                style: TextStyle(color: Colors.white30, fontSize: 13),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 35),

              /// INPUT FIELD
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: gold,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: "00",
                  hintStyle: const TextStyle(color: Colors.white10),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.02),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              /// BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updateStock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.black)
                      : Text(
                          "CONFIRM STOCK ADDITION",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              /// GO BACK BUTTON
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Go Back",
                  style: TextStyle(color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}