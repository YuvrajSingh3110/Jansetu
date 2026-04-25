import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  /// Requests permission and gets the current locality/subLocality (village/city name).
  /// Returns a default fallback if location services are disabled or permission denied.
  Future<String> getCurrentLocality({String fallback = 'Village'}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return fallback;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return fallback;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return fallback;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // SubLocality often holds village/neighborhood name in rural areas,
        // Locality holds city/town name.
        if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
          return placemark.subLocality!;
        } else if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          return placemark.locality!;
        }
      }
    } catch (_) {
      // In case of timeout or geocoding error
      return fallback;
    }

    return fallback;
  }
}
