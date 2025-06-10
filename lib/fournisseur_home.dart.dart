import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'AjouterSignalementPage.dart';
import 'profil_page.dart';
import 'models/signalement.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FournisseurHomePage extends StatefulWidget {
  const FournisseurHomePage({super.key});

  @override
  State<FournisseurHomePage> createState() => _FournisseurHomePageState();
}

class _FournisseurHomePageState extends State<FournisseurHomePage> {
  List<Signalement> signalements = [];
  List<dynamic> notifications = [];
  bool isLoading = true;
  int selectedIndex = 0;
  int newNotificationsCount = 0;
  bool wasInNotificationTab = false;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  Set<String> expandedIds = {};

  @override
  void initState() {
    super.initState();
    fetchSignalements();
  }

  Future<void> fetchSignalements() async {
    try {
      final response = await http.get(
          Uri.parse("http://127.0.0.1:8000/api/signalements/?user_id=$uid"));
      final notifResponse = await http.get(
          Uri.parse("http://127.0.0.1:8000/api/notifications/?user_id=$uid"));

      if (response.statusCode == 200 && notifResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<dynamic> notifData = jsonDecode(notifResponse.body);

        final idsNonLus = notifData
            .where((n) => n['is_modified'] == false)
            .map((n) => n['signalement_id'])
            .toSet();

        setState(() {
          signalements = data.map((e) {
            final id = e['id'];
            return Signalement.fromJson({
              ...e,
              'is_modified': !idsNonLus.contains(id),
            });
          }).toList();

          notifications = notifData;
          newNotificationsCount = idsNonLus.length;
          isLoading = false;
        });
      } else {
        throw Exception("Erreur serveur");
      }
    } catch (e) {
      print("❌ Erreur : $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> markNotificationsAsRead() async {
    try {
      for (var notif in notifications) {
        if (notif['is_modified'] == false) {
          final id = notif['id'];
          await http.patch(
            Uri.parse('http://127.0.0.1:8000/api/notifications/$id/update/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'is_modified': true}),
          );
        }
      }

      // 🔄 petite pause avant de recharger les données
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print("❌ Erreur lors de la mise à jour des notifications : $e");
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d’ouvrir le lien : $url');
    }
  }

  Widget _buildNotifications() {
    final notifs = notifications;
    Set<int> expandedIndexes = {};

    if (notifs.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.notifications_empty));
    }

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: notifs.length,
          itemBuilder: (context, index) {
            final notif = notifs[index];
            final status = notif['status'] ?? 'en_attente';
            final isValide = status == 'valide';
            final icon = isValide ? Icons.check_circle : Icons.cancel;
            final color = isValide ? Colors.green : Colors.red;
            final message = isValide
                ? AppLocalizations.of(context)!.signalement_accepted
                : AppLocalizations.of(context)!.signalement_rejected;

            final description = notif['description'] ?? '';
            final isLong = description.length > 20;
            final isExpanded = expandedIndexes.contains(index);
            final displayedText = isExpanded || !isLong
                ? description
                : '${description.substring(0, 20)}...';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: Icon(icon, color: color, size: 30),
                title: Text(
                  message,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayedText,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (isLong)
                      GestureDetector(
                        onTap: () {
                          setLocalState(() {
                            if (isExpanded) {
                              expandedIndexes.remove(index);
                            } else {
                              expandedIndexes.add(index);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            isExpanded
                                ? AppLocalizations.of(context)!.show_less
                                : AppLocalizations.of(context)!.show_more,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.notifications),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSignalements() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: signalements.length,
      itemBuilder: (context, index) {
        final sig = signalements[index];

        final loc = AppLocalizations.of(context)!;

        // Color statusColor;
        // String statusLabel;

        // switch (sig.status.toLowerCase()) {
        //   case 'valide':
        //     statusColor = Colors.green;
        //     statusLabel = loc.status_valid;
        //     break;
        //   case 'rejete':
        //     statusColor = Colors.red;
        //     statusLabel = loc.status_rejected;
        //     break;
        //   default:
        //     statusColor = Colors.orange;
        //     statusLabel = loc.status_pending;
        // }
        String statusColor;
        String statusLabel;

        switch (sig.status.toLowerCase()) {
          case 'valide':
            statusColor = 'success'; // ✅ comme dans MUI
            statusLabel = loc.status_valid;
            break;
          case 'rejete':
            statusColor = 'error';
            statusLabel = loc.status_rejected;
            break;
          case 'en_attente':
          default:
            statusColor = 'warning';
            statusLabel = loc.status_pending;
            break;
        }
        Color getChipColor(String statusColor) {
          switch (statusColor) {
            case 'success':
              return Colors.green;
            case 'error':
              return Colors.red;
            case 'warning':
            default:
              return Colors.orange;
          }
        }

        final isLong = sig.description.length > 20;
        final isExpanded = expandedIds.contains(sig.id);
        final text = isExpanded || !isLong
            ? sig.description
            : '${sig.description.substring(0, 20)}...';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),

            // 📷 Photo
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: sig.imageUrl != null && sig.imageUrl!.isNotEmpty
                  ? Image.network(
                      sig.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),

            // 📝 Description
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (isLong)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          expandedIds.remove(sig.id);
                        } else {
                          expandedIds.add(sig.id);
                        }
                      });
                    },
                    child: Text(
                      isExpanded
                          ? AppLocalizations.of(context)!.show_less
                          : AppLocalizations.of(context)!.show_more,
                      style: const TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                  ),
              ],
            ),

            // 🏷️ Statut
            subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Chip(
                  label: Text(statusLabel),
                  backgroundColor: getChipColor(statusColor),
                )),

            // 📍 Carte
            trailing: IconButton(
              icon: const Icon(Icons.map, color: Colors.blue),
              onPressed: () {
                if (sig.localisation.isNotEmpty) {
                  final query = Uri.encodeComponent(sig.localisation);
                  final url =
                      "https://www.google.com/maps/search/?api=1&query=$query";
                  _launchURL(url);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(
    IconData icon,
    String label,
    Color color,
    bool selected,
    VoidCallback onTap, {
    int? badgeCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: selected
                    ? Colors.green.withOpacity(0.15)
                    : color.withOpacity(0.15),
                child: Icon(icon,
                    color: selected ? Colors.green : color, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.green : Colors.black),
              ),
            ],
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        //title: const Text("Fournisseur de données"),
        title: Text(AppLocalizations.of(context)!.supplier_title),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 192, 134, 27),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchSignalements,
          )
        ],
      ),
      body: Column(
        children: [
          // Bandeau image + bouton signaler
          Container(
            width: double.infinity,
            height: 180,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fourni.jpg'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Container(
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.4),
              child: Text(
                AppLocalizations.of(context)!.welcome,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AjouterSignalementPage()),
                ).then((_) => fetchSignalements());
              },
              icon: const Icon(Icons.add_circle_outline),
              //label: const Text('Signaler un problème'),
              label: Text(AppLocalizations.of(context)!.report_problem),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 218, 136, 70),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedIndex == 0
                    ? _buildSignalements()
                    : _buildNotifications(),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) async {
          if (wasInNotificationTab && index != 1) {
            await markNotificationsAsRead();

            // Recharge les signalements pour supprimer les notifs non lues
            await fetchSignalements();

            setState(() {
              newNotificationsCount = 0;
              wasInNotificationTab = false;
            });
          }

          if (index == 1) {
            setState(() {
              wasInNotificationTab = true;
              selectedIndex = 1;
            });
            return;
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilPage()),
            );
            // ❗ Ne pas changer selectedIndex, on garde le bouton précédent actif
            return;
          }

          // Pour l'onglet Signalement (index 0)
          setState(() {
            selectedIndex = index;
          });
        },
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.visibility_outlined),
            label: AppLocalizations.of(context)!.signalement,
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_active_outlined),
                if (newNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$newNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: AppLocalizations.of(context)!.notifications,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }
}
