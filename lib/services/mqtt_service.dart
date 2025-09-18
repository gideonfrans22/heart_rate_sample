import 'dart:async';
import 'package:flutter/foundation.dart';
import 'mqtt_service_mobile.dart'
    if (dart.library.html) 'mqtt_service_web.dart';

abstract class MqttServiceBase {
  Stream<double> get heartRateStream;
  bool get isConnected;
  Future<void> initialize();
  void disconnect();
  void dispose();
}

class MqttService {
  static final MqttService _instance = MqttService._internal();
  static MqttService get instance => _instance;
  MqttService._internal();

  MqttServiceBase? _implementation;
  bool _initialized = false;

  Stream<double> get heartRateStream =>
      _implementation?.heartRateStream ?? const Stream.empty();

  bool get isConnected => _initialized && _implementation != null
      ? _implementation!.isConnected
      : false;

  Future<void> initialize() async {
    if (!_initialized) {
      try {
        _implementation = createMqttService();
        await _implementation!.initialize();
        _initialized = true;

        // Debug: Print which implementation is being used
        if (kIsWeb) {
          print('Using MQTT Web implementation');
        } else {
          print('Using MQTT Mobile implementation');
        }
      } catch (e) {
        print('Failed to initialize MQTT service: $e');
        _initialized = false;
      }
    }
  }

  void disconnect() {
    if (_initialized && _implementation != null) {
      _implementation!.disconnect();
    }
  }

  void dispose() {
    if (_initialized && _implementation != null) {
      _implementation!.dispose();
      _initialized = false;
      _implementation = null;
    }
  }
}
