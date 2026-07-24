import 'package:flutter/material.dart';
import 'package:user_app/main.dart';

class MyOrders extends StatefulWidget {
  const MyOrders({super.key});

  @override
  State<MyOrders> createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  static const Color gold = Color(0xFFC59A6D);
  static const Color glass = Color(0xFF1F1F1F);

  List orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  /// FETCH ORDERS WITH PRODUCTS
  Future<void> fetchOrders() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('tbl_booking')
          .select('''
            *,
            tbl_cart(
              cart_quantity,
              tbl_product(
                product_name,
                price,
                photo
              )
            )
          ''')
          .eq('user_id', userId)
          .neq('booking_status', 0)
          .order('id', ascending: false);

      setState(() {
        orders = List.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Orders Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            const Text("Order History", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : orders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(orders[index]);
                  },
                ),
    );
  }

  Widget _buildOrderCard(Map order) {
    String statusText = "Processing";
    Color statusColor = Colors.orangeAccent;

    if (order['booking_status'] == 1) {
      statusText = "Pending";
      statusColor = Colors.grey;
    } else if (order['booking_status'] == 2) {
      statusText = "Paid";
      statusColor = Colors.greenAccent;
    } else if (order['booking_status'] == 3) {
      statusText = "Accepted";
      statusColor = Colors.orangeAccent;
    } else if (order['booking_status'] == 4) {
      statusText = "Rejected";
      statusColor = Colors.redAccent;
    } else if (order['booking_status'] == 5) {
      statusText = "Packed";
      statusColor = Colors.purpleAccent;
    } else if (order['booking_status'] == 6) {
      statusText = "Shipped";
      statusColor = Colors.blueAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ORDER HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order #${order['id']}",
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white10, height: 25),

          /// PRODUCTS LIST
          Column(
            children: (order['tbl_cart'] as List).map((cartItem) {
              final product = cartItem['tbl_product'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    /// PRODUCT IMAGE
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['photo'] ?? "",
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// PRODUCT INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['product_name'] ?? "",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Qty: ${cartItem['cart_quantity']}",
                            style:
                                const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),

                    /// PRICE
                    Text(
                      "₹${product['price']}",
                      style: const TextStyle(
                          color: gold, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              );
            }).toList(),
          ),

          const Divider(color: Colors.white10),

          /// TOTAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount",
                style: TextStyle(color: Colors.white54),
              ),
              Text(
                "₹${order['booking_amount']}",
                style: const TextStyle(
                    color: gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 80, color: gold.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text("No orders yet",
              style: TextStyle(color: Colors.white54, fontSize: 18)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Start Shopping",
                style: TextStyle(color: gold)),
          )
        ],
      ),
    );
  }
}