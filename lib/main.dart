import 'package:flutter/material.dart';
import 'package:google_map_places/modelAdress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'WidgetGoogleMap.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Set<Marker> mapMarkers = Set();

  Marker newMarker;

  List<ModelAddress> listSelectedMarkerAddress = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WidgetGoogleMap(),
    );
  }
}
