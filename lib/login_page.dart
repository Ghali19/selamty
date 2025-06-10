import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:selamty/fournisseur_home.dart.dart';
import 'register_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  void showMessage(String message, {Color color = Colors.orange}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _login() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!isValidEmail(email)) {
      showMessage(loc.invalidEmailMessage);
      setState(() => _loading = false);
      return;
    }

    if (password.length < 6) {
      showMessage(loc.passwordTooShortMessage);
      setState(() => _loading = false);
      return;
    }

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception("UID introuvable");

      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/api/utilisateurs/$uid/"),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);

        if (userData['isBlocked'] == true) {
          await FirebaseAuth.instance.signOut();
          showMessage(loc.userBlockedMessage, color: Colors.red);
          setState(() => _loading = false);
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FournisseurHomePage()),
        );
      } else {
        showMessage(loc.userNotFoundMessage);
      }
    } on FirebaseAuthException catch (e) {
      final loc = AppLocalizations.of(context)!;
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = loc.invalidEmailMessage;
          break;
        case 'user-not-found':
        case 'wrong-password':
          message = loc.invalidCredentialsMessage;
          break;
        case 'user-disabled':
          message = loc.userDisabledMessage;
          break;
        case 'too-many-requests':
          message = loc.tooManyRequestsMessage;
          break;
        default:
          message = "${loc.authErrorMessage}: ${e.message}";
      }
      showMessage(message);
    } catch (e) {
      showMessage(loc.authErrorMessage);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 64, color: theme.primaryColor),
                    const SizedBox(height: 20),
                    Text(loc.loginTitle,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: loc.emailLabel,
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.passwordLabel,
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(165, 115, 6, 1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(loc.loginButton,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage()),
                        );
                      },
                      child: Text(loc.signupRedirect,
                          style: const TextStyle(color: Colors.blue)),
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
}
