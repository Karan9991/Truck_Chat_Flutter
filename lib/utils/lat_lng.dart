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
