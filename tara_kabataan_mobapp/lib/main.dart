import 'package:flutter/material.dart';
import 'blogs.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'connection_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // For android emulator to allow HTTP connections
  if (!kIsWeb && Platform.isAndroid) {
    HttpOverrides.global = MyHttpOverrides();
  }
  
  runApp(const MyApp());
}

// This class helps with handling certificate verification issues
// when connecting to localhost on Android
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tara Kabataan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A3FF),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: kDebugMode ? const StartScreen() : const BlogsPage(),
      // Add error handling for route navigation
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),
          child: child!,
        );
      },
    );
  }
}

// A startup screen to help with debugging
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/public/tarakabataanlogo2.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 30),
            const Text(
              'Tara Kabataan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Bogart',
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BlogsPage()),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to App'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ConnectionTestScreen()),
                );
              },
              icon: const Icon(Icons.network_check),
              label: const Text('Run Connection Test'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}