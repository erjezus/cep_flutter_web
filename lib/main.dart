import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:cep_flutter_web/screens/event_screen.dart';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';

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
  await Firebase.initializeApp(options: firebaseConfig);
  final user = FirebaseAuth.instance.currentUser;

  runApp(MyApp(isLoggedIn: user != null, userEmail: user?.email));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userEmail;

  const MyApp({required this.isLoggedIn, this.userEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Perolón',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFB71C1C),
          brightness: Brightness.light,
        ),
        textTheme: Typography.blackCupertino.copyWith(
          bodyMedium: TextStyle(fontSize: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFB71C1C)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFB71C1C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      ),
      home: isLoggedIn && userEmail != null
          ? LoadingWithFrases(
        future: _getUserByEmail(userEmail!),
        onDone: (backendUser) => backendUser != null
            ? EventScreen(
          userId: backendUser['id'],
          userName: backendUser['username'],
        )
            : LoginScreen(),
      )
          : LoginScreen(),
    );
  }

  Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    const int maxRetries = 5;
    const Duration delay = Duration(seconds: 2);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/api/users/by-email?email=$email'),
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }

        if (response.statusCode == 503 || response.statusCode == 502) {
          await Future.delayed(delay * (attempt + 1));
          continue;
        }

        break;
      } catch (e) {
        await Future.delayed(delay * (attempt + 1));
      }
    }

    return null;
  }
}

class LoadingWithFrases extends StatefulWidget {
  final Future<Map<String, dynamic>?> future;
  final Widget Function(Map<String, dynamic>?) onDone;

  const LoadingWithFrases({super.key, required this.future, required this.onDone});

  @override
  State<LoadingWithFrases> createState() => _LoadingWithFrasesState();
}

class _LoadingWithFrasesState extends State<LoadingWithFrases> {
  final frasesCubatas = [
    "Agitando el cubata... esto tarda menos que la cola del bar.",
    "Preparando tu cubata virtual... con su hielo, su limón y su paciencia.",
    "Cargando la app... y sirviendo cubatas como Dios manda.",
    "Removiendo el cubata y conectando con la feria... un segundo.",
    "Montando los cubatas... que esto no es agua con misterio.",
    "Montando la caseta... que esto no se hace solo.",
    "Cargando feria... ¡no te impacientes que ya suenan las sevillanas!",
    "Reponiendo hielo y montando la barra... dame un segundo.",
    "Preparando tu próxima ronda... 🥳🍻"
  ];

  int _currentFraseIndex = 0;
  Timer? _timer;
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentFraseIndex = Random().nextInt(frasesCubatas.length);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?> (
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      frasesCubatas[_currentFraseIndex],
                      key: ValueKey(_currentFraseIndex),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB71C1C),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return widget.onDone(snapshot.data);
        }
      },
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
  final TextEditingController nameController = TextEditingController();
  bool isLogin = true;
  final bool showGoogleButton = false;

  Future<void> _signInWithGoogle() async {
    try {

      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL); // <- mantiene la sesión activa incluso tras cerrar navegador

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
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showError("Completa todos los campos.");
      return;
    }

    if (password.length < 6) {
      _showError("La contraseña debe tener al menos 6 caracteres.");
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final backendUser = await _registerOrLoginBackendUser(name, email, password);
      _navigateToEventScreen(backendUser);
    } catch (e) {
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
          builder: (_) => EventScreen(
            userId: backendUser['id'],
            userName: backendUser['username'],
          ),
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
          child: StandardCard(
            elevation: 12,
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.png', height: 150),
                  const SizedBox(height: 16),
                  Text(
                    isLogin ? "Bienvenido de nuevo" : "Crea una cuenta",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 24),
                  if (!isLogin)
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nombre",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  if (!isLogin) const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLogin ? _signInWithEmailAndPassword : _registerWithEmailAndPassword,
                    child: Text(isLogin ? "Iniciar sesión" : "Registrarse"),
                  ),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(isLogin ? "¿No tienes cuenta? Regístrate" : "¿Ya tienes cuenta? Inicia sesión"),
                  ),
                  const Divider(height: 32),
                  if (showGoogleButton)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text("Continuar con Google"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFFB71C1C),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      onPressed: _signInWithGoogle,
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