import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:background_sms/background_sms.dart';
import 'package:we_heroes/db/db_services.dart';
import 'package:we_heroes/model/contactsm.dart';

class SafeHome extends StatefulWidget {
  @override
  State<SafeHome> createState() => _SafeHomeState();
}

class _SafeHomeState extends State<SafeHome> {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false; // Track loading state

  Future<bool> _isPermissionGranted() async {
    PermissionStatus smsPermission = await Permission.sms.status;

    if (smsPermission.isGranted) {
      return true; // Permission already granted
    } else if (smsPermission.isDenied) {
      // Request permission
      smsPermission = await Permission.sms.request();
      return smsPermission.isGranted; // Check if permission is granted after request
    } else if (smsPermission.isPermanentlyDenied) {
      // If permission is permanently denied, navigate to app settings
      openAppSettings();
      return false;
    }

    return false; // Default case, should not reach here
  }

  Future<void> _sendSms(String phoneNumber, String message) async {
    SmsStatus result = await BackgroundSms.sendMessage(
      phoneNumber: phoneNumber,
      message: message,
    );

    if (result == SmsStatus.sent) {
      Fluttertoast.showToast(msg: "Message sent to $phoneNumber");
    } else {
      Fluttertoast.showToast(msg: "Failed to send message to $phoneNumber");
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services.')));
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are denied.')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() {
        _isLoading = false; // Stop loading
      });
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      _getAddressFromLatLon();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _getAddressFromLatLon() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);

      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
        "${place.locality}, ${place.postalCode}, ${place.street}";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  void showModelSafeHome(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height / 1.4,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "SEND YOUR CURRENT LOCATION IMMEDIATELY TO YOUR EMERGENCY CONTACTS",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                if (_isLoading)
                  CircularProgressIndicator(), // Show progress indicator
                if (!_isLoading && _currentPosition != null)
                  Text(_currentAddress!),
                PrimaryButton(
                    title: "GET LOCATION",
                    onPressed: () {
                      _getCurrentLocation();
                    }),
                SizedBox(height: 10),
                PrimaryButton(
                    title: "SEND ALERT",
                    onPressed: () async {
                      List<TContact> contactList =
                      await DatabaseHelper().getContactList();

                      if (contactList.isEmpty) {
                        Fluttertoast.showToast(
                            msg: "Emergency contact is empty");
                      } else {
                        String messageBody =
                            "I am in trouble! Here is my location: "
                            "https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}. $_currentAddress";

                        if (await _isPermissionGranted()) {
                          setState(() {
                            _isLoading = true; // Start loading
                          });
                          for (var contact in contactList) {
                            await _sendSms(contact.number, messageBody);
                          }
                          setState(() {
                            _isLoading = false; // Stop loading
                          });
                        } else {
                          Fluttertoast.showToast(msg: "SMS permission denied");
                        }
                      }
                    }),
              ],
            ),
          ),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              )),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModelSafeHome(context),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          height: 180,
          width: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(),
          child: Row(
            children: [
              Expanded(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text("Send Location"),
                        subtitle: Text("Share Location"),
                      ),
                    ],
                  )),
              ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/route.jpg')),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String title;
  final Function onPressed;

  PrimaryButton({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: MediaQuery.of(context).size.width * 0.5,
      child: ElevatedButton(
        onPressed: () => onPressed(),
        child: Text(
          title,
          style: TextStyle(fontSize: 17),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
