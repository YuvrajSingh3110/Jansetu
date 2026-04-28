import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:jansetu/core/services/location_service.dart';

class NearbyHealthResource {
  const NearbyHealthResource({
    required this.name,
    required this.distanceKm,
    required this.mapsUrl,
    this.status,
    this.details,
    this.phoneNumber,
    this.isFallback = false,
  });

  final String name;
  final double distanceKm;
  final String mapsUrl;
  final String? status;
  final String? details;
  final String? phoneNumber;
  final bool isFallback;
}

class NearbyHealthService {
  NearbyHealthService({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  final LocationService _locationService;

  Future<NearbyHealthResource?> findNearbyPhc() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return null;

    try {
      final query = '''
[out:json][timeout:15];
(
  node["name"](around:12000,${position.latitude},${position.longitude})["name"~"PHC|Primary Health Centre|Primary Health Center|Community Health Centre|Community Health Center",i];
  way["name"](around:12000,${position.latitude},${position.longitude})["name"~"PHC|Primary Health Centre|Primary Health Center|Community Health Centre|Community Health Center",i];
  node["amenity"~"hospital|clinic",i](around:8000,${position.latitude},${position.longitude});
  way["amenity"~"hospital|clinic",i](around:8000,${position.latitude},${position.longitude});
);
out center tags 20;
''';

      final response = await http.get(
        Uri.https(
          'overpass-api.de',
          '/api/interpreter',
          {'data': query},
        ),
      );

      if (response.statusCode != 200) {
        return _buildFallback(position);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = (decoded['elements'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      if (elements.isEmpty) {
        return _buildFallback(position);
      }

      elements.sort((a, b) {
        final distanceA = _distanceForElement(position, a);
        final distanceB = _distanceForElement(position, b);
        final scoreA = _priorityScore(a);
        final scoreB = _priorityScore(b);
        if (scoreA != scoreB) return scoreB.compareTo(scoreA);
        return distanceA.compareTo(distanceB);
      });

      final best = elements.first;
      final lat = _elementLat(best);
      final lon = _elementLon(best);
      final tags = (best['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final distanceKm = _distanceForElement(position, best);
      final name = (tags['name'] as String?)?.trim();

      return NearbyHealthResource(
        name: (name == null || name.isEmpty) ? 'Nearby PHC' : name,
        distanceKm: distanceKm,
        status: _buildStatus(tags),
        details: _buildDetails(tags),
        phoneNumber: _extractPhone(tags),
        mapsUrl: _mapsUrlForCoordinates(lat, lon, name ?? 'Nearby PHC'),
      );
    } catch (_) {
      return _buildFallback(position);
    }
  }

  NearbyHealthResource _buildFallback(Position position) {
    return NearbyHealthResource(
      name: 'Nearby PHC',
      distanceKm: 0,
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=primary%20health%20centre%20near%20${position.latitude},${position.longitude}',
      status: null,
      details: null,
      isFallback: true,
    );
  }

  double _distanceForElement(Position userPosition, Map<String, dynamic> element) {
    final lat = _elementLat(element);
    final lon = _elementLon(element);
    return Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          lat,
          lon,
        ) /
        1000;
  }

  double _elementLat(Map<String, dynamic> element) {
    final lat = element['lat'] ?? (element['center'] as Map?)?['lat'];
    return (lat as num).toDouble();
  }

  double _elementLon(Map<String, dynamic> element) {
    final lon = element['lon'] ?? (element['center'] as Map?)?['lon'];
    return (lon as num).toDouble();
  }

  int _priorityScore(Map<String, dynamic> element) {
    final tags = (element['tags'] as Map?)?.cast<String, dynamic>() ?? {};
    final name = ((tags['name'] as String?) ?? '').toLowerCase();
    if (name.contains('primary health centre') ||
        name.contains('primary health center') ||
        name.contains('community health centre') ||
        name.contains('community health center') ||
        name.contains('phc')) {
      return 3;
    }
    final amenity = ((tags['amenity'] as String?) ?? '').toLowerCase();
    if (amenity == 'hospital') return 2;
    if (amenity == 'clinic') return 1;
    return 0;
  }

  String _mapsUrlForCoordinates(double lat, double lon, String label) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
  }

  String? _buildStatus(Map<String, dynamic> tags) {
    final openingHours = tags['opening_hours'] as String?;
    if (openingHours == null || openingHours.trim().isEmpty) return null;
    return openingHours;
  }

  String? _buildDetails(Map<String, dynamic> tags) {
    final operatorName = tags['operator'] as String?;
    final healthcare = tags['healthcare'] as String?;
    final amenity = tags['amenity'] as String?;
    final bits = [
      if (healthcare != null && healthcare.isNotEmpty) healthcare,
      if (amenity != null && amenity.isNotEmpty) amenity,
      if (operatorName != null && operatorName.isNotEmpty) operatorName,
    ];
    if (bits.isEmpty) return null;
    return bits.join(' · ');
  }

  String? _extractPhone(Map<String, dynamic> tags) {
    final candidates = [
      tags['contact:phone'],
      tags['phone'],
      tags['contact:mobile'],
    ];
    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
