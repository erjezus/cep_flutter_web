import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cep_flutter_web/screens/event_screen.dart';

const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyCcd94OXJ8gy_hW2agrHGBzpQhSycQtV3c",
  authDomain: "cepw-228ab.firebaseapp.com",
  projectId: "cepw-228ab",
  storageBucket: "cepw-228ab.appspot.com",
  messagingSenderId: "1013371857474",
  appId: "1:1013371857474:web:d94f628b6f902758409bdb",
  measurementId: "G-N2L53Z8W5Y",
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga el archivo .env correspondiente
  await dotenv.load(fileName: kReleaseMode ? '.env.production' : '.env.development');

  await Firebase.initializeApp(options: firebaseConfig);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Perolón',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = dotenv.env['BASE_URL']!;

  Future<void> _signInWithGoogle(BuildContext context) async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final email = userCredential.user?.email ?? '';
    final name = userCredential.user?.displayName ?? '';

    final existingUser = await _getUserByEmail(email);
    Map<String, dynamic>? backendUser;

    if (existingUser != null) {
      backendUser = existingUser;
    } else {
      backendUser = await _registerOrLoginBackendUser(name, email);
    }

    if (backendUser != null) {
      print("✅ Navegando a EventScreen con userId: ${backendUser['id']}");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EventScreen(userId: backendUser?['id'] ?? 0),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _registerOrLoginBackendUser(String username, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password_hash': 'from_google',
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return await _getUserByEmail(email);
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/api/users?email=$email'));
    if (response.statusCode == 200) {
      final users = jsonDecode(response.body) as List;
      if (users.isNotEmpty) return users.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            margin: EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 150,
                  ),
                  Text(
                    "Inicia sesión para continuar",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Color(0xFFD32F2F),
                    ),
                    icon: Icon(Icons.login),
                    label: Text("Iniciar sesión con Google"),
                    onPressed: () => _signInWithGoogle(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}