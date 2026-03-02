import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

import '../model/place_result.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  Location _location = Location();
  TextEditingController _locationController = TextEditingController();
  bool isLoading = true;
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> route = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initialLocation();
    pinMultiplePlaces(['Rampura, Dhaka', 'Mohakhali, Dhaka', 'Kurmitola, Dhaka','Khelket']);
  }

  // initialze Location
  Future<void> _initialLocation() async {
    if (!await _checkLocationPermission()) return;
    _location.onLocationChanged.listen((LocationData locationData) {
      setState(() {
        _currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        isLoading = false;
      });
    });
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  Future<void> _userCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current Location Not Available')),
      );
    }
  }

  //// Search Location
  Future<void> fetchCoordinatePoints(String location) async {
    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': location,
      'format': 'json',
      'limit': '1',
      'email': 'sharifahmed1413@gmail.com',
    });

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'OpenStreetMapFlutterApp/1.0 (sharifahmed1413@gmail.com)',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found')),
        );
        return;
      }

      final lat = double.parse(data[0]['lat']);
      final lon = double.parse(data[0]['lon']);

      setState(() {
        _destination = LatLng(lat, lon);
        route.clear();
      });

      await fetchRoute();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: ${response.statusCode}')),
      );
      debugPrint('Nominatim error: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> fetchRoute() async {
    if (_currentLocation == null || _destination == null) return;
    final url = Uri.parse(
      "https://router.project-osrm.org/route/v1/driving/"
          "${_currentLocation!.longitude},${_currentLocation!.latitude};"
          "${_destination!.longitude},${_destination!.latitude}"
          "?overview=full&geometries=polyline",
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final geometry = data['routes'][0]['geometry'];
      _decodePolyLine(geometry);
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route Not Found'))
      );
    }
  }
void _decodePolyLine(String encodePolyline){
    final decodePoints = PolylinePoints.decodePolyline(encodePolyline);
    setState(() {
      route = decodePoints.map((point)=> LatLng(point.latitude, point.longitude)).toList();
    });
}
 /* final places = <LatLng>[
    LatLng(23.8103, 90.4125), // Dhaka
    LatLng(23.9999, 90.4203), // Gazipur (approx)
    LatLng(24.7471, 90.4203), // Mymensingh
  ];*/
  ////// address write
  List<LatLng> destinations = [];

  Future<void> pinMultiplePlaces(List<String> places) async {
    destinations.clear();

    for (final place in places) {
      final url = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': place,
        'format': 'json',
        'limit': '1',
        'email': 'sharifahmed1413@gmail.com',
      });

      final res = await http.get(url, headers: {
        'User-Agent': 'OpenStreetMapFlutterApp/1.0 (sharifahmed1413@gmail.com)',
        'Accept': 'application/json',
      });

      debugPrint('Place="$place" status=${res.statusCode}');

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        debugPrint('Result count=${data.length}');
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          destinations.add(LatLng(lat, lon));
        }
      } else {
        debugPrint(res.body);
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    debugPrint('Destinations total=${destinations.length}');
    setState(() {});
  }
///// Search Result Show
  List<PlaceResult> _suggestions = [];
  bool _isSearching = false;
  Future<List<PlaceResult>> searchTop5(String query) async {
    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '5',
      'addressdetails': '1',
      'email': 'sharifahmed1413@gmail.com',
    });

    final res = await http.get(url, headers: {
      'User-Agent': 'OpenStreetMapFlutterApp/1.0 (sharifahmed1413@gmail.com)',
      'Accept': 'application/json',
    });

    if (res.statusCode != 200) return [];

    final List data = jsonDecode(res.body);
    return data.map((e) => PlaceResult.fromJson(e)).toList();
  }

  Future<void> updateSuggestions(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await searchTop5(q.trim());
    if (!mounted) return;

    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenStreetMap', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.cyan,
      ),
      body: Stack(
        children: [
          isLoading ? Center(child: CircularProgressIndicator(),):
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? LatLng(23.777176, 90.399452),
              initialZoom: 13.0,
              maxZoom: 100,
              minZoom: 0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.android.application',
              ),
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: Colors.blue,
                    child: Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  markerSize: Size(30, 30),
                  markerDirection: MarkerDirection.heading,
                ),
              ),
              if (destinations.isNotEmpty)
                MarkerLayer(
                  markers: destinations.map((p) => Marker(
                    point: p,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.pin_drop, size: 40, color: Colors.red),
                  )).toList(),
                ),
              /*MarkerLayer(
                markers: places.map((p) {
                  return Marker(
                    point: p,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_pin, size: 45, color: Colors.red),
                  );
                }).toList(),
              ),*/
             if(_destination != null)
               MarkerLayer(markers: [
                 Marker(
                     point: _destination!,
                     height: 50,
                     width: 50,
                     child: Icon(Icons.pin_drop,size: 40,color: Colors.red,)
                 )
               ]),
              if(_currentLocation != null && _destination != null && route.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(points: route,strokeWidth: 5,color: Colors.red)
                ])
            ],
          ),
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withAlpha(150),
                              hintText: 'Search...',
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey
                                )
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey
                                )
                              ),
                            ),
                            onChanged: (v){
                              updateSuggestions(v);
                            },
                          ),
                        ),
                        IconButton(
                          color: Colors.white,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(Colors.blue),
                          ),
                          onPressed: () {
                            final location = _locationController.text.trim();
                            if(location.isNotEmpty){
                              fetchCoordinatePoints(location);
                            }
                          },
                          icon: Icon(Icons.search),
                        ),
                      ],
                    ),
                    if (_suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(240),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final item = _suggestions[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place, size: 20),
                              title: Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                setState(() {
                                  _destination = item.point;
                                  _suggestions = []; // hide list
                                  route.clear();
                                });

                                _locationController.text = item.name; // optional
                                _mapController.move(item.point, 15);
                                await fetchRoute();
                              },
                            );
                          },
                        ),
                      )
                  ],
                ),
              )
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _userCurrentLocation,
        child: Icon(Icons.location_on_outlined, color: Colors.white, size: 30),
      ),
    );
  }
}
