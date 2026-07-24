import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:admin_apps/addgallery.dart';
import 'package:admin_apps/addstock.dart';
import 'package:admin_apps/addproduct.dart';
import 'package:flutter/material.dart';
import 'package:admin_apps/main.dart';
import 'package:google_fonts/google_fonts.dart';

class MyProducts extends StatefulWidget {
  const MyProducts({super.key});

  @override
  State<MyProducts> createState() => _MyProductsState();
}

class _MyProductsState extends State<MyProducts> {
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);
  final Color glass = const Color(0xFF262626);

  List productList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await supabase
          .from('tbl_product')
          .select('*, tbl_category(category_name), tbl_product_skintype(tbl_skintype(skintype_name))')
          .order('product_id', ascending: false);

      setState(() {
        productList = response;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteProduct(int id) async {
    await supabase.from('tbl_product').delete().match({'product_id': id});
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "Inventory",
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: gold))
          : Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                /// Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Product Repository", style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProduct())).then((_) => fetchProducts());
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("ADD NEW PRODUCT"),
                      style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                /// Grid of Products (More professional than table)
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      mainAxisSpacing: 25,
                      crossAxisSpacing: 25,
                    ),
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      final product = productList[index];
                      // Extract joined skin types
                      final List skTypes = product['tbl_product_skintype'] ?? [];
                      final String stDisplay = skTypes.isNotEmpty 
                        ? skTypes.map((e) => e['tbl_skintype']['skintype_name']).join(', ')
                        : "No Skin Type";

                      return Container(
                        decoration: BoxDecoration(
                          color: darkCard,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                                    child: Image.network(product['photo'], width: double.infinity, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 15, right: 15,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                                      child: Text("₹${product['price']}", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product['product_name'] ?? "", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 5),
                                    Text("${product['tbl_category']?['category_name']} • $stDisplay", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildStockBadge(product['stock'] ?? 0),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.collections_outlined, color: gold, size: 18),
                                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddGallery(productId: product['product_id']))),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_box_outlined, color: Colors.blueAccent, size: 18),
                                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddStock(productId: product['product_id']))).then((_) => fetchProducts()),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 18),
                                              onPressed: () => _confirmDelete(product['product_id']),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildStockBadge(int stock) {
    Color c = stock > 5 ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text("$stock STK", style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCard,
        title: Text("Delete Product?", style: GoogleFonts.outfit(color: Colors.white)),
        content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              deleteProduct(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
