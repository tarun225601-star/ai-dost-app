import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  // Flutter बाइंडिंग्स को सुरक्षित करने के लिए
  WidgetsFlutterBinding.ensureInitialized();

  // भविष्य में यहाँ Supabase, Local Storage या Riverpod इनिशियलाइज होगा
  // await Supabase.initialize(...);

  runApp(const AIDostApp());
}
