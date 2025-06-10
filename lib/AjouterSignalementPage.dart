import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'MapPickerPage.dart';
//import 'package:image/image.dart' as img;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AjouterSignalementPage extends StatefulWidget {
  const AjouterSignalementPage({super.key});

  @override
  State<AjouterSignalementPage> createState() => _AjouterSignalementPageState();
}

class _AjouterSignalementPageState extends State<AjouterSignalementPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedCategoryId;
  String description = '';
  LatLng? localisation;
  File? _imageFile;
  List<Map<String, dynamic>> categories = [];
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:8000/api/categories/'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          categories = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print("❌ Erreur serveur catégories");
      }
    } catch (e) {
      print("🚨 Erreur de chargement des catégories : $e");
    }
  }

  Future<String?> uploadToDjango(File imageFile) async {
    if (await imageFile.length() == 0) {
      print("⚠️ Le fichier est vide, abandon de l'upload");
      return null;
    }

    final uri = Uri.parse('http://127.0.0.1:8000/api/upload/');
    final request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final data = jsonDecode(body);
        return data['url'];
      } else {
        print('❌ Erreur lors de l\'upload : ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('🚨 Exception upload image : $e');
      return null;
    }
  }

  Future<File?> _pickAndCopyImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return null;

    final ext = path.extension(picked.path).toLowerCase();

    // 🚫 Refuser les .heic ou .heif car non supportés
    if (ext == '.heic' || ext == '.heif') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "⚠️ Format .heic non supporté. Veuillez utiliser JPG ou PNG.")),
      );
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final filename = path.basename(picked.path);
    final copied = await File(picked.path).copy('${tempDir.path}/$filename');

    return copied;
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.galerie),
              onTap: () async {
                Navigator.pop(context);
                final image = await _pickAndCopyImage(ImageSource.gallery);
                if (image != null) {
                  setState(() => _imageFile = image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.prendre),
              onTap: () async {
                Navigator.pop(context);
                final image = await _pickAndCopyImage(ImageSource.camera);
                if (image != null) {
                  setState(() => _imageFile = image);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (localisation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.select_location))
      );
      return;
    }

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await uploadToDjango(_imageFile!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.unsupported_format)),
        );
        return;
      }
    }

    final data = {
      'description': description,
      'localisation': {
        'latitude': localisation!.latitude,
        'longitude': localisation!.longitude,
      },
      'image_base64': imageUrl ?? '',
      'status': 'en_attente',
      'category': selectedCategoryId,
      'user_id': uid,
    };

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/signalements/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.success_report)),
        );
        Navigator.pop(context);
      } else {
        print("❌ Échec de l'envoi : ${response.body}");
      }
    } catch (e) {
      print("🚨 Erreur de soumission : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.add_report),
        backgroundColor: const Color.fromARGB(255, 192, 140, 26),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                   Text(
                    AppLocalizations.of(context)!.report_form,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    items: categories.map<DropdownMenuItem<String>>((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'],
                        child: Text(cat['nom']),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedCategoryId = value),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.category,
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) => value == null
                        ? AppLocalizations.of(context)!.select_category
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      maxLines: 3,
                      onChanged: (val) => description = val,
                      validator: (val) => val == null || val.isEmpty
                          ? AppLocalizations.of(context)!.enter_description
                          : null,
                      ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_imageFile!,
                                  fit: BoxFit.cover, width: double.infinity),
                            )
                          :  Center(child: Text(AppLocalizations.of(context)!.add_image),),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: localisation != null
                          ? '${localisation!.latitude}, ${localisation!.longitude}'
                          : '',
                    ),
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapPickerPage(
                            onLocationPicked: (locStr) {
                              final parts = locStr.split(',');
                              setState(() {
                                localisation = LatLng(
                                  double.parse(parts[0].trim()),
                                  double.parse(parts[1].trim()),
                                );
                              });
                            },
                          ),
                        ),
                      );
                    },
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.location,
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send),
                    label: Text(AppLocalizations.of(context)!.submit_report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(161, 115, 15, 1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
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
