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
          // Título alineado a la izquierda — estándar en web
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 6),
          // Radio 12: más profesional que el 20 original
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
        textTheme: Typography.blackCupertino.copyWith(
          titleLarge: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
          bodySmall: TextStyle(fontSize: 13, color: Colors.grey[600]),
          labelSmall: TextStyle(fontSize: 11, color: Colors.grey[500], letterSpacing: 0.2),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        // FAB coherente en toda la app
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    // Render free tier puede tardar hasta 60 s en arrancar (cold start).
    // Usamos un timeout generoso por intento y varios reintentos.
    const int maxRetries = 8;
    const Duration requestTimeout = Duration(seconds: 65);
    const Duration retryDelay = Duration(seconds: 5);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse('${AppConfig.baseUrl}/api/users/by-email?email=$email'))
            .timeout(requestTimeout);

        if (response.statusCode == 200) {
          return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        }

        if (response.statusCode == 503 || response.statusCode == 502) {
          await Future.delayed(retryDelay);
          continue;
        }

        break;
      } catch (e) {
        // TimeoutException u otro error de red → reintentamos
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
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

  // Frases que aparecen tras 15 s para avisar del cold start del servidor
  final frasesColdStart = [
    "☕ El servidor estaba echando la siesta... ya se está despertando.",
    "😴 Oye, que el servidor también necesita su descanso. Dale un segundo.",
    "🐢 El servidor iba a su ritmo, pero ya va arrancando.",
    "☀️ Despertando el servidor como los domingos: poco a poco.",
    "🔌 El servidor estaba en reposo. Puede tardar hasta un minuto. ¡Paciencia!",
    "🍳 Preparando el servidor como un buen desayuno... que las prisas no son buenas.",
    "💤 Al servidor también le da la tarde. Ya está volviendo.",
  ];

  int _currentFraseIndex = 0;
  int _currentColdStartIndex = 0;
  Timer? _timer;
  int _elapsed = 0;
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed++;
          if (_elapsed % 10 == 0) {
            _currentFraseIndex = Random().nextInt(frasesCubatas.length);
          }
          // Rota las frases de cold start cada 8 s
          if (_elapsed >= 15 && (_elapsed - 15) % 8 == 0) {
            _currentColdStartIndex = Random().nextInt(frasesColdStart.length);
          }
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
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final bool coldStart = _elapsed >= 15;
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
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
                    if (coldStart) ...[
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Text(
                          frasesColdStart[_currentColdStartIndex],
                          key: ValueKey(_currentColdStartIndex),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 720) {
            // Desktop: panel de marca izquierda + formulario derecha
            return Row(
              children: [
                Expanded(flex: 4, child: _buildBrandPanel()),
                Expanded(flex: 6, child: _buildFormContent()),
              ],
            );
          }
          // Mobile: cabecera compacta + formulario
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMobileHeader(),
                  _buildFormContent(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Panel izquierdo (solo desktop) con la identidad de la app
  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'app-logo',
            child: Image.asset('assets/logo.png', width: 96, height: 84, fit: BoxFit.contain),
          ),
          const SizedBox(height: 28),
          const Text(
            'El Perolón',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Gestión de eventos,\nconsumos y gastos del grupo.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 15,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  // Cabecera compacta para móvil
  Widget _buildMobileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Row(
        children: [
          Hero(
            tag: 'app-logo',
            child: Image.asset('assets/logo.png', width: 52, height: 46, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          const Text(
            'El Perolón',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Contenido del formulario (reutilizado en desktop y mobile)
  Widget _buildFormContent() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isLogin
                      ? 'Introduce tus credenciales para continuar'
                      : 'Completa los datos para registrarte',
                  style: TextStyle(fontSize: 13.5, color: Colors.grey[500], height: 1.4),
                ),
                const SizedBox(height: 24),
                _buildSegmentedToggle(),
                const SizedBox(height: 20),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: Column(
                    children: [
                      if (!isLogin) ...[
                        _buildTextField(
                          controller: nameController,
                          label: "Nombre",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildTextField(
                        controller: emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
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
                            size: 20,
                            color: Colors.grey[500],
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (isLogin
                            ? _signInWithEmailAndPassword
                            : _registerWithEmailAndPassword),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(isLogin ? "Iniciar sesión" : "Crear cuenta"),
                  ),
                ),
                if (showGoogleButton) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[200])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text("o",
                            style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: Colors.grey[200])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text("Continuar con Google"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _signInWithGoogle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }

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
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
        suffixIcon: suffix,
      ),
    );
  }
}