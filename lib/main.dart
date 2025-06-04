import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/screens/event_screen.dart';
import 'package:cep_flutter_web/config/config.dart';

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
  print("🌐 BASE_URL: ${AppConfig.baseUrl}");
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

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = AppConfig.baseUrl;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true;

  Future<void> _signInWithGoogle() async {
    try {
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

      _navigateToEventScreen(backendUser);
    } catch (e) {
      _showError('Error al iniciar sesión con Google: $e');
    }
  }

  Future<void> _signInWithEmailAndPassword() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError("Completa todos los campos.");
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final backendUser = await _getUserByEmail(email);
      _navigateToEventScreen(backendUser);
    } catch (e) {
      _showError('Error de inicio de sesión: $e');
    }
  }

  Future<void> _registerWithEmailAndPassword() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    print("📩 Email: $email");
    print("🔑 Password: $password");

    if (email.isEmpty || password.isEmpty) {
      _showError("Completa todos los campos.");
      return;
    }

    if (password.length < 6) {
      _showError("La contraseña debe tener al menos 6 caracteres.");
      return;
    }

    try {
      print("🛠 Intentando registrar en Firebase...");
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      print("✅ Registro en Firebase OK. Registrando en backend...");
      final backendUser = await _registerOrLoginBackendUser(email.split('@').first, email, password);
      print("➡️ backendUser: $backendUser");

      _navigateToEventScreen(backendUser);
    } catch (e) {
      print("❌ Error de Firebase: $e");
      _showError('Error al registrarse: $e');
    }
  }

  Future<Map<String, dynamic>?> _registerOrLoginBackendUser(String username, String email, [String password = 'from_google']) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password_hash': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return await _getUserByEmail(email);
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/api/users/by-email?email=$email'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  void _navigateToEventScreen(Map<String, dynamic>? backendUser) {
    if (backendUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EventScreen(userId: backendUser['id']),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', height: 150),
                    Text(
                      isLogin ? "Inicia sesión para continuar" : "Crea una cuenta",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: "Contraseña"),
                      obscureText: true,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLogin ? _signInWithEmailAndPassword : _registerWithEmailAndPassword,
                      child: Text(isLogin ? "Iniciar sesión" : "Registrarse"),
                    ),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(isLogin ? "¿No tienes cuenta? Regístrate" : "¿Ya tienes cuenta? Inicia sesión"),
                    ),
                    //Divider(),
                    //ElevatedButton.icon(
                    //  style: ElevatedButton.styleFrom(
                    //    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    //    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //    backgroundColor: Color(0xFFD32F2F),
                    //  ),
                    //  icon: Icon(Icons.login),
                    //  label: Text("Iniciar sesión con Google"),
                    //  onPressed: _signInWithGoogle,
                    //),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
