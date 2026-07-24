import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/main.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage("Hello! I'm your Uvora assistant. Tap any of the questions below to learn more about sun safety.", false),
  ];
  bool _isLoading = false;

  Map<String, String> _faqDataset = {};

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    try {
      final res = await supabase.from('tbl_chatbot_faq').select();
      Map<String, String> fetchedFaqs = {};
      for (var item in res) {
        fetchedFaqs[item['keyword'].toString()] = item['answer'].toString();
      }
      
      if (mounted) {
        setState(() {
          _faqDataset = fetchedFaqs;
        });
      }
    } catch (e) {
      debugPrint("Failed to load FAQs: $e");
      // Fallback
      if (mounted) {
        setState(() {
          _faqDataset = {
            "How often should I apply sunscreen?": "According to APIs: Reapply sunscreen every 3 hours outdoors.",
            "What is the UV Index?": "The UV Index is a scale from 0 to 11+ indicating risk of harm from unprotected sun exposure.",
          };
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendQuestion(String question, String answer) async {
    setState(() {
      _messages.add(ChatMessage(question, true));
      _isLoading = true;
    });
    _scrollToBottom();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(answer, false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFC59A6D);
    const Color bgBlack = Color(0xFF0A0A0F);
    const Color glass = Color(0xFF1E1E2E);

    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        title: Text("Assistant", style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(center: Alignment.bottomRight, radius: 1.5, colors: [gold.withOpacity(0.03), Colors.transparent]),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final content = _messages[i];
                  bool isUser = content.isUser;
                  String text = content.text;

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isUser ? const LinearGradient(colors: [Color(0xFFC59A6D), Color(0xFF7A4E2D)]) : null,
                        color: isUser ? null : glass,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                        ),
                        boxShadow: [if (isUser) BoxShadow(color: gold.withOpacity(0.2), blurRadius: 10)],
                      ),
                      child: Text(
                        text,
                        style: GoogleFonts.outfit(color: isUser ? Colors.black : Colors.white70, fontSize: 14, height: 1.4, fontWeight: isUser ? FontWeight.w600 : FontWeight.normal),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: Row(
                    children: [
                      const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(color: gold, strokeWidth: 1.5)),
                      const SizedBox(width: 10),
                      Text("Thinking...", style: GoogleFonts.outfit(color: gold, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            _buildQuestionsArea(gold),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsArea(Color gold) {
    if (_faqDataset.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F16),
        border: Border(top: BorderSide(color: gold.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              "Suggested Questions", 
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _faqDataset.keys.map((question) {
              return ActionChip(
                label: Text(question, style: const TextStyle(color: Colors.white)),
                backgroundColor: const Color(0xFF1E1E2E),
                side: BorderSide(color: gold.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: _isLoading ? null : () {
                  _sendQuestion(question, _faqDataset[question]!);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

