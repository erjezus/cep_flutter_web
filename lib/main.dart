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
import 'package:cep_flutter_web/config/app_colors.dart';

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
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        // Sombras suaves y difusas en todas las tarjetas
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.black.withOpacity(0.06),
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        // Jerarquía tipográfica clara
        textTheme: Typography.blackCupertino.copyWith(
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium: const TextStyle(fontSize: 15, height: 1.3),
          bodySmall: TextStyle(fontSize: 13, color: Colors.grey[600]),
          labelSmall: TextStyle(fontSize: 11, color: Colors.grey[500], letterSpacing: 0.2),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
        // FAB coherente en toda la app (mismo color, forma y elevación)
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        // Transiciones de página fluidas en todas las plataformas
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: isLoggedIn && userEmail != null
          ? LoadingWithFrases(
        future: _getUserByEmail(userEmail!),
        onDone: (backendUser) => backendUser != null
            ? EventScreen(
          userId: backendUser['id'],
          userName: backendUser['username'],
          userRole: (backendUser['role'] ?? 'USER').toString(),
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
          return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
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
                        color: AppColors.primary,
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
  bool _obscurePassword = true;
  bool _isLoading = false;
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

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final backendUser = await _getUserByEmail(email);
      _navigateToEventScreen(backendUser);
    } catch (e) {
      _showError('Error de inicio de sesión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    setState(() => _isLoading = true);
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final backendUser = await _registerOrLoginBackendUser(name, email, password);
      _navigateToEventScreen(backendUser);
    } catch (e) {
      _showError('Error al registrarse: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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
            userRole: (backendUser['role'] ?? 'USER').toString(),
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
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo en insignia circular
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'app-logo',
                        child: SizedBox(
                          width: 300,
                          height: 260,
                          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tarjeta con el formulario
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Selector Iniciar sesión / Registrarse
                          _buildSegmentedToggle(),
                          const SizedBox(height: 24),

                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: Column(
                              children: [
                                if (!isLogin) ...[
                                  _buildTextField(
                                    controller: nameController,
                                    label: "Nombre",
                                    icon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                _buildTextField(
                                  controller: emailController,
                                  label: "Email",
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  controller: passwordController,
                                  label: "Contraseña",
                                  icon: Icons.lock_outline,
                                  obscure: _obscurePassword,
                                  onSubmitted: (_) => _isLoading
                                      ? null
                                      : (isLogin
                                          ? _signInWithEmailAndPassword()
                                          : _registerWithEmailAndPassword()),
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Botón principal
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (isLogin
                                      ? _signInWithEmailAndPassword
                                      : _registerWithEmailAndPassword),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      isLogin ? "Iniciar sesión" : "Crear cuenta",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          if (showGoogleButton) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[300])),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text("o",
                                      style: TextStyle(color: Colors.grey[500])),
                                ),
                                Expanded(child: Divider(color: Colors.grey[300])),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.login),
                                label: const Text("Continuar con Google"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _isLoading ? null : _signInWithGoogle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Selector animado entre "Iniciar sesión" y "Registrarse".
  Widget _buildSegmentedToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleOption("Iniciar sesión", isLogin),
          _buildToggleOption("Registrarse", !isLogin),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isLogin = label == "Iniciar sesión"),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// Campo de texto con estilo "filled" moderno.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}