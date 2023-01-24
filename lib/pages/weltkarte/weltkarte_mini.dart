import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../widgets/custom_appbar.dart';

class WorldmapMini extends StatelessWidget {
  double minMapZoom = kIsWeb ? 2.0 : 1.6;
  double maxMapZoom = 14;
  Map location;

  WorldmapMini({Key key, this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Standort anzeigen"),
      body: FlutterMap(
      options: MapOptions(
        center: LatLng(location["latt"], location["longt"]),
        zoom: 6,
        minZoom: minMapZoom,
        maxZoom: maxMapZoom,
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
                width: 30.0,
                height: 30.0,
                point: LatLng(
                    location["latt"], location["longt"]),
                builder: (_) => Icon(
                  Icons.flag,
                  color: Colors.green[900],
                  size: 30,
                ))
          ],
        )
      ],
    )
    );
  }
}
