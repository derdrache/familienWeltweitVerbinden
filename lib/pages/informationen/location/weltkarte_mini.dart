import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class WorldmapMini extends StatelessWidget {
  final double minMapZoom = kIsWeb ? 2.0 : 1.6;
  final double maxMapZoom = 14;
  final Map location;

  WorldmapMini({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(location["latt"], location["longt"]),
        initialZoom: 6,
        minZoom: minMapZoom,
        maxZoom: maxMapZoom,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.familien_suche',
        ),
        MarkerLayer(
          markers: [
            Marker(
                width: 30.0,
                height: 30.0,
                point: LatLng(
                    location["latt"], location["longt"]),
                child: Icon(
                  Icons.flag,
                  color: Colors.green[900],
                  size: 30,
                )
            )
          ],
        )
      ],
    )
    );
  }
}
