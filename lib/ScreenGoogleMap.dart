import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_map_places/helper/HelperFunctions.dart';
import 'package:google_map_places/models/modelAdress.dart';
import 'package:google_map_places/helper/Secrate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ScreenGoogleMap extends StatefulWidget {
  @override
  _ScreenGoogleMapState createState() => _ScreenGoogleMapState();
}

class _ScreenGoogleMapState extends State<ScreenGoogleMap> {
  bool isMapTypeNormal = false, isPolygonCreated = false, fullScreen = false;

  Set<Marker> markers = new HashSet<Marker>();
  Marker newMarker;
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
  void didUpdateWidget(covariant ScreenGoogleMap oldWidget) {
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
        '$baseURL?input=$input&key=${Secrate.googleMapKey}&location=${_lastMapPosition.latitude},${_lastMapPosition.longitude}&radius=1500';
    print(request);
    await http.get(request).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          _placeList = json.decode(response.body)['predictions'];
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
      // getLatLongFromPlaceId('');
    });
  }

  dynamic getLatLongFromPlaceId(String placeId) async {
    // newMarker = Marker(
    //   markerId: MarkerId("marker_20.0070399_73.7598144"),
    //   position: LatLng(20.0070399, 73.7598144),
    // );
    // setState(() {
    //   markers.add(newMarker);
    // });
    String request =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${Secrate.googleMapKey}';
    await http.get(request).then((response) {
      if (response.statusCode == 200) {
        var responsedata = json.decode(response.body);
        var placeDetails = responsedata['result'];
        print(placeDetails);
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
    bool isGpsOn = await HelperFunction.isGps();
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
      HelperFunction.gpsAlert(context).then((val) {
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
          ? SafeArea(
              child: Column(
                children: [
                  TextField(
                    controller: _controllerSearch,
                    decoration: InputDecoration(
                      hintText: "Enter Place",
                      labelText: 'Search Place',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          _controllerSearch.clear();
                        },
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
                          onMapCreated: (GoogleMapController controller) {
                            //_onMapCreated(controller);
                            controller.setMapStyle(Secrate.mapJson);

                            _controller.complete(controller);
                          },
                          onCameraMove: (position) async {},
                          onCameraIdle: () =>
                              {if (_lastMapPosition != null) _getLocation()},
                          onTap: (position) {},
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
                                      Icon(Icons.search,
                                          color: Colors.grey[700]),
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
              ),
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
              padding: EdgeInsets.symmetric(horizontal: 15),
              itemCount: _placeList.length,
              itemBuilder: (context, index) {
                var addressDetails = _placeList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text('${addressDetails.description}'),
                );
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
      apiKey: Secrate.googleMapKey,
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
          await GoogleMapsPlaces(apiKey: Secrate.googleMapKey)
              .getDetailsByPlaceId(p.placeId);
      return detail;
    }
  }
}
