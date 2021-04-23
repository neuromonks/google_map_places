import 'dart:typed_data';

import 'package:android_intent/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:math' as Math;

class HelpterFuncation {
  static getAddress(double latitude, double longitude) async {
    final coordinates = new Coordinates(latitude, longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    debugPrint('${addresses.length}');
    var first = addresses.first;
    print("${first.featureName} : ${first.addressLine}");

    return "${first.featureName} : ${first.addressLine}";
  }

  static gpsAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Can't get gurrent location"),
          content: const Text('Please make sure you enable GPS and try again'),
          actions: <Widget>[
            FlatButton(
              child: Text('Turn On'),
              onPressed: () {
                final AndroidIntent intent = AndroidIntent(
                    action: 'android.settings.LOCATION_SOURCE_SETTINGS');

                intent.launch();
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static isGps() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static void launchMapsUrl(double lat, double lon) async {
    final url = "http://maps.google.com/maps?q=loc:" +
        lat.toString() +
        "," +
        lon.toString() +
        " (" +
        "Location" +
        ")";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<void> makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static LatLng computeCentroid(List<LatLng> points) {
    double latitude = 0;
    double longitude = 0;
    int n = points.length;

    for (LatLng point in points) {
      latitude += point.latitude;
      longitude += point.longitude;
    }

    return new LatLng(latitude / n, longitude / n);
  }

  static Future<Uint8List> draaMarker(int width, int height, Color color,
      [String textMarker]) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final Paint paint2 = Paint()..color = Colors.white;

    final Radius radius = Radius.circular(100);
    canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()),
          topLeft: radius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        ),
        paint2);
    canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()),
          topLeft: radius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        ),
        paint);

    TextPainter painter = TextPainter(textDirection: ui.TextDirection.ltr);
    painter.text = TextSpan(
      text: textMarker != null ? textMarker : '',
      style: TextStyle(fontSize: 30, color: Colors.white),
    );
    painter.layout();
    painter.paint(
        canvas,
        Offset((width * 0.5) - painter.width * 0.5,
            (height * 0.5) - painter.height * 0.5));
    final img = await pictureRecorder.endRecording().toImage(width, height);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data.buffer.asUint8List();
  }

  static int value;
  // ignore: missing_return
  static Color getDynamicColor(double max, double valueToCompare, Color color) {
    List<double> list = [];
    value = 5;
    for (var i = 0; i < 5; i++) {
      if (i > 0) {
        list.add((max / value).roundToDouble());
      } else {
        list.add(0);
      }
      value--;
    }
    if (valueToCompare <= list[1]) {
      return color.withOpacity(0.2);
    }
    if (valueToCompare <= list[2]) {
      return color.withOpacity(0.4);
    }
    if (valueToCompare <= list[3]) {
      return color.withOpacity(0.6);
    }
    if (valueToCompare <= list[4]) {
      return color.withOpacity(0.8);
    }
    if (valueToCompare >= list[4]) {
      return color.withOpacity(1);
    }
  }

  // ignore: missing_return
  static Color getDynamicColorInt(int max, int valueToCompare, Color color) {
    List<double> list = [];
    value = 5;
    for (var i = 0; i < 5; i++) {
      if (i > 0) {
        list.add((max / value).roundToDouble());
      } else {
        list.add(0);
      }
      value--;
    }
    if (valueToCompare <= list[1]) {
      return color.withOpacity(0.2);
    }
    if (valueToCompare <= list[2]) {
      return color.withOpacity(0.4);
    }
    if (valueToCompare <= list[3]) {
      return color.withOpacity(0.6);
    }
    if (valueToCompare <= list[4]) {
      return color.withOpacity(0.8);
    }
    if (valueToCompare >= list[4]) {
      return color.withOpacity(1);
    }
  }

  static List<LatLng> getPlotPloygon(List<dynamic> areaCatered) {
    List<LatLng> listPoints = [];
    areaCatered.forEach((element) {
      listPoints.add(new LatLng(element[0], element[1]));
    });

    return listPoints;
  }

  static Future<Uint8List> markerText(
      int width, int height, Color color, double textSize,
      [String textMarker]) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    // final Paint paint = Paint()..color = color;

    // final Radius radius = Radius.elliptical(10, 10);

    // canvas.drawRRect(
    //     RRect.fromRectAndCorners(
    //       Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()),
    //       topLeft: radius,
    //       topRight: radius,
    //       bottomLeft: radius,
    //       bottomRight: radius,
    //     ),
    //     paint);

    TextPainter painter = TextPainter(textDirection: ui.TextDirection.ltr);
    painter.text = TextSpan(
      text: textMarker != null ? textMarker : '',
      style: TextStyle(fontSize: textSize, color: color),
    );
    painter.layout();
    painter.paint(
        canvas,
        Offset((width * 0.5) - painter.width * 0.5,
            (height * 0.5) - painter.height * 0.5));
    final img = await pictureRecorder.endRecording().toImage(width, height);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data.buffer.asUint8List();
  }

  static double calculatePolygonArea(List coordinates) {
    double area = 0;
    if (coordinates.length > 2) {
      for (var i = 0; i < coordinates.length - 1; i++) {
        var p1 = coordinates[i];
        var p2 = coordinates[i + 1];
        area += convertToRadian(p2.longitude - p1.longitude) *
            (2 +
                Math.sin(convertToRadian(p1.latitude)) +
                Math.sin(convertToRadian(p2.latitude)));
      }

      area = area * 6378137 * 6378137 / 2;
    }

    double areaAcres = area.abs() * 0.000247105;
    // if (areaType == "acres") {
    //   areaValue = areaAcres; //sq meters to Acres

    // } else if (areaType == "guntha") {
    //   areaValue = areaAcres * 40.00000001; //sq meters to Acres
    // } else if (areaType == "vaar") {
    //   areaValue = areaAcres * 4840; //sq meters to Acres
    // }

    return areaAcres;
  }

  static double convertToRadian(double input) {
    return input * Math.pi / 180;
  }

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }
}
