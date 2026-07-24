import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/main.dart';
import 'package:user_app/payment.dart';

class MyCart extends StatefulWidget {
  const MyCart({super.key});

  @override
  State<MyCart> createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  static const Color bgBlack = Color(0xFF0A0A0F);
  static const Color gold    = Color(0xFFC59A6D);
  static const Color glass   = Color(0xFF1E1E2E);
  static const Color copper  = Color(0xFF7A4E2D);

  List cartItems = [];
  bool isLoading = true;
  double grandTotal = 0;

  @override
  void initState() {
    super.initState();
    fetchCartData();
  }

  Future<void> fetchCartData() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final booking = await supabase
          .from('tbl_booking')
          .select()
          .eq('user_id', userId)
          .eq('booking_status', 0)
          .maybeSingle();

      if (booking == null) {
        setState(() { cartItems = []; isLoading = false; });
        return;
      }

      final response = await supabase
          .from('tbl_cart')
          .select('*, tbl_product(*)')
          .eq('booking_id', booking['id']);

      setState(() {
        cartItems = List.from(response);
        _calcTotal();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _calcTotal() {
    grandTotal = cartItems.fold(0.0, (sum, item) {
      final price = (item['tbl_product']['price'] as num?)?.toDouble() ?? 0;
      final qty   = item['cart_quantity'] ?? 0;
      return sum + price * qty;
    });
  }

  Future<void> updateQty(int index, int delta) async {
    final newQty = cartItems[index]['cart_quantity'] + delta;
    if (newQty < 1) { deleteItem(cartItems[index]['id'], index); return; }
    await supabase.from('tbl_cart').update({'cart_quantity': newQty}).eq('id', cartItems[index]['id']);
    setState(() { cartItems[index]['cart_quantity'] = newQty; _calcTotal(); });
  }

  Future<void> deleteItem(int cartId, int index) async {
    await supabase.from('tbl_cart').delete().eq('id', cartId);
    setState(() { cartItems.removeAt(index); _calcTotal(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
        title: Text("My Cart",
            style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () async {
                for (int i = cartItems.length - 1; i >= 0; i--) {
                  await deleteItem(cartItems[i]['id'], i);
                }
              },
              child: Text("Clear All", style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13)),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2))
          : cartItems.isEmpty
              ? _buildEmpty()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: cartItems.length,
                        itemBuilder: (ctx, i) => _buildItem(cartItems[i], i),
                      ),
                    ),
                    _buildCheckout(),
                  ],
                ),
    );
  }

  Widget _buildItem(Map item, int index) {
    final product = item['tbl_product'];
    final double price = (product['price'] as num?)?.toDouble() ?? 0;
    final int qty = item['cart_quantity'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Row(
        children: [
          /// Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: product['photo'] != null
                ? Image.network(product['photo'], width: 72, height: 72, fit: BoxFit.cover)
                : Container(
                    width: 72, height: 72, color: const Color(0xFF141420),
                    child: const Icon(Icons.spa_outlined, color: gold, size: 30),
                  ),
          ),

          const SizedBox(width: 14),

          /// Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product_name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${(price * qty).toStringAsFixed(0)}",
                  style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),

          /// Qty Controls
          Column(
            children: [
              Row(
                children: [
                  _qtyBtn(Icons.remove_rounded, () => updateQty(index, -1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text("$qty",
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  _qtyBtn(Icons.add_rounded, () => updateQty(index, 1)),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => deleteItem(item['id'], index),
                child: Text("Remove", style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: gold.withOpacity(.1),
          shape: BoxShape.circle,
          border: Border.all(color: gold.withOpacity(.3)),
        ),
        child: Icon(icon, size: 16, color: gold),
      ),
    );
  }

  Widget _buildCheckout() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(.07))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${cartItems.length} item${cartItems.length > 1 ? 's' : ''}",
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
              Text("₹${grandTotal.toStringAsFixed(0)}",
                  style: GoogleFonts.outfit(color: gold, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentGatewayScreen(
                    id: cartItems[0]['booking_id'],
                    amt: grandTotal.toInt(),
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                "PAY  ₹${grandTotal.toStringAsFixed(0)}  →",
                style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 90, color: gold.withOpacity(.3)),
          const SizedBox(height: 20),
          Text("Your cart is empty", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 18)),
          const SizedBox(height: 8),
          Text("Add some products to get started", style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }
}