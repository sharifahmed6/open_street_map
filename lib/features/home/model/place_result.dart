import 'package:latlong2/latlong.dart';

class PlaceResult {
  final String name;
  final LatLng point;

  PlaceResult({required this.name, required this.point});

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      name: json['display_name'] ?? '',
      point: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
    );
  }
}