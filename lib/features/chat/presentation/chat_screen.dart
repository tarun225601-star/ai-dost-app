import 'package:flutter/material.dart';
import '../../../core/constants/app_modes.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // डिफ़ॉल्ट रूप से पहला मोड (सिंपल चैट) सिलेक्टेड रहेगा
  AppMode _selectedMode = AppModesList.modes[0];
  
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text,
          isUser: true,
        ),
      );
      _messageController.clear();
    });

    // यहाँ भविष्य में AI API कॉल जुड़ेगा जो _selectedMode के हिसाब से जवाब देगा
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "नमस्ते! मैं आपका ' ${_selectedMode.name} ' मोड में साथी हूँ। बताइए, इसमें आपकी क्या मदद करूँ?",
            isUser: false,
          ),
        );
      });
    });
  }

  // मोड बदलने वाला डायलॉग बॉक्स
  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'अपने 10 दमदार मोड्स चुनें',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: AppModesList.modes.length,
                  itemBuilder: (context, index) {
                    final mode = AppModesList.modes[index];
                    return ListTile(
                      leading: Icon(
                        mode.isVipPredictive
                            ? Icons.star
                            : mode.isFree
                                ? Icons.chat_bubble_outline
                                : Icons.lock,
                        color: mode.isVipPredictive
                            ? Colors.amber
                            : mode.isFree
                                ? const Color(0xFF6C63FF)
                                : Colors.grey,
                      ),
                      title: Text(
                        mode.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        mode.description,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      trailing: mode.isFree
                          ? const Text('फ्री', style: TextStyle(color: Colors.green))
                          : mode.isVipPredictive
                              ? const Text('VIP', style: TextStyle(color: Colors.amber))
                              : const Text('लॉक', style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        setState(() {
                          _selectedMode = mode;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showModeSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedMode.name, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: _showModeSelector,
            tooltip: 'मोड्स बदलें',
          ),
        ],
      ),
      body: Column(
        children: [
          // चैट मैसेजेस की लिस्ट
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          ' ${_selectedMode.name} तैयार है!',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'अपनी बात नीचे टाइप करें...',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? const Color(0xFF6C63FF)
                                : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg.text,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // मैसेज इनपुट बॉक्स
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'यहाँ कुछ भी लिखें...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF6C63FF)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
