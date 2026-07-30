import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService {
  static const String _keyName = 'gemini_api_key';

  // सेव करें
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, apiKey.trim());
  }

  // रीड करें
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }
}
