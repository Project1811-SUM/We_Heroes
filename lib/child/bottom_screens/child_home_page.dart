import 'dart:math';

import 'package:background_sms/background_sms.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shake/shake.dart';
import 'package:we_heroes/db/db_services.dart';
import 'package:we_heroes/model/contactsm.dart';
import 'package:we_heroes/widgets/home_widgets/CustomAppBar.dart';
import 'package:we_heroes/widgets/home_widgets/CustomCarouel.dart';
import 'package:we_heroes/widgets/home_widgets/emergency.dart';
import 'package:we_heroes/widgets/home_widgets/live_safe.dart';
import 'package:we_heroes/widgets/home_widgets/safehome/SafeHome.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int qIndex = 0;
  Position? _currentPosition;
  String? _currentAddress;
  String _currentCity = ''; // Added this to store current city
  bool _isLoading = false; // Track loading state
  bool _locationPermissionGranted = false; // Track location permission status

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
          content: Text('Location services are disabled. Please enable the services.')));
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
          content: Text('Location permissions are permanently denied, we cannot request permissions.')));
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
        _currentCity = place.locality ?? ''; // Get the current city
        _currentAddress =
        "${place.locality}, ${place.postalCode}, ${place.street}";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  getRandomQuote() {
    Random random = Random();
    setState(() {
      qIndex = random.nextInt(6);
    });
  }

  getAndSendSms() async {
    List<TContact> contactList = await DatabaseHelper().getContactList();

    if (contactList.isEmpty) {
      Fluttertoast.showToast(msg: "Emergency contact is empty");
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
  }

  @override
  void initState() {
    getRandomQuote();
    super.initState();
    _getCurrentLocation();

    // Shake feature
    ShakeDetector.autoStart(
      onPhoneShake: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shake detected! Sending SOS...'),
          ),
        );
        getAndSendSms(); // Send SMS when shake is detected
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: 10,
                child: Container(
                  color: Colors.grey.shade100,
                ),
              ),
              SizedBox(height: 5),
              CustomAppBar(
                  quoteIndex: qIndex,
                  onTap: () {
                    getRandomQuote();
                  }),
              SizedBox(height: 5),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  child: Icon(Icons.flight_takeoff_outlined),
                                  backgroundColor: Colors.grey.shade300,
                                ),
                                SizedBox(width: 5),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _locationPermissionGranted == false
                                        ? Text(
                                      "Turn on location services.",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                        : Text("Location enabled"),
                                    SizedBox(height: 5),
                                    _currentCity.isEmpty
                                        ? Text(
                                      "Please enable location for a better experience.",
                                      maxLines: 2,
                                    )
                                        : Text("Current City: $_currentCity"),
                                    SizedBox(height: 5),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: _locationPermissionGranted == true
                                          ? SizedBox()
                                          : MaterialButton(
                                        onPressed: () async {
                                          await _handleLocationPermission();
                                        },
                                        color: Colors.grey.shade100,
                                        shape: StadiumBorder(),
                                        child: Text(
                                          "Enable location",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "In case of emergency, dial me",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Emergency(),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Explore your power",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    CustomCarousel(),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Explore LiveSafe",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    LiveSafe(),
                    SafeHome(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
