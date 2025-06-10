import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:selamty/fournisseur_home.dart.dart';
import 'login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _loading = false;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  void showMessage(String message, {Color color = const Color.fromRGBO(180, 127, 12, 1)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _register() async {
    final loc = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showMessage(loc.fillAllFields);
      return;
    }

    if (!isValidEmail(email)) {
      showMessage(loc.invalidEmailMessage);
      return;
    }

    if (password.length < 6) {
      showMessage(loc.passwordTooShortMessage);
      return;
    }

    if (password != confirmPassword) {
      showMessage(loc.passwordsDoNotMatch);
      return;
    }

    setState(() => _loading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception("UID utilisateur introuvable.");

      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/api/utilisateurs/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': uid,
          'nom': name,
          'email': email,
          'role': 'fournisseur',
        }),
      );

      if (response.statusCode == 201) {
        showMessage(loc.accountCreated, color: Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        showMessage(loc.firestoreRegistrationError);
      }
    } on FirebaseAuthException catch (e) {
      final loc = AppLocalizations.of(context)!;
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = loc.emailAlreadyInUse;
          break;
        case 'invalid-email':
          message = loc.invalidEmailMessage;
          break;
        case 'weak-password':
          message = loc.weakPasswordMessage;
          break;
        default:
          message = '${loc.authErrorMessage}: ${e.message}';
      }
      showMessage(message);
    } catch (e) {
      showMessage(loc.unexpectedError);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_alt_1, size: 64),
                  const SizedBox(height: 20),
                  Text(loc.registerTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: loc.nameLabel,
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: loc.emailLabel,
                      prefixIcon: const Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: loc.passwordLabel,
                      prefixIcon: const Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: loc.confirmPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(161, 115, 15, 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(loc.registerButton,
                              style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.alreadyRegistered),
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
