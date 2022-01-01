import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ErkundenPage extends StatefulWidget{
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage>{
  Widget build(BuildContext context){


    Widget ownFlutterMap(){
      return FlutterMap(
        options: MapOptions(
          center: LatLng(51.5, -0.09),
          zoom: 13.0,
        ),
        layers: [

          TileLayerOptions(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c']
          ),
          MarkerLayerOptions(
            markers: [
              //hier Landen alle Personen und Events
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(51.5, -0.09),
                builder: (ctx) => const FloatingActionButton(
                    mini: true,
                    child: Text("2"),
                    onPressed: null,
                  ),
                ),
            ],
          ),
        ],
      );
    }

    Widget mapTextField(){
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Card(
            child: TextField(
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: "Interessen suche",
              ),
            ),
        ),
      );
    }


    return Scaffold(
        body: Stack(children: [
          ownFlutterMap(),
          mapTextField()
        ])
    );
  }
}