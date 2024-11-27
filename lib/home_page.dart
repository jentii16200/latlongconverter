// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:latlong2/latlong.dart' as latLng;
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController latController = TextEditingController();
  final TextEditingController longController = TextEditingController();
  String? convertedCoords;
  late MapController mapController;

  final List<Marker> markers = [];
  final PopupController popupController = PopupController();

  latLng.LatLng currentLatLng = const latLng.LatLng(14.5535, 121.0452); // Default to West Rembo, Makati City

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  void convertCoords() {
    try {
      double lat = double.parse(latController.text);
      double lng = double.parse(longController.text);

      String latDMS = convertToDMS(lat);
      String lngDMS = convertToDMS(lng);

      setState(() {
        convertedCoords = "Latitude: $latDMS\nLongitude: $lngDMS";
        currentLatLng = latLng.LatLng(lat, lng);
        markers.clear();
        markers.add(
          Marker(
            point: currentLatLng,
            child: const Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 40,
            ),
          ),
        );
        mapController.move(currentLatLng, 14.0);
      });
    } catch (e) {
      setState(() {
        convertedCoords = "Invalid input";
      });
    }
  }

  String convertToDMS(double decimal) {
    int degrees = decimal.truncate();
    double minutesDecimal = (decimal - degrees).abs() * 60;
    int minutes = minutesDecimal.truncate();
    double seconds = (minutesDecimal - minutes).abs() * 60;

    return "$degrees° $minutes' ${seconds.toStringAsFixed(2)}\"";
  }

  void saveToDatabase() async {
    try {
      double lat = double.parse(latController.text);
      double lng = double.parse(longController.text);

      var url = Uri.parse("http://your-backend-server/save-coords");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "lat": lat,
          "lng": lng,
          "notes": "User inputted coordinates",
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Coordinates saved successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save coordinates.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid input.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lat-Long Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: 'Latitude (DD)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: longController,
              decoration: const InputDecoration(labelText: 'Longitude (DD)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: convertCoords,
              child: const Text("Convert Coords"),
            ),
            if (convertedCoords != null) ...[
              const SizedBox(height: 16),
              Text(
                convertedCoords!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: saveToDatabase,
              child: const Text("Save to DB"),
            ),
            Expanded(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: currentLatLng,
                  initialZoom: 14.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      currentLatLng = point;
                      markers.clear();
                      markers.add(
                        Marker(
                          point: point,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    });
                  },
                ),
                children: [
                  TileLayer(
                    // Display map tiles from any source
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
                    userAgentPackageName: 'com.example.app',
                    // And many more recommended properties!
                  ),
                  RichAttributionWidget(
                    // Include a stylish prebuilt attribution widget that meets all requirments
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')), // (external)
                      ),
                      // Also add images...
                    ],
                  ),
                  MarkerLayer(
                    markers: markers,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
