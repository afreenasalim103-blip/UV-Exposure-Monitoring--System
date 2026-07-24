
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_apps/splash_screen.dart';
import 'package:flutter/material.dart';


import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://aoyiapuiwqcfpggplrwn.supabase.co',
    anonKey: 'sb_publishable_ZkCDgiDMyvODbFuQTOigSg_3L0neN7t',
  );
  runApp(MyApp());
}
  final supabase = Supabase.instance.client;

      
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFC59A6D);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Dashboard',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: gold,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: gold,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
