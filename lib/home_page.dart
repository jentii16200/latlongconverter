// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:latlong2/latlong.dart' as latLng;
// import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController latController = TextEditingController();
  final TextEditingController longController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String? convertedCoords;
  late MapController mapController;

  final List<Marker> markers = [];
  final PopupController popupController = PopupController();
  // ? Default to West Rembo, Makati City
  latLng.LatLng currentLatLng = const latLng.LatLng(14.5535, 121.0452);

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
    log("running");
    try {
      double lat = double.parse(latController.text);
      double lng = double.parse(longController.text);

      var url = Uri.parse("http://192.168.1.2:3000/save-coords");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "lat": lat,
          "lng": lng,
          "notes": notesController.text,
        }),
      );
      log(response.statusCode.toString());
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Coordinates saved successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save coordinates.")),
        );
      }
    } catch (e) {
      log(e.toString());
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
              decoration: const InputDecoration(labelText: 'Latitude (DDss)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: longController,
              decoration: const InputDecoration(labelText: 'Longitude (DD)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              keyboardType: TextInputType.text,
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
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.latlongconverter',
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => 'https://openstreetmap.org/copyright',
                      ),
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
