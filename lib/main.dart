import 'package:daily_quotes/quote.home.page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Motivation',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212),
        primaryColor: Color(0xFF121212),
        cardColor: Color(0xFF1E1E1E),
        textTheme: GoogleFonts.merriweatherTextTheme(ThemeData.dark().textTheme),
      ),
      home: QuoteHomePage(),
    );
  }
}
