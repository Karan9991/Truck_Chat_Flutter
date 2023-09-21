import 'package:chat/chat/chat_list.dart';
import 'package:chat/privateChat/chatlist.dart';
import 'package:chat/utils/alert_dialog.dart';
import 'package:chat/utils/constants.dart';
import 'package:chat/utils/device_type.dart';
import 'package:chat/utils/shared_pref.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart' as geoloc;
//import 'package:location/location.dart';

Future<void> registerDevice() async {
  debugPrint(
      '---------------------------User Register Start------------------------------');

  String user_id = '';
  String deviceType = getDeviceType();

   geoloc.Position? currentLocation;
  double latitude = 1.0;
  double longitude = 1.0;

  // Request location permission
  final permissionStatus = await geoloc.Geolocator.checkPermission();

  debugPrint(
      '---------------------------Permission status $permissionStatus------------------------------');

  try {
    geoloc.Position currentLocation =
        await geoloc.Geolocator.getCurrentPosition(
      desiredAccuracy: geoloc.LocationAccuracy.high,
    );

    latitude = currentLocation.latitude;
    longitude = currentLocation.longitude;

    debugPrint("Latitude: $latitude");
    debugPrint("Longitude: $longitude");
  } catch (e) {
    debugPrint("Error while getting location: $e");
  }

  // Location location = Location();
  // LocationData? currentLocation;

  // // Request location permission
  // PermissionStatus? permissionStatus;
  // permissionStatus = await location.requestPermission();
  // if (permissionStatus != PermissionStatus.granted) {
  //   // Handle permission not granted
  //   return;
  // }

  // // Fetch current location
  // try {
  //   currentLocation = await location.getLocation();
  //   latitude = currentLocation.latitude!;
  //   longitude = currentLocation.longitude!;
  //   debugPrint('${currentLocation.latitude}');
  //   debugPrint('${currentLocation.longitude}');
  // } catch (e) {
  //   // Handle location fetch error
  //   debugPrint('Error fetching location: $e');
  //   return;
  // }
  // Device registration data
  // Fetch device serial number and store in SharedPrefs
  String? serialNumber = await getDeviceSerialNumber();

  SharedPrefs.setString(SharedPrefsKeys.SERIAL_NUMBER, serialNumber!);

  if (serialNumber == null) {
    // Handle error getting serial number
    debugPrint('Error getting device serial number');
    return;
  }

  String? registrationId = await getFirebaseToken();

  debugPrint('Firebase token $registrationId');
  if (registrationId == null) {
    // Handle error getting Firebase token
    debugPrint('Error getting Firebase token');
    return;
  }

  // Prepare request body
  Map<String, dynamic> requestBody = {
    API.DEVICE_ID: serialNumber,
    API.DEVICE_GCM_ID: registrationId,
    API.DEVICE_TYPE: deviceType,
    API.LATITUDE: latitude,
    API.LONGITUDE: longitude,
  };

  String requestBodyJson = jsonEncode(requestBody);

  // Send POST request to server
  Uri url = Uri.parse(API.DEVICE_REGISTER);
  http.Response response = await http.post(
    url,
    body: requestBodyJson,
    headers: {API.CONTENT_TYPE: API.APPLICATION_JSON},
  );

  // Handle server response
  if (response.statusCode == 200) {
    debugPrint('---------------Device Register Response---------------');

    // Registration successful
    debugPrint("Device registered successfully!");

    Map<String, dynamic> responseBody = jsonDecode(response.body);

    // Check if the user_id exists in the response
    if (responseBody.containsKey(API.USER_ID)) {
      user_id = responseBody[API.USER_ID].toString();
      debugPrint("User ID: $user_id");
      SharedPrefs.setString(SharedPrefsKeys.USER_ID, user_id);
      SharedPrefs.setDouble(SharedPrefsKeys.LATITUDE, latitude!);
      SharedPrefs.setDouble(SharedPrefsKeys.LONGITUDE, longitude!);

      debugPrint('testing ${SharedPrefs.getString(SharedPrefsKeys.USER_ID)}');
    } else {
      debugPrint("Error: User ID not found in response");
    }

    debugPrint(response.body);
  } else {
    // Registration failed
    debugPrint("Device registration failed: ${response.body}");
  }

  debugPrint(
      '---------------------------User Register End------------------------------');
}

Future<String?> getDeviceSerialNumber() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String? serialNumber;

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    serialNumber = androidInfo.androidId;
    debugPrint("Serial number $serialNumber");
  } else if (Platform.isIOS) {
    // For iOS, you can use androidId as an alternative if needed
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    serialNumber = iosInfo.identifierForVendor;
  }

  return serialNumber;
}

Future<String?> getFirebaseToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token;

  try {
    token = await messaging.getToken();
  } catch (e) {
    debugPrint('Error getting Firebase token: $e');
  }

  return token;
}
