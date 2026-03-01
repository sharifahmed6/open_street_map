import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
Location _location = Location();
TextEditingController _locationController = TextEditingController();
bool isLoading = false;
  LatLng? _currentLocation;
  LatLng? _destination;
List<LatLng> route = [];
  Future<void> _userCurrentLocation()async{
    if(_currentLocation != null){
      _mapController.move(_currentLocation!, 15);
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current Location Not Available'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenStreetMap',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.cyan,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? LatLng(0, 0),
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
                    child: Icon(Icons.my_location,color: Colors.white,size: 16),
                  ),
                  markerSize: Size(30, 30),
                  markerDirection: MarkerDirection.heading
                ),
              )
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _userCurrentLocation,
        child: Icon(Icons.location_on_outlined,color: Colors.white,size: 30,),
      ),
    );
  }
}
