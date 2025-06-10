import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(loc.profile_title),
        backgroundColor: const Color.fromARGB(255, 218, 163, 11),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? Center(child: Text(loc.no_user))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal[200],
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName ?? loc.not_provided,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? loc.not_provided,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.account_circle_outlined, color: Colors.teal[700]),
                            title: Text(loc.full_name),
                            subtitle: Text(user.displayName ?? loc.not_provided),
                          ),
                          const Divider(),
                          ListTile(
                            leading: Icon(Icons.email_outlined, color: Colors.teal[700]),
                            title: Text(loc.email_address),
                            subtitle: Text(user.email ?? loc.not_provided),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(loc.confirm),
                            content: Text(loc.logout_question),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(loc.cancel),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context); // Ferme la boîte de dialogue
                                  await FirebaseAuth.instance.signOut();
                                  Navigator.popUntil(context, (route) => route.isFirst);
                                },
                                child: Text(loc.logout),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(loc.logout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 201, 132, 4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
