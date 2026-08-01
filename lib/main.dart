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
      title: 'AI Global Studio - Llama 3.3 Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.indigo,
        colorScheme: const ColorScheme.dark(
          primary: Colors.indigoAccent,
          secondary: Colors.greenAccent,
        ),
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
    const BusinessChatScreen(), 
    const ModesListScreen(),       
    const ApiSettingsScreen(),        
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.business_center), label: 'Business Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: '10 Modes'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'API Settings'),
        ],
      ),
    );
  }
}

class BusinessChatScreen extends StatefulWidget {
  const BusinessChatScreen({super.key});

  @override
  State<BusinessChatScreen> createState() => _BusinessChatScreenState();
}

class _BusinessChatScreenState extends State<BusinessChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  
  // ऊपर बिजनेस का नाम और नीचे प्रॉम्प्ट डालने के लिए अलग फील्ड्स
  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _customPromptController = TextEditingController();
  
  bool _isEditingForm = false;
  bool _isLoading = false;
  
  String _activeBusiness = "General Business";
  String _activeSystemPrompt = "तुम एक एक्सपर्ट बिजनेस कंसलटेंट हो जो कंपनियों और स्टार्टअप्स को आगे बढ़ाने में मदद करते हैं।";
  
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadSavedBusinessSettings();
  }

  _loadSavedBusinessSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedBusiness = prefs.getString('biz_type');
    String? savedPrompt = prefs.getString('biz_prompt');

    if (savedBusiness != null && savedBusiness.isNotEmpty) {
      setState(() {
        _activeBusiness = savedBusiness;
        _businessTypeController.text = savedBusiness;
      });
    }
    if (savedPrompt != null && savedPrompt.isNotEmpty) {
      setState(() {
        _activeSystemPrompt = savedPrompt;
        _customPromptController.text = savedPrompt;
      });
    }

    setState(() {
      _messages.add({
        'sender': 'ai', 
        'text': 'नमस्ते! Llama 3.3 (70B) मॉडल के साथ आपका बिजनेस एआई पार्टनर तैयार है। वर्तमान बिजनेस: $_activeBusiness'
      });
    });
  }

  _saveAndActivateBusinessMode() async {
    String businessName = _businessTypeController.text.trim();
    String promptText = _customPromptController.text.trim();

    if (businessName.isEmpty || promptText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ कृपया ऊपर बिजनेस का नाम और नीचे प्रॉम्प्ट दोनों भरें!'))
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('biz_type', businessName);
    await prefs.setString('biz_prompt', promptText);

    setState(() {
      _activeBusiness = businessName;
      _activeSystemPrompt = promptText;
      _isEditingForm = false;
      _messages.add({
        'sender': 'ai', 
        'text': '✅ नया बिजनेस मोड सेट हो गया: "$businessName"। अब मैं Llama 3.3 के साथ इसी रोल में काम करूँगा।'
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
      String groqKey = prefs.getString('groq_api_key') ?? '';

      if (groqKey.isEmpty) {
        setState(() {
          _messages.add({
            'sender': 'ai', 
            'text': '⚠️ कृपया पहले "API Settings" टैब में जाकर अपनी Groq API Key सेव करें!'
          });
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile", // यहाँ Groq का लेटेस्ट Llama 3.3 मॉडल सेट है
          "messages": [
            {"role": "system", "content": _activeSystemPrompt},
            {"role": "user", "content": userText}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'];

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
            const Text('AI Business Studio (Llama 3.3)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('बिजनेस: $_activeBusiness', style: const TextStyle(fontSize: 11, color: Colors.greenAccent)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(_isEditingForm ? Icons.close : Icons.tune, color: Colors.greenAccent),
            tooltip: 'बिजनेस और प्रॉम्प्ट सेट करें',
            onPressed: () => setState(() => _isEditingForm = !_isEditingForm),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isEditingForm)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏢 1. ऊपर डालें (क्या बिजनेस है?):', style: TextStyle(fontSize: 13, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _businessTypeController,
                      decoration: InputDecoration(
                        hintText: 'जैसे: Hotel, Bank, Hospital...',
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('✍️ 2. नीचे डालें (एआई से क्या काम करवाना है - Prompt):', style: TextStyle(fontSize: 13, color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customPromptController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'यहाँ लिखें कि Llama 3.3 को इस बिजनेस में क्या भूमिका निभानी है...',
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        onPressed: _saveAndActivateBusinessMode,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('Save & Apply Business Mode', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
              child: LinearProgressIndicator(color: Colors.greenAccent),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'अपने बिजनेस से जुड़ा सवाल यहाँ पूछें...',
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
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

  final List<Map<String, String>> modes = const [
    {'title': '1. Hotel Manager', 'desc': 'होटल बुकिंग और गेस्ट सर्विस'},
    {'title': '2. Bank Advisor', 'desc': 'लोन और फाइनेंसियल प्लानिंग'},
    {'title': '3. Hospital Admin', 'desc': 'हेल्थकेयर और पेशेंट मैनेजमेंट'},
    {'title': '4. Code Architect', 'desc': 'सॉफ्टवेयर और ऐप कोडिंग'},
    {'title': '5. Business Coach', 'desc': 'स्टार्टअप ग्रोथ और स्ट्रेटजी'},
    {'title': '6. Data Automation', 'desc': 'ऑटोमेशन और वर्कफ़्लो'},
    {'title': '7. Voice Companion', 'desc': 'स्मार्ट कन्वर्सेशन बॉट'},
    {'title': '8. Marketing Expert', 'desc': 'डिजिटल मार्केटिंग और सेल्स'},
    {'title': '9. Task Scheduler', 'desc': 'डेली टास्क और प्लानिंग'},
    {'title': '10. Super-Bot Pro', 'desc': 'अल्टीमेट ऑलराउंडर एआई'}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('10 Specialized AI Modes'), backgroundColor: const Color(0xFF1E293B)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
        ),
        itemCount: modes.length,
        itemBuilder: (context, index) {
          final mode = modes[index];
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mode['title']!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 13)),
                const SizedBox(height: 6),
                Text(mode['desc']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _groqKeyController = TextEditingController();
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
      _groqKeyController.text = prefs.getString('groq_api_key') ?? '';
      _supabaseUrlController.text = prefs.getString('supabase_url') ?? '';
      _supabaseKeyController.text = prefs.getString('supabase_key') ?? '';
    });
  }

  _saveKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_api_key', _groqKeyController.text.trim());
    await prefs.setString('supabase_url', _supabaseUrlController.text.trim());
    await prefs.setString('supabase_key', _supabaseKeyController.text.trim());
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ सेटिंग्स सफलतापूर्वक सेव हो गई हैं!')));
  }

  @override
  Widget build(BuildContext context) {
    Widget buildField(String label, TextEditingController controller, String hint, {bool obscure = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: hint, 
              filled: true, 
              fillColor: const Color(0xFF1E293B), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
            ),
          ),
          const SizedBox(height: 14),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('API & Database Settings'), backgroundColor: const Color(0xFF1E293B)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildField('Groq API Key', _groqKeyController, 'gsk_...', obscure: true),
            buildField('Supabase Project URL', _supabaseUrlController, 'https://xyz.supabase.co'),
            buildField('Supabase Anon / API Key', _supabaseKeyController, 'eyJhbGci...', obscure: true),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: _saveKeys,
                child: const Text('Save Configurations', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// मान ले तेरी फाइल का बाकी कोड ऊपर लिखा है...

// और यह वाला हिस्सा बिल्कुल सबसे नीचे (फाइल के अंत में) चिपका दे:
Future<void> callGroqApi() async {
  try {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer तेरी_एपीआई_की_यहाँ_डाल',
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "user", "content": "hi"}
        ]
      }),
    );

        if (response.statusCode == 200) {
      print("मस्त काम हो गया: ${response.body}");
    } else {
      print("सर्वर का एरर कोड: ${response.statusCode}");
      print("वजह: ${response.body}");
    }
  } catch (e, stackTrace) {
    print("❌ असली एरर की वजह यह रही: $e");
    print("स्टैक ट्रेस: $stackTrace");
  }
}

}
