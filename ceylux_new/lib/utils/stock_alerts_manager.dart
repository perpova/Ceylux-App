import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockAlertsManager {
  static const String _prefKey = 'read_stock_alerts';

  // ValueNotifier to notify listeners when read alerts change
  static final ValueNotifier<Map<String, int>> readAlertsNotifier = ValueNotifier({});

  // Load initial read alerts from SharedPreferences
  static Future<void> loadReadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final readAlerts = prefs.getStringList(_prefKey) ?? [];
    final map = <String, int>{};
    for (final entry in readAlerts) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final savedQty = int.tryParse(parts[1]);
        if (savedQty != null) {
          map[parts[0]] = savedQty;
        }
      }
    }
    readAlertsNotifier.value = map;
  }

  // Mark a stock item alert as read with its current total quantity
  static Future<void> markAsRead(String id, int currentQty) async {
    final prefs = await SharedPreferences.getInstance();
    final readAlerts = prefs.getStringList(_prefKey) ?? [];
    
    // Remove existing entry for this item ID
    readAlerts.removeWhere((entry) => entry.startsWith('$id:'));
    
    // Add new entry with current quantity
    readAlerts.add('$id:$currentQty');
    await prefs.setStringList(_prefKey, readAlerts);
    
    // Update notifier reactively
    final newMap = Map<String, int>.from(readAlertsNotifier.value);
    newMap[id] = currentQty;
    readAlertsNotifier.value = newMap;
  }

  // Mark all stock items as read
  static Future<void> markAllAsRead(List<dynamic> items) async {
    final prefs = await SharedPreferences.getInstance();
    final readAlerts = prefs.getStringList(_prefKey) ?? [];
    final newMap = Map<String, int>.from(readAlertsNotifier.value);
    
    for (var item in items) {
      final id = item.id;
      final currentQty = item.totalQty;
      readAlerts.removeWhere((entry) => entry.startsWith('$id:'));
      readAlerts.add('$id:$currentQty');
      newMap[id] = currentQty;
    }
    
    await prefs.setStringList(_prefKey, readAlerts);
    readAlertsNotifier.value = newMap;
  }

  // Clear read alert for a stock item
  static Future<void> clearRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readAlerts = prefs.getStringList(_prefKey) ?? [];
    readAlerts.removeWhere((entry) => entry.startsWith('$id:'));
    await prefs.setStringList(_prefKey, readAlerts);
    
    final newMap = Map<String, int>.from(readAlertsNotifier.value);
    newMap.remove(id);
    readAlertsNotifier.value = newMap;
  }
}
