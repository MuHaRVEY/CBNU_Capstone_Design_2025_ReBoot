import 'package:http/http.dart' as http;
import 'dart:convert';

class Geometry {
  final String type;
  final List<dynamic> coordinates;

  Geometry({
    required this.type,
    required this.coordinates
  });

  /* Geometry.fromJson(Map<String, dynamic> json)
  :type = json["type"],
  coordinates = json["coordinates"]; */

  factory Geometry.fromJson(Map<String, dynamic> json){
    return Geometry(type: json["type"], coordinates: json["coordinates"]);
  }
}

class Feature{
  final Geometry geometry;

  Feature({required this.geometry});

  /* Feature.fromJson(Map<String, dynamic> json)
  :geometry = json["goemetry"]; */

  factory Feature.fromJson(Map<String, dynamic> json){
    return Feature(geometry: Geometry.fromJson(json["geometry"]));
  }
}

class FeatureCollection {
  final List<Feature> features;

  FeatureCollection({required this.features});

  factory FeatureCollection.fromJson(Map<String, dynamic> json){
    var list =json["features"] as List;
    List<Feature>featureList = list.map((e) => Feature.fromJson(e)).toList();

    return FeatureCollection(features: featureList);
  }
}

class TmapApi {
  TmapApi();

  var data = {
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
    body: data);

    var decode = json.decode(response.body);
    var featureCollection = FeatureCollection.fromJson(decode);

    return featureCollection;
  }
}

