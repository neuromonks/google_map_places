import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_map_places/HelperFucations.dart';
import 'package:google_map_places/modelAdress.dart';
import 'package:google_map_places/secrate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class WidgetGoogleMap extends StatefulWidget {
  @override
  _WidgetGoogleMapState createState() => _WidgetGoogleMapState();
}

class _WidgetGoogleMapState extends State<WidgetGoogleMap> {
  bool isMapTypeNormal = false, isPolygonCreated = false, fullScreen = false;

  Set<Marker> markers = new HashSet<Marker>();
  Set<Polyline> polylines = new HashSet<Polyline>();
  Set<Polygon> polygons = new HashSet<Polygon>();
  Marker newMarker;
  List<LatLng> polygonLatLongs = [];
  List<LatLng> polylineLatLongs = [];
  double mapZoomValue = 16.5;

  Completer<GoogleMapController> _controller = Completer();

  CameraPosition _kGooglePlex;

  LatLng _lastMapPosition;

  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  final searchScaffoldKey = GlobalKey<ScaffoldState>();
  ModelAddress currentAddress = new ModelAddress();
  List<dynamic> _placeList = [];
  String _sessionToken;
  @override
  void didUpdateWidget(covariant WidgetGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  var _controllerSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controllerSearch.addListener(() {
      _onChanged();
    });

    checkIsGpsOn();
  }

  _onChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = Uuid().v1();
      });
    }
    getSuggestion(_controllerSearch.text);
  }

  void getSuggestion(String input) async {
    String baseURL =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request =
        '$baseURL?input=$input&key=${Screate.googleMapKey}&sessiontoken=$_sessionToken&location=${_lastMapPosition.latitude},${_lastMapPosition.longitude}&radius=1500';
    print(request);
    await http.get(request).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          _placeList = json.decode(response.body)['predictions'];
          print(_placeList);
          if (_placeList.isNotEmpty) {
            _placeList.forEach((element) {
              getLatLongFromPlaceId(element['place_id']);
            });
          } else {
            print('empty');
          }
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    });
  }

  dynamic getLatLongFromPlaceId(String placeId) async {
    String request =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${Screate.googleMapKey}';
    await http.get(request).then((response) {
      if (response.statusCode == 200) {
        print('adf');
        var responsedata = json.decode(response.body);
        var placeDetails = responsedata['result'];
        newMarker = Marker(
          markerId: MarkerId(
              "marker_${placeDetails['geometry']['location']['lat']}_${placeDetails['geometry']['location']['lng']}"),
          position: LatLng(placeDetails['geometry']['location']['lat'],
              placeDetails['geometry']['location']['lng']),
        );
        setState(() {
          markers.add(newMarker);
        });
      }
    });
  }

  checkIsGpsOn() async {
    bool isGpsOn = await HelpterFuncation.isGps();
    if (isGpsOn) {
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .then((value) {
        setState(() {
          _kGooglePlex = CameraPosition(
              target: LatLng(value.latitude, value.longitude),
              zoom: mapZoomValue);

          _lastMapPosition = LatLng(value.latitude, value.longitude);
        });
      });
    } else {
      HelpterFuncation.gpsAlert(context).then((val) {
        Future.delayed(const Duration(seconds: 3), () {
          checkIsGpsOn();
        });
      });
    }
  }

  Future<void> moveToNewPoition(lat, lon) async {
    CameraPosition newPosition = CameraPosition(
      target: LatLng(lat, lon),
      zoom: mapZoomValue,
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(newPosition));
    _onCameraMove(newPosition);
  }

  _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
    setState(() {
      mapZoomValue = position.zoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: homeScaffoldKey,
      body: _kGooglePlex != null
          ? Column(
              children: [
                TextField(
                  controller: _controllerSearch,
                  decoration: InputDecoration(
                    hintText: "Seek your location here",
                    focusColor: Colors.white,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    prefixIcon: Icon(Icons.map),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel),
                      onPressed: () {},
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      GoogleMap(
                        mapType: isMapTypeNormal
                            ? MapType.normal
                            : MapType.satellite,
                        initialCameraPosition: _kGooglePlex,
                        mapToolbarEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        markers: markers,
                        polygons: polygons,
                        polylines: polylines,
                        onMapCreated: (GoogleMapController controller) {
                          //_onMapCreated(controller);
                          controller.setMapStyle(Screate.mapJson);

                          _controller.complete(controller);
                        },
                        onCameraMove: (position) async {
                          // if (widget.onCameraMove != null) {
                          //   setState(() {
                          //     _lastMapPosition = LatLng(
                          //         position.target.latitude,
                          //         position.target.longitude);
                          //   });
                          //   widget.onCameraMove(position);
                          // } else {
                          //   return null;
                          // }
                        },
                        onCameraIdle: () => {
                          // widget.onCameraIdle != null
                          //     ? widget.onCameraIdle()
                          //     : null,
                          if (_lastMapPosition != null) _getLocation()
                        },
                        onTap: (position) {
                          // if (widget.createPloygon != null) {
                          //   if (!isPolygonCreated) {
                          //     moveToNewPoition(value.latitude, value.longitude);
                          //     generatePolyLines(position);
                          //   }
                          // } else {
                          //   _lastMapPosition =
                          //       LatLng(position.latitude, position.longitude);
                          //   widget.onTap(position, currentAddress);

                          //   _getLocation();
                          // }
                        },
                      ),
                      Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            margin: EdgeInsets.only(left: 12),
                            child: Column(
                              children: [
                                actionButtion(
                                    Icon(Icons.map_rounded,
                                        color: Colors.grey[700]), () {
                                  setState(() {
                                    isMapTypeNormal = !isMapTypeNormal;
                                  });
                                }),
                                // if (widget.searchedAddress != null)
                                actionButtion(
                                    Icon(Icons.search, color: Colors.grey[700]),
                                    () => _handlePressButton()),
                              ],
                            ),
                          )),
                      Container(
                        margin: EdgeInsets.only(left: 20),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: FlatButton(
                            textColor: Colors.white,
                            color: Colors.grey[400],
                            child: Text(
                              'Show Places',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              openBottomSheet();
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image.asset(
                //   "assets/images/loadingLocation.png",
                //   scale: 1.5,
                // ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 16),
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                Text('Loading Map.')
              ],
            )),
    );
  }

  openBottomSheet() {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return ListView.builder(
              shrinkWrap: true,
              itemCount: _placeList.length,
              itemBuilder: (context, index) {
                var addressDetails = _placeList[index];
                return Text('${addressDetails.description}');
              });
        });
  }

  Widget actionButtion(Icon icon, Function ontap) {
    return Container(
        height: 38,
        width: 38,
        margin: EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: Colors.white70,
        ),
        child: IconButton(icon: icon, onPressed: () => ontap()));
  }

  _getLocation() async {
    var addresses = await Geocoder.local.findAddressesFromCoordinates(
        Coordinates(_lastMapPosition.latitude, _lastMapPosition.longitude));
    var first = addresses.first;
    setState(() {
      currentAddress = ModelAddress(
          description: first?.addressLine ?? "NA",
          pincode: first?.postalCode ?? "NA",
          district: first?.subAdminArea ?? "NA",
          latitude: _lastMapPosition.latitude,
          longitude: _lastMapPosition.longitude);
    });
  }

  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  Future<void> _handlePressButton() async {
    Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: Screate.googleMapKey,
      onError: onError,
      mode: Mode.overlay,
      language: "En",
      components: [Component(Component.country, "In")],
    );
    displayPrediction(p, homeScaffoldKey.currentState, _controller)
        .then((value) async {
      final lat = value.result.geometry.location.lat;
      final lng = value.result.geometry.location.lng;
      GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          bearing: 192.8334901395799,
          target: LatLng(lat, lng),
          zoom: mapZoomValue)));

      _lastMapPosition = LatLng(lat, lng);

      moveToNewPoition(lat, lng);
    });
  }

  // ignore: missing_return
  Future<PlacesDetailsResponse> displayPrediction(
      Prediction p,
      ScaffoldState scaffold,
      Completer<GoogleMapController> _controller) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await GoogleMapsPlaces(apiKey: Screate.googleMapKey)
              .getDetailsByPlaceId(p.placeId);
      return detail;
    }
  }
}
