import 'dart:math';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:capstonedesign/tmap_api.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as LAC;
import 'package:geolocator/geolocator.dart';

class MapStateTest extends StatefulWidget{
  @override
  _MapStateTest createState() => _MapStateTest();

}

class _MapStateTest extends State<MapStateTest>{
  late GoogleMapController mapController;

  
  FeatureCollection? data;
  
  void first() async {
    var _data = await getJsonData();
    setState(() {
      data = _data;
    });
    
  }

  final LatLng _center = const LatLng(37.56520450, 126.98702028);

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
  }

  final List<Marker> markers = [];

  _addMarker(cordinate) {
    int id = Random().nextInt(100);

    setState(() {
      markers.add(Marker(position: cordinate, markerId: MarkerId(id.toString())));
    });
  }

var loc = {
    "startX" : "126.983937",
		"startY" : "37.564991",
		"endX" : "126.988940",
		"endY" : "37.566158",
		"reqCoordType" : "WGS84GEO",
		"resCoordType" : "WGS84GEO",
		"startName" : "출발지",
		"endName" : "도착지"
  };

  Future<FeatureCollection> getJsonData() async{
    var url = 'https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&format=json';
    
    var response = await http.post(Uri.parse(url),
    headers: {"appKey":"yoGbsPZDXKaj8PRRQSIuX8AAd1SHGLIp9zw5oVOe"},
    body: loc);

    var decode = json.decode(response.body);
    var featureCollection = FeatureCollection.fromJson(decode);

    return featureCollection;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Maps Sample App'),
          backgroundColor: Colors.green[700],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height*0.7,
              width: MediaQuery.of(context).size.width,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 11.0
                ),
                markers: markers.toSet(),
                onTap: (cordinate) {
                  mapController.animateCamera(CameraUpdate.newLatLng(cordinate));
                  _addMarker(cordinate);
                },
              ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FloatingActionButton(
              onPressed: () async {
                var gps = await getCurrentLocation();

                mapController.animateCamera(
                    CameraUpdate.newLatLng(LatLng(gps.latitude, gps.longitude)));

              },
              backgroundColor: Colors.white,
              child: Icon(
                Icons.my_location,
                color: Colors.black,
              ),
            ),
              TextButton(onPressed: first , child: Text("json"))],
              ),
          Text(data == null ? "test" : data!.features[0].geometry.type)],
        )

      )
    );
  }
}

Future<Position> getCurrentLocation() async {
  Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high));

  return position;
}

