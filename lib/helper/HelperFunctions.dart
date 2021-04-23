import 'package:android_intent/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HelperFunction {
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
}
