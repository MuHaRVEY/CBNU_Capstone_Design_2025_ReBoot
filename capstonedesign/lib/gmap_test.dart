import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class MapStateTest extends StatefulWidget{
  @override
  _MapStateTest createState() => _MapStateTest();

}

class _MapStateTest extends State<MapStateTest>{
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(37.56520450, 126.98702028);

  void _onMapCreated(GoogleMapController controller){
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Maps Sample App'),
          backgroundColor: Colors.green[700],
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
              target: _center,
          zoom: 11.0
          ),
        ),
      )
    );
  }

}
