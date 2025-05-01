import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';

class MapStateTest extends StatefulWidget{
  @override
  _MapStateTest createState() => _MapStateTest();

}

class _MapStateTest extends State<MapStateTest>{
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(37.56520450, 126.98702028);

  void _onMapCreated(GoogleMapController controller) async {
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
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          initialCameraPosition: CameraPosition(
              target: _center,
          zoom: 20.0
          ),
        ),
      )
    );
  }
}

Future<Position> getCurrentLocation() async {
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

  return position;
}

FloatingActionButton(
onPressed: () async {
var gps = await getCurrentLocation();

_controller.animateCamera(
CameraUpdate.newLatLng(LatLng(gps.latitude, gps.longitude)));

},
child: Icon(
Icons.my_location,
color: Colors.black,
),
backgroundColor: Colors.white,
),