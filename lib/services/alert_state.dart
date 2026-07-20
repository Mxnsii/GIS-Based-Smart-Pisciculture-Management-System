import 'package:flutter/foundation.dart';

class AlertState {
  /// Set containing IDs of acknowledged alerts.
  /// 
  /// Format:
  /// - Real-time parameters: `param_temp_low`, `param_temp_high`, `param_ph_low`, etc.
  /// - AI/ML diseases: `$species-$prediction`
  static final Set<String> _acknowledgedAlerts = {};

  /// Accessor for acknowledged alerts.
  static Set<String> get acknowledgedAlerts => _acknowledgedAlerts;

  /// broadcast increments to notify widgets to rebuild when alert state changes
  static final ValueNotifier<int> alertNotifier = ValueNotifier<int>(0);

  /// Acknowledges an alert
  static void acknowledge(String alertKey) {
    if (!_acknowledgedAlerts.contains(alertKey)) {
      _acknowledgedAlerts.add(alertKey);
      alertNotifier.value++;
    }
  }

  /// Checks if an alert is acknowledged
  static bool isAcknowledged(String alertKey) {
    return _acknowledgedAlerts.contains(alertKey);
  }

  /// Resets acknowledgment for an alert (e.g. when condition becomes healthy again)
  static void reset(String alertKey) {
    if (_acknowledgedAlerts.contains(alertKey)) {
      _acknowledgedAlerts.remove(alertKey);
      alertNotifier.value++;
    }
  }

  /// Reset all alerts matching a prefix (e.g. for a species)
  static void resetWhere(bool Function(String) test) {
    bool changed = false;
    _acknowledgedAlerts.removeWhere((key) {
      if (test(key)) {
        changed = true;
        return true;
      }
      return false;
    });
    if (changed) {
      alertNotifier.value++;
    }
  }
}
