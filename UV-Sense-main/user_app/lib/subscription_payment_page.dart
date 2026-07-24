import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/main.dart';

class SubscriptionPaymentPage extends StatefulWidget {
  final Map plan;

  const SubscriptionPaymentPage({super.key, required this.plan});

  @override
  State<SubscriptionPaymentPage> createState() => _SubscriptionPaymentPageState();
}

class _SubscriptionPaymentPageState extends State<SubscriptionPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  final TextEditingController cardNumber = TextEditingController();
  final TextEditingController cardName = TextEditingController();
  final TextEditingController expiry = TextEditingController();
  final TextEditingController cvv = TextEditingController();

  static const Color gold = Color(0xFFC59A6D);
  static const Color bgBlack = Color(0xFF0A0A0F);
  static const Color glass = Color(0xFF1E1E2E);

  Future<void> _processSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final user = supabase.auth.currentUser;
      final duration = widget.plan['plan_duration'] as int;
      final endDate = DateTime.now().add(Duration(days: duration));

      await supabase.from('tbl_user_subscription').insert({
        'user_id': user!.id,
        'plan_id': widget.plan['plan_id'],
        'end_date': endDate.toIso8601String(),
        'subscription_status': 'active',
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: glass,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Success ✨", style: TextStyle(color: Colors.white)),
            content: const Text("Subscription activated successfully. Restarting app to apply changes...", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  RestartWidget.restartApp(context);
                },
                child: const Text("OK", style: TextStyle(color: Colors.amber)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subscription activation failed")),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Secure Payment", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: gold), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            /// Card Visualization
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [Color(0xFF7A4E2D), Color(0xFFC59A6D)]),
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.credit_score_rounded, color: Colors.white, size: 40),
                  const Spacer(),
                  Text(
                    cardNumber.text.isEmpty ? "XXXX XXXX XXXX XXXX" : cardNumber.text,
                    style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cardName.text.isEmpty ? "CARD HOLDER" : cardName.text.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(expiry.text.isEmpty ? "MM/YY" : expiry.text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInput("Card Number", cardNumber, Icons.credit_card, 
                      formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16), CardFormatter()]),
                  const SizedBox(height: 16),
                  _buildInput("Card Holder", cardName, Icons.person_outline),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInput("Expiry", expiry, Icons.date_range, 
                          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), ExpiryFormatter()])),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInput("CVV", cvv, Icons.lock_outline, obscure: true, limit: 3)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processSubscription,
                      style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: _isProcessing 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text("PAY ₹${widget.plan['plan_price']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController ctrl, IconData icon, 
      {List<TextInputFormatter>? formatters, bool obscure = false, int? limit}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      inputFormatters: formatters ?? (limit != null ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(limit)] : null),
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: gold, size: 20),
        filled: true,
        fillColor: glass,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }
}

class CardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(" ", "");
    if (text.length > 16) return oldValue;
    var newText = "";
    for (int i = 0; i < text.length; i++) {
      if (i % 4 == 0 && i != 0) newText += " ";
      newText += text[i];
    }
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll("/", "");
    if (text.length > 4) return oldValue;
    if (text.length >= 3) text = "${text.substring(0, 2)}/${text.substring(2)}";
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
