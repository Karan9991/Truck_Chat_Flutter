import 'package:chat/utils/constants.dart';
import 'package:geolocator/geolocator.dart';

Future<Map<String, double>> getLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double latitude = position.latitude;
    double longitude = position.longitude;

    return {Constants.LATITUDE: latitude, Constants.LONGITUDE: longitude};
  } catch (e) {
    // Handle location fetch error
    //throw Exception('Error fetching location: $e');
    return {Constants.LATITUDE: 1.0, Constants.LONGITUDE: 1.0};
  }
}


// import 'package:location/location.dart';

// Future<Map<String, double>> getLocation() async {
//   Location location = Location();
//   LocationData? currentLocation;

//   // Request location permission
//   // PermissionStatus? permissionStatus;
//   // permissionStatus = await location.requestPermission();
//   // if (permissionStatus != PermissionStatus.granted) {
//   //   // Handle permission not granted
//   //   throw Exception('Location permission not granted');
//   // }

//   // Fetch current location
//   try {
//     currentLocation = await location.getLocation();
//     double latitude = currentLocation.latitude!;
//     double longitude = currentLocation.longitude!;
//     return {Constants.LATITUDE: latitude, Constants.LONGITUDE: longitude};
//   } catch (e) {
//     // Handle location fetch error
//      return {Constants.LATITUDE: 1.0, Constants.LONGITUDE: 1.0};
//   }
// }