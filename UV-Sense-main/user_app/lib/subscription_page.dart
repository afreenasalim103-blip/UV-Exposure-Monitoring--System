import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/main.dart';
import 'package:user_app/subscription_payment_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  static const Color bgBlack = Color(0xFF0A0A0F);
  static const Color glass   = Color(0xFF1E1E2E);
  static const Color gold    = Color(0xFFC59A6D);
  static const Color copper  = Color(0xFF7A4E2D);

  List plans = [];
  bool isLoading = true;
  bool isProcessing = false;
  Map? activeSubscription;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final user = supabase.auth.currentUser;
      final plansRes = await supabase.from('tbl_subscription_plan').select().order('plan_price');
      
      final subRes = await supabase
          .from('tbl_user_subscription')
          .select('*, tbl_subscription_plan(*)')
          .eq('user_id', user!.id)
          .eq('subscription_status', 'active')
          .maybeSingle();

      setState(() {
        plans = plansRes;
        activeSubscription = subRes;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> purchaseSubscription(Map plan) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SubscriptionPaymentPage(plan: plan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Premium Plans", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: gold), onPressed: () => Navigator.pop(context)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : CustomScrollView(
              slivers: [
                if (activeSubscription != null) ...[
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [copper, gold]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ACTIVE PLAN", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 10)),
                          const SizedBox(height: 8),
                          Text(activeSubscription!['tbl_subscription_plan']['plan_name'], style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Valid until: ${activeSubscription!['end_date'].toString().split('T')[0]}", style: const TextStyle(color: Colors.black87, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
                
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildPlanCard(plans[i]),
                      childCount: plans.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlanCard(Map plan) {
    bool isCurrent = activeSubscription != null && activeSubscription!['plan_id'] == plan['plan_id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isCurrent ? gold : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan['plan_name'], style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              if (isCurrent) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(10)),
                child: const Text("CURRENT", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(plan['plan_description'] ?? 'Unlock premium features', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("₹${plan['plan_price']}", style: const TextStyle(color: gold, fontSize: 24, fontWeight: FontWeight.w900)),
                   Text("${plan['plan_duration']} Days Access", style: const TextStyle(color: Colors.white24, fontSize: 11)),
                ],
              ),
              ElevatedButton(
                onPressed: (isCurrent || isProcessing) ? null : () => _showPaymentSheet(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text("Select Plan", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(Map plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: glass,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Secure Checkout", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Complete payment of ₹${plan['plan_price']} for ${plan['plan_name']}", style: const TextStyle(color: Colors.white38)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(Icons.payment, color: gold),
                  const SizedBox(width: 15),
                  const Expanded(child: Text("Test Mode Payment Gateway", style: TextStyle(color: Colors.white70))),
                  Text("ENABLED", style: TextStyle(color: Colors.greenAccent.withOpacity(0.5), fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  purchaseSubscription(plan);
                },
                style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("PAY NOW", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
