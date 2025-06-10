import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
//import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'models/signalement.dart';

class VisiteurHomePage extends StatefulWidget {
  const VisiteurHomePage({super.key});

  @override
  State<VisiteurHomePage> createState() => _VisiteurHomePageState();
}

class _VisiteurHomePageState extends State<VisiteurHomePage> {
  List<Signalement> signalements = [];
  List<String> categories = [];
  String selectedCategory = 'Toutes';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchSignalements();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/categories/'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final loadedCategories = data
            .map<String>((cat) => (cat['nom'] as String).trim())
            .toSet()
            .toList();
        final allLabel = AppLocalizations.of(context)!.all;
        setState(() {
          categories = [allLabel, ...loadedCategories];
          selectedCategory = allLabel;
        });
      } else {
        debugPrint(
            "Erreur de chargement des catégories : ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur lors du fetch des catégories : $e");
    }
  }

  Future<void> fetchSignalements() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/visiteur/'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final filtered = data.where((e) => e['status'] == 'valide').toList();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'signalements_visiteur_cache', jsonEncode(filtered));

        setState(() {
          signalements = filtered.map((e) => Signalement.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur réseau ou serveur : $e");
      await loadFromCache();
    }
  }

  Future<void> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('signalements_visiteur_cache');

    if (cachedData != null) {
      final List<dynamic> data = jsonDecode(cachedData);
      setState(() {
        signalements = data.map((e) => Signalement.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      debugPrint("Aucun cache disponible");
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d’ouvrir le lien : $url');
    }
  }

  List<Signalement> get filteredSignalements {
    final filtered = selectedCategory.toLowerCase() ==
            AppLocalizations.of(context)!.all.toLowerCase()
        ? signalements
        : signalements.where((s) {
            final cat = s.categorie.trim().toLowerCase();
            return cat == selectedCategory.toLowerCase();
          }).toList();

    // Trier par date décroissante
    filtered.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1; // b passe avant
      if (b.createdAt == null) return -1; // a passe avant
      return b.createdAt!.compareTo(a.createdAt!); // plus récent d’abord
    });

    return filtered;
  }

  Set<String> expandedIds = {};

  Widget _buildSignalementCard(Signalement sig) {
    final loc = AppLocalizations.of(context)!;

    final String dateStr;
    if (sig.createdAt != null) {
      // Formate la date en respectant la locale (fr, en, ar)
      final dateLocal =
          MaterialLocalizations.of(context).formatShortDate(sig.createdAt!);
      final hour = sig.createdAt!.hour.toString().padLeft(2, '0');
      final minute = sig.createdAt!.minute.toString().padLeft(2, '0');
      dateStr = '$dateLocal - $hour:$minute';
    } else {
      dateStr = loc.unknown; // exemple dans arb : "unknown": "Inconnue",
    }

    bool isExpanded = expandedIds.contains(sig.id);
    final isLong = sig.description.length > 20;
    final displayText = isExpanded || !isLong
        ? sig.description
        : '${sig.description.substring(0, 20)}...';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: sig.imageUrl != null && sig.imageUrl!.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ImageFullScreenPage(imageUrl: sig.imageUrl!),
                      ),
                    );
                  },
                  child: Image.network(
                    sig.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  ),
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  isExpanded ? loc.see_less : loc.see_more,
                  style: const TextStyle(color: Colors.blue, fontSize: 13),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text("${loc.date} : $dateStr"),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.map, color: Colors.blue),
          onPressed: () {
            final query = Uri.encodeComponent(sig.localisation);
            final url =
                "https://www.google.com/maps/search/?api=1&query=$query";
            _launchURL(url);
          },
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.visitor_home_title),
        backgroundColor: const Color.fromARGB(255, 192, 134, 27),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await fetchCategories();
              await fetchSignalements();
            },
          )
        ],
      ),
      body: isLoading
          ? ListView.builder(
              itemCount: 5,
              itemBuilder: (_, __) => _buildShimmerCard(),
            )
          : Column(
              children: [
                const SizedBox(height: 18),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: loc.filter_by_category,
                      border: const OutlineInputBorder(),
                    ),
                    value: selectedCategory,
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: filteredSignalements.isEmpty
                      ? Center(child: Text(loc.no_signalement))
                      : ListView.builder(
                          itemCount: filteredSignalements.length,
                          itemBuilder: (context, index) =>
                              _buildSignalementCard(
                                  filteredSignalements[index]),
                        ),
                ),
              ],
            ),
    );
  }
}

class ImageFullScreenPage extends StatelessWidget {
  final String imageUrl;

  const ImageFullScreenPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 50),
          ),
        ),
      ),
    );
  }
}
