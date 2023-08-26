
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

Future<void> registerDevice() async {
  print(
      '---------------------------User Register Start------------------------------');


  String user_id = '';
  String deviceType = getDeviceType();

  geoloc.Position? currentLocation;
  double latitude = 1.0;
  double longitude = 1.0;

  // Request location permission
  final permissionStatus = await geoloc.Geolocator.checkPermission();

  print(
      '---------------------------Permission status $permissionStatus------------------------------');

  try {
    geoloc.Position currentLocation =
        await geoloc.Geolocator.getCurrentPosition(
      desiredAccuracy: geoloc.LocationAccuracy.high,
    );

    latitude = currentLocation.latitude;
    longitude = currentLocation.longitude;

    print("Latitude: $latitude");
    print("Longitude: $longitude");
  } catch (e) {
    print("Error while getting location: $e");
  }

  // Device registration data
  // Fetch device serial number and store in SharedPrefs
  String? serialNumber = await getDeviceSerialNumber();

  SharedPrefs.setString(SharedPrefsKeys.SERIAL_NUMBER, serialNumber!);

  if (serialNumber == null) {
    // Handle error getting serial number
    print('Error getting device serial number');
    return;
  }

  String? registrationId = await getFirebaseToken();

  print('Firebase token $registrationId');
  if (registrationId == null) {
    // Handle error getting Firebase token
    print('Error getting Firebase token');
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
    print('---------------Device Register Response---------------');

    // Registration successful
    print("Device registered successfully!");

    Map<String, dynamic> responseBody = jsonDecode(response.body);

    // Check if the user_id exists in the response
    if (responseBody.containsKey(API.USER_ID)) {
      user_id = responseBody[API.USER_ID].toString();
      print("User ID: $user_id");
      SharedPrefs.setString(SharedPrefsKeys.USER_ID, user_id);
      SharedPrefs.setDouble(SharedPrefsKeys.LATITUDE, latitude!);
      SharedPrefs.setDouble(SharedPrefsKeys.LONGITUDE, longitude!);

      print('testing ${SharedPrefs.getString(SharedPrefsKeys.USER_ID)}');
    } else {
      print("Error: User ID not found in response");
    }

    print(response.body);
  } else {
    // Registration failed
    print("Device registration failed: ${response.body}");
  }


  print(
      '---------------------------User Register End------------------------------');
}

Future<String?> getDeviceSerialNumber() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String? serialNumber;

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    serialNumber = androidInfo.androidId;
    print("Serial number $serialNumber");
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
    print('Error getting Firebase token: $e');
  }

  return token;
}
