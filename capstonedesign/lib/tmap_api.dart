import 'package:http/http.dart' as http;
import 'dart:convert';

class TmapJson{
  final String type;
  final List<List<double>> coordinate;
  

  TmapJson({
    required this.type,
    required this.coordinate
  });

  TmapJson.fromJson(Map<String, dynamic> json)
  :type = json["features"],
  coordinate = json["coordinate"];
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

  Future<List<TmapJson>> getJsonData() async{
    var url = 'https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&format=json';
    var response = await http.post(Uri.parse(url),
    headers: {"appKey":"yoGbsPZDXKaj8PRRQSIuX8AAd1SHGLIp9zw5oVOe"},
    body: data);
    List<dynamic> _data = json.decode(response.body);
    List<TmapJson> result = _data.map((e) => TmapJson.fromJson(e)).toList();
    return result;
  }
}

