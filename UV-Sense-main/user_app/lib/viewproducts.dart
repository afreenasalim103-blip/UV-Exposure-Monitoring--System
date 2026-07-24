import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/main.dart';
import 'package:user_app/my_cart.dart';

class ViewProducts extends StatefulWidget {
  const ViewProducts({super.key});

  @override
  State<ViewProducts> createState() => _ViewProductsState();
}

class _ViewProductsState extends State<ViewProducts> {
  static const Color bgBlack = Color(0xFF0A0A0F);
  static const Color gold    = Color(0xFFC59A6D);
  static const Color glass   = Color(0xFF1E1E2E);
  static const Color copper  = Color(0xFF7A4E2D);

  List products = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await supabase.from('tbl_product').select().order('product_id', ascending: false);
      setState(() { products = response; isLoading = false; });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List get filtered {
    if (searchController.text.isEmpty) return products;
    return products
        .where((p) => p['product_name'].toString().toLowerCase().contains(searchController.text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: CustomScrollView(
        slivers: [
          /// ── APP BAR ──
          SliverAppBar(
            backgroundColor: bgBlack,
            pinned: true,
            expandedHeight: 150,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCart())),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: gold.withOpacity(.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: gold.withOpacity(.3)),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: gold, size: 22),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [copper.withOpacity(.3), bgBlack],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Skin Care",
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
                        Text("Shop",
                            style: GoogleFonts.outfit(
                                color: gold, fontSize: 30, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// ── SEARCH ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search sunscreens, moisturizers...",
                  hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: gold, size: 20),
                  filled: true,
                  fillColor: glass,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: gold.withOpacity(.4)),
                  ),
                ),
              ),
            ),
          ),

          /// ── GRID ──
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2)),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 70, color: gold.withOpacity(.3)),
                    const SizedBox(height: 12),
                    Text("No products found",
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _ProductCard(product: filtered[i]),
                  childCount: filtered.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.63,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── PRODUCT CARD ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Map product;
  const _ProductCard({required this.product});

  static const Color gold  = Color(0xFFC59A6D);
  static const Color glass = Color(0xFF1E1E2E);

  Future<void> _addToCart(BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final booking = await supabase
          .from('tbl_booking')
          .select()
          .eq('user_id', user.id)
          .eq('booking_status', 0)
          .maybeSingle();

      int bookingId;
      if (booking != null) {
        bookingId = booking['id'];
        final existing = await supabase
            .from('tbl_cart')
            .select()
            .eq('booking_id', bookingId)
            .eq('product_id', product['product_id'])
            .maybeSingle();
        if (existing != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Already in cart"), behavior: SnackBarBehavior.floating),
            );
          }
          return;
        }
      } else {
        final nb = await supabase
            .from('tbl_booking')
            .insert({'user_id': user.id, 'booking_status': 0, 'booking_amount': 0})
            .select()
            .single();
        bookingId = nb['id'];
      }

      await supabase.from('tbl_cart').insert({
        'booking_id': bookingId,
        'product_id': product['product_id'],
        'cart_quantity': 1,
        'cart_status': 0,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to cart ✓"),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Cart error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Image
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: product['photo'] != null
                      ? Image.network(
                          product['photo'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF141420),
                            child: const Center(child: Icon(Icons.spa_outlined, color: gold, size: 40)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF141420),
                          child: const Center(child: Icon(Icons.spa_outlined, color: gold, size: 40)),
                        ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border_rounded, color: gold, size: 15),
                  ),
                ),
              ],
            ),
          ),

          /// Details
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product_name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${product['price']}",
                      style: GoogleFonts.outfit(
                          color: gold, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    GestureDetector(
                      onTap: () => _addToCart(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: gold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.black, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}