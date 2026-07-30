import 'package:flutter/material.dart';

class AIDostApp extends StatelessWidget {
  const AIDostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Dost',
      debugShowCheckedModeBanner: false,
      // प्रोफेशनल डार्क थीम सेट कर रहे हैं ताकि आंखों को सुकून मिले
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // डीप डार्क बैकग्राउंड
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E1E),
        ),
        fontFamily: 'Roboto', // इसे बाद में कस्टम फोंट से बदल सकते हैं
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// अभी के लिए एक सिंपल स्टार्टअप स्क्रीन का ढांचा
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.smart_toy_rounded,
              size: 80,
              color: Color(0xFF6C63FF),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI Dost',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'आपका अपना सच्चा और स्मार्ट साथी',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
