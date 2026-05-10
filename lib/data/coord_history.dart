import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last [maxEntries] coordinate pairs the user has submitted.
/// Each entry is stored as "lat,lon" in SharedPreferences (localStorage on web).
class CoordHistory {
  static const _key = 'coord_history';
  static const maxEntries = 5;

  static Future<List<({double lat, double lon})>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final result = <({double lat, double lon})>[];
    for (final s in raw) {
      final parts = s.split(',');
      if (parts.length != 2) continue;
      final lat = double.tryParse(parts[0]);
      final lon = double.tryParse(parts[1]);
      if (lat != null && lon != null) result.add((lat: lat, lon: lon));
    }
    return result;
  }

  static Future<void> save(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    final entry = '$lat,$lon';
    existing.remove(entry);
    existing.insert(0, entry);
    if (existing.length > maxEntries) existing.length = maxEntries;
    await prefs.setStringList(_key, existing);
  }
}
