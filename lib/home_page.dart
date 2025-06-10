import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selamty/customlogoauth.dart';
import 'package:selamty/VisiteurHomePage.dart';
import 'login_page.dart';
import 'locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language, color: Colors.black),
            onSelected: (locale) {
              provider.setLocale(locale);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: Locale('fr'), child: Text("🇫🇷 Français")),
              const PopupMenuItem(
                  value: Locale('en'), child: Text("🇬🇧 English")),
              const PopupMenuItem(
                  value: Locale('ar'), child: Text("🇲🇷 العربية")),
            ],
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFF5F5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CustomLogoAuth(),
                    const SizedBox(height: 30),
                    Text(
                      loc.welcome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.chooseMode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const VisiteurHomePage()),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: Text(loc.visitor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(230, 2, 43, 10),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        shadowColor: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                      icon: const Icon(Icons.manage_accounts_rounded),
                      label: Text(loc.provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 185, 93, 6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        shadowColor: Colors.deepPurpleAccent,
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
}
