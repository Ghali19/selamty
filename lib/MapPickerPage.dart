import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class MapPickerPage extends StatefulWidget {
  final Function(String) onLocationPicked;

  const MapPickerPage({super.key, required this.onLocationPicked});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? selectedLocation;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.location_disabled)),

      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    if (!mounted) return;

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      selectedLocation = currentLocation;
      _mapController.move(currentLocation!, 15.0);
    });
  }

  Future<void> searchLocation(String query) async {
    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1';

    final response = await http.get(Uri.parse(url),
        headers: {'User-Agent': 'flutter_map_example_app'});

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        final newLocation = LatLng(lat, lon);

        if (!mounted) return;

        setState(() {
          selectedLocation = newLocation;
        });

        _mapController.move(newLocation, 15.0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.location_not_found)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.choose_location),
        backgroundColor: const Color.fromARGB(255, 192, 140, 26),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(18.086, -15.942), // remplace par ta valeur
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.selamty',
              ),
              if (selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: selectedLocation!,
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              child: TextField(
                controller: _searchController,
                onSubmitted: searchLocation,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.search_hint,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      searchLocation(_searchController.text);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),
          if (selectedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  final locStr =
                      "${selectedLocation!.latitude}, ${selectedLocation!.longitude}";
                  widget.onLocationPicked(locStr);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: Text(AppLocalizations.of(context)!.confirm_position),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(161, 115, 15, 1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
