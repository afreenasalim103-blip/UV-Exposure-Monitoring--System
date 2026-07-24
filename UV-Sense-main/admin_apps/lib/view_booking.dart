import 'package:admin_apps/sidebar_wrapper.dart';
import 'package:admin_apps/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminViewBooking extends StatefulWidget {
  const AdminViewBooking({super.key});

  @override
  State<AdminViewBooking> createState() => _AdminViewBookingState();
}

class _AdminViewBookingState extends State<AdminViewBooking> {
  final Color bgBlack = const Color(0xFF0B0B0B);
  final Color darkCard = const Color(0xFF1A1A1A);
  final Color gold = const Color(0xFFC59A6D);

  List allBookings = [];
  List filteredBookings = [];
  bool loading = true;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    getBookings();
  }

  Future<void> getBookings() async {
    try {
      final response = await supabase.from('tbl_booking').select('''
            *,
            tbl_user(*),
            tbl_cart(
              cart_quantity,
              tbl_product(
                product_name,
                price,
                photo
              )
            )
          ''').order('id', ascending: false);

      setState(() {
        allBookings = List.from(response);
        filteredBookings = allBookings;
        loading = false;
      });
    } catch (e) {
      debugPrint("Booking Fetch Error: $e");
      setState(() => loading = false);
    }
  }

  void filterByDate(DateTime date) {
    setState(() {
      selectedDate = date;
      filteredBookings = allBookings.where((booking) {
        DateTime bookingDate = DateTime.parse(booking['booking_date']);
        return bookingDate.year == date.year && bookingDate.month == date.month && bookingDate.day == date.day;
      }).toList();
    });
  }

  void clearFilter() {
    setState(() {
      selectedDate = null;
      filteredBookings = allBookings;
    });
  }

  String getStatusText(int status) {
    switch (status) {
      case 0: return "Pending";
      case 1: return "Rejected";
      case 2: return "Paid";
      case 3: return "Accepted";
      case 4: return "Packed";
      case 5: return "Shipped";
      case 6: return "Delivered";
      default: return "Unknown";
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 1: return Colors.redAccent;
      case 2: return Colors.blueAccent;
      case 3: return Colors.orangeAccent;
      case 6: return Colors.greenAccent;
      default: return gold;
    }
  }

  Future<void> updateStatus(int bookingId, int status) async {
    await supabase.from('tbl_booking').update({'booking_status': status}).eq('id', bookingId);
    await getBookings();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Status Updated")));
  }

  @override
  Widget build(BuildContext context) {
    return SidebarWrapper(
      title: "Detailed Orders",
      child: loading
          ? Center(child: CircularProgressIndicator(color: gold))
          : Column(
            children: [
              /// 1. Top Filter Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    Text("Total Orders: ${allBookings.length}", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    if (selectedDate != null) 
                      TextButton.icon(
                        onPressed: clearFilter,
                        icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                        label: Text(DateFormat('dd MMM yyyy').format(selectedDate!), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context, 
                          initialDate: DateTime.now(), 
                          firstDate: DateTime(2023), 
                          lastDate: DateTime(2025),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(primary: gold, onPrimary: Colors.black, surface: darkCard),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) filterByDate(picked);
                      },
                      icon: Icon(Icons.calendar_month_rounded, size: 18),
                      label: const Text("Filter by Date"),
                      style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ],
                ),
              ),

              /// 2. Orders Content
              Expanded(
                child: filteredBookings.isEmpty 
                  ? Center(child: Text("No orders found for this date.", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      int status = booking['booking_status'] ?? 0;
                      List cart = booking['tbl_cart'] ?? [];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: darkCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("#ORDER-${booking['id']}", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 5),
                                    Text(booking['booking_date'] ?? "", style: const TextStyle(color: Colors.white30, fontSize: 11)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(getStatusText(status).toUpperCase(), style: TextStyle(color: getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 30),
                            
                            /// User Info Row
                            Row(
                              children: [
                                CircleAvatar(radius: 15, backgroundImage: NetworkImage(booking['tbl_user']?['user_photo'] ?? "https://via.placeholder.com/150")),
                                const SizedBox(width: 10),
                                Text(booking['tbl_user']?['user_name'] ?? "Unknown", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                                const Spacer(),
                                Text(booking['tbl_user']?['user_contact'] ?? "", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            /// Products Detailed Section
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
                              child: Column(
                                children: cart.map((item) {
                                  final p = item['tbl_product'];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Image.network(p['photo'] ?? "", width: 40, height: 40, fit: BoxFit.cover),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(p['product_name'] ?? "", style: TextStyle(color: Colors.white70, fontSize: 13))),
                                        Text("x${item['cart_quantity']}", style: TextStyle(color: gold, fontSize: 12)),
                                        const SizedBox(width: 10),
                                        Text("₹${p['price']}", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 15),

                            /// Summary & Actions
                            Row(
                              children: [
                                const Text("TOTAL AMOUNT: ", style: TextStyle(color: Colors.white30, fontSize: 12)),
                                Text("₹${booking['booking_amount']}", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                if (status == 2) ...[
                                  TextButton(onPressed: () => updateStatus(booking['id'], 3), child: const Text("Accept Order", style: TextStyle(color: Colors.greenAccent))),
                                  TextButton(onPressed: () => updateStatus(booking['id'], 1), child: const Text("Reject", style: TextStyle(color: Colors.redAccent))),
                                ] else if (status < 6 && status >= 3) ...[
                                  _buildActionButton(status, booking['id']),
                                ]
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
    );
  }

  Widget _buildActionButton(int currentStatus, int bookingId) {
    String nextLabel = "";
    int nextStatus = currentStatus + 1;
    Color color = gold;

    switch (currentStatus) {
      case 3: nextLabel = "Mark Packed"; break;
      case 4: nextLabel = "Mark Shipped"; color = Colors.blueAccent; break;
      case 5: nextLabel = "Mark Delivered"; color = Colors.greenAccent; break;
    }

    return ElevatedButton(
      onPressed: () => updateStatus(bookingId, nextStatus),
      style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.15), foregroundColor: color, elevation: 0),
      child: Text(nextLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}