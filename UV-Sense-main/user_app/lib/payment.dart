import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/main.dart';
import 'package:user_app/success.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final int id;
  final int amt;

  const PaymentGatewayScreen({super.key, required this.id, required this.amt});

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isProcessing = false;

  final TextEditingController cardNumber = TextEditingController();
  final TextEditingController cardName = TextEditingController();
  final TextEditingController expiry = TextEditingController();
  final TextEditingController cvv = TextEditingController();

  Future<void> checkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      await supabase
          .from('tbl_cart')
          .update({'cart_status': 1}).eq('booking_id', widget.id);

      await supabase.from('tbl_booking').update({
        'booking_status': 2,
        'booking_amount': widget.amt
      }).eq('id', widget.id);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PaymentSuccessPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Failed")),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F2FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Secure Payment",
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [

              /// CREDIT CARD UI
              Container(
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xff7F5AF0), Color(0xff6246EA)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Icon(Icons.credit_card,
                        color: Colors.white, size: 40),

                    const Spacer(),

                    Text(
                      cardNumber.text.isEmpty
                          ? "XXXX XXXX XXXX XXXX"
                          : cardNumber.text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          letterSpacing: 2),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Text(
                          cardName.text.isEmpty
                              ? "CARD HOLDER"
                              : cardName.text.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white70),
                        ),

                        Text(
                          expiry.text.isEmpty ? "MM/YY" : expiry.text,
                          style: const TextStyle(
                              color: Colors.white70),
                        )
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// PAYMENT FORM
              Form(
                key: _formKey,
                child: Column(
                  children: [

                    /// CARD NUMBER
                    TextFormField(
                      controller: cardNumber,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        CardFormatter()
                      ],
                      decoration: inputDecoration("Card Number"),
                      validator: (value) {
                        if (value == null ||
                            value.replaceAll(" ", "").length != 16) {
                          return "Enter valid 16 digit card number";
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    /// CARD HOLDER
                    TextFormField(
                      controller: cardName,
                      decoration: inputDecoration("Card Holder Name"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter name";
                        }

                        if (!RegExp(r'^[a-zA-Z ]{3,15}$')
                            .hasMatch(value)) {
                          return "Enter valid name";
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [

                        /// EXPIRY
                        Expanded(
                          child: TextFormField(
                            controller: expiry,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              ExpiryFormatter()
                            ],
                            decoration: inputDecoration("Expiry MM/YY"),
                            validator: (value) {

                              if (value == null || value.length != 5) {
                                return "Invalid";
                              }

                              final parts = value.split('/');
                              int month = int.parse(parts[0]);
                              int year = int.parse(parts[1]);

                              if (month < 1 || month > 12) {
                                return "Invalid";
                              }

                              final now = DateTime.now();
                              int currentYear = now.year % 100;
                              int currentMonth = now.month;

                              if (year < currentYear ||
                                  (year == currentYear &&
                                      month < currentMonth)) {
                                return "Expired";
                              }

                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),

                        const SizedBox(width: 15),

                        /// CVV
                        Expanded(
                          child: TextFormField(
                            controller: cvv,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3)
                            ],
                            decoration: inputDecoration("CVV"),
                            validator: (value) {
                              if (value == null || value.length != 3) {
                                return "Invalid";
                              }
                              return null;
                            },
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 30),

                    /// PAY BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff7F5AF0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isProcessing
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                "Pay ₹${widget.amt}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Secure Payment Powered by FragranceHub",
                      style: TextStyle(color: Colors.grey),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class CardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue) {

    var text = newValue.text.replaceAll(" ", "");

    if (text.length > 16) return oldValue;

    var newText = "";

    for (int i = 0; i < text.length; i++) {
      if (i % 4 == 0 && i != 0) newText += " ";
      newText += text[i];
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue) {

    String text = newValue.text.replaceAll("/", "");

    if (text.length > 4) return oldValue;

    if (text.length >= 3) {
      text = "${text.substring(0,2)}/${text.substring(2)}";
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}