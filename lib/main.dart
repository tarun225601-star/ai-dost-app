class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // चारों सेटिंग्स के लिए कंट्रोलर
  final TextEditingController _geminiKeyController = TextEditingController();
  final TextEditingController _razorpayKeyController = TextEditingController();
  final TextEditingController _supabaseUrlController = TextEditingController();
  final TextEditingController _supabaseKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKeys(); // ऐप खुलते ही पुरानी सेव की हुई की लोड हो जाएंगी
  }

  // डेटा लोड करने का फंक्शन
  _loadKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _geminiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _razorpayKeyController.text = prefs.getString('razorpay_key') ?? '';
      _supabaseUrlController.text = prefs.getString('supabase_url') ?? '';
      _supabaseKeyController.text = prefs.getString('supabase_key') ?? '';
    });
  }

  // चारों को परमानेंट सेव करने का फंक्शन
  _saveKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _geminiKeyController.text);
    await prefs.setString('razorpay_key', _razorpayKeyController.text);
    await prefs.setString('supabase_url', _supabaseUrlController.text);
    await prefs.setString('supabase_key', _supabaseKeyController.text);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('सफलतापूर्वक चारों API और Supabase सेटिंग्स सेव हो गई हैं!')),
    );
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
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('4 Core API Settings'), backgroundColor: const Color(0xFF1E293B)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildField('1. Gemini API Key', _geminiKeyController, 'AIzaSy...', obscure: true),
            buildField('2. Razorpay API Key', _razorpayKeyController, 'rzp_live_... / rzp_test_...', obscure: true),
            buildField('3. Supabase Link (URL)', _supabaseUrlController, 'https://xyzcompany.supabase.co'),
            buildField('4. Supabase API Key', _supabaseKeyController, 'eyJhbGciOiJIUzI1NiIsIn...', obscure: true),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(14)),
                onPressed: _saveKeys,
                child: const Text('Save All 4 Configurations', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
