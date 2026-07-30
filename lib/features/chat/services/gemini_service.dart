import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../settings/services/api_key_service.dart';
import 'crisis_prompt_helper.dart';

class GeminiService {
  static Future<String> sendMessage(String prompt, String systemInstruction, int modeId) async {
    try {
      // 1. सेटिंग से यूजर की डाली हुई API Key फेच करें
      String? apiKey = await ApiKeyService.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return "कृपया पहले कोने में दिए गए सेटिंग आइकॉन पर क्लिक करके अपनी Gemini API Key दर्ज करें!";
      }

      // 2. अगर मोड नंबर 5 (संकटमोचन) है, तो उसका खास क्राइसिस प्रॉम्प्ट जोड़ें
      String finalInstruction = systemInstruction;
      if (modeId == 5) {
        finalInstruction += "\n" + CrisisPromptHelper.getCrisisInstruction(5);
      }

      final String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey";

      // 3. जेमिनी API को रिक्वेस्ट भेजें
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "System Instruction: $finalInstruction\n\nUser: $prompt"}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidate = data['candidates']?[0];
        if (candidate != null) {
          return candidate['content']['parts'][0]['text'] ?? "क्षमा करें, कोई उत्तर नहीं मिला।";
        }
      }
      return "एपीआई एरर (Error: ${response.statusCode}). कृपया अपनी API Key जांच लें।";
    } catch (e) {
      return "कनेक्शन एरर: $e";
    }
  }
}
