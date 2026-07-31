import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const AiDostApp());
}

class AiDostApp extends StatelessWidget {
  const AiDostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Global Studio',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.indigo,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SingleSmartChatScreen(), 
    const ModesListScreen(),       
    const SettingsScreen(),        
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.indigoAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat & VIP'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: '10 Modes'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'API Settings'),
        ],
      ),
    );
  }
}

class SingleSmartChatScreen extends StatefulWidget {
  const SingleSmartChatScreen({super.key});

  @override
  State<SingleSmartChatScreen> createState() => _SingleSmartChatScreenState();
}

class _SingleSmartChatScreenState extends State<SingleSmartChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskInstructionsController = TextEditingController();
  
  bool _isEditingForm = false;
  bool _isLoading = false;
  String _activeTaskTitle = "सामान्य सहायक (General Assistant)";
  String _activeSystemPrompt = "तुम एक स्मार्ट एआई असिस्टेंट हो।";
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadSavedTaskForm();
  }

  _loadSavedTaskForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTitle = prefs.getString('vip_task_title');
    String? savedPrompt = prefs.getString('vip_task_prompt');

    if (savedTitle != null && savedTitle.isNotEmpty) {
      setState(() {
        _activeTaskTitle = savedTitle;
        _taskTitleController.text = savedTitle;
      });
    }
    if (savedPrompt != null && savedPrompt.isNotEmpty) {
      setState(() {
        _activeSystemPrompt = savedPrompt;
        _taskInstructionsController.text = savedPrompt;
      });
    }

    setState(() {
      _messages.add({
        'sender': 'ai', 
        'text': 'नमस्ते! मैं पूरी तरह तैयार हूँ। अपना सवाल पूछें।'
      });
    });
  }

  _saveAndApplyTaskForm() async {
    if (_taskInstructionsController.text.trim().isEmpty) return;

    String title = _taskTitleController.text.trim().isEmpty ? "कस्टम टास्क" : _taskTitleController.text.trim();
    String prompt = _taskInstructionsController.text.trim();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('vip_task_title', title);
    await prefs.setString('vip_task_prompt', prompt);

    setState(() {
      _activeTaskTitle = title;
      _activeSystemPrompt = prompt;
      _isEditingForm = false;
      _messages.add({
        'sender': 'ai', 
        'text': '✨ नया टास्क और निर्देश सेट हो गया है: "$_activeTaskTitle"'
      });
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String userText = _messageController.text;
    
    setState(() {
      _messages.add({'sender': 'user', 'text': userText});
      _messageController.clear();
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String apiKey = prefs.getString('gemini_api_key') ?? '';

      if (apiKey.isEmpty) {
        setState(() {
          _messages.add({
            'sender': 'ai', 
            'text': '⚠️ पहले API Settings टैब में जाकर अपनी असली Gemini API Key सेव करें!'
          });
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "system_instruction": {
            "parts": [{"text": _activeSystemPrompt}]
          },
          "contents": [
            {
              "parts": [{"text": userText}]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['candidates'][0]['content']['parts'][0]['text'];

        setState(() {
          _messages.add({'sender': 'ai', 'text': aiResponse});
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({'sender': 'ai', 'text': '❌ API एरर (${response.statusCode}): ${response.body}'});
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': '❌ कनेक्शन एरर: $e'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Global Studio - VIP Chat', style: TextStyle(fontSize: 16)),
            Text('एक्टिव: $_activeTaskTitle', style: const TextStyle(fontSize: 11, color: Colors.indigoAccent)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(_isEditingForm ? Icons.close : Icons.playlist_add, color: Colors.indigoAccent),
            onPressed: () => setState(() => _isEditingForm = !_isEditingForm),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isEditingForm)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1E293B),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VIP चैट बॉक्स फॉर्म (टास्क सेट करें):', style: TextStyle(fontSize: 12, color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _taskTitleController,
                      decoration: InputDecoration(
                        hintText: 'टास्क का नाम',
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _taskInstructionsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'यहाँ निर्देश (System Prompt) डालें...',
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                        onPressed: _saveAndApplyTaskForm,
                        child: const Text('Save & Update Bot', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.indigo : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Colors.indigoAccent),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'यहाँ सवाल पूछें...',
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigoAccent),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ModesListScreen extends StatelessWidget {
  const ModesListScreen({super.key});

  final List<String> modes = const [
    '1. Business Consultant', '2. Hotel Manager', '3. Voice Companion',
    '4. Code Architect', '5. Media Creator', '6. Data Automation',
    '7. Voice Biometric', '8. Sarcastic AI', '9. Task Scheduler', '10. Super-Bot'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('10 AI Modes'), backgroundColor: const Color(0xFF1E293B)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
        ),
        itemCount: modes.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.withOpacity(0.4)),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(modes[index], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _geminiKeyController = TextEditingController();
  final TextEditingController _razorpayKeyController = TextEditingController();
  final TextEditingController _supabaseUrlController = TextEditingController();
  final TextEditingController _supabaseKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  _loadKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _geminiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _razorpayKeyController.text = prefs.getString('razorpay_key') ?? '';
      _supabaseUrlController.text = prefs.getString('supabase_url') ?? '';
      _supabaseKeyController.text = prefs.getString('supabase_key') ?? '';
    });
  }

  _saveKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _geminiKeyController.text);
    await prefs.setString('razorpay_key', _razorpayKeyController.text);
    await prefs.setString('supabase_url', _supabaseUrlController.text);
    await prefs.setString('supabase_key', _supabaseKeyController.text);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('सेटिंग्स सेव हो गई हैं!')));
  }

  @override
  Widget build(BuildContext context) {
    Widget buildField(String label, TextEditingController controller, String hint, {bool obscure = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 14),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('API Settings'), backgroundColor: const Color(0xFF1E293B)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildField('Gemini API Key', _geminiKeyController, 'AIzaSy...', obscure: true),
            buildField('Razorpay Key', _razorpayKeyController, 'rzp_live_...', obscure: true),
            buildField('Supabase URL', _supabaseUrlController, 'https://xyz.supabase.co'),
            buildField('Supabase Key', _supabaseKeyController, 'eyJhbGci...', obscure: true),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _saveKeys,
              child: const Text('Save Configurations', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
