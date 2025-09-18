import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'mqtt_service.dart';

class MqttServiceMobile implements MqttServiceBase {
  late MqttServerClient _client;
  final StreamController<double> _heartRateController =
      StreamController<double>.broadcast();

  @override
  Stream<double> get heartRateStream => _heartRateController.stream;

  @override
  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;

  @override
  Future<void> initialize() async {
    print('📱 MOBILE MQTT SERVICE: Initializing...');
    print('📱 Platform check - kIsWeb: $kIsWeb');

    _client = MqttServerClient(
      '139.59.251.61',
      'flutter_mobile_client_${DateTime.now().millisecondsSinceEpoch}',
    );
    _client.port = 1883;
    _client.keepAlivePeriod = 60;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;

    print('📱 Mobile client configured for 139.59.251.61:1883');

    try {
      await _connect();
    } catch (e) {
      print('📱 MQTT initialization failed: $e');
    }
  }

  Future<void> _connect() async {
    try {
      print('📱 Connecting to MQTT broker (Mobile) at 139.59.251.61:1883...');
      await _client.connect("default", "12345");

      if (_client.connectionStatus?.state == MqttConnectionState.connected) {
        print('📱 MQTT connected successfully (Mobile)');
        _subscribeToHeartRate();
      }
    } catch (e) {
      print('📱 MQTT connection failed: $e');
      _client.disconnect();
    }
  }

  void _subscribeToHeartRate() {
    const topic = 'esp32/heartrate';
    _client.subscribe(topic, MqttQos.atMostOnce);

    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      try {
        final heartRate = double.parse(message);
        print('📱 Received heart rate: $heartRate');
        _heartRateController.add(heartRate);
      } catch (e) {
        print('📱 Failed to parse heart rate: $message');
      }
    });
  }

  void _onConnected() => print('📱 MQTT client connected (Mobile)');
  void _onDisconnected() => print('📱 MQTT client disconnected (Mobile)');
  void _onSubscribed(String topic) =>
      print('📱 Subscribed to topic: $topic (Mobile)');

  @override
  void disconnect() => _client.disconnect();

  @override
  void dispose() {
    _heartRateController.close();
    disconnect();
  }
}

// This is the factory function that will be used by the conditional import
MqttServiceBase createMqttService() {
  print('📱 Creating MQTT Mobile service instance');
  return MqttServiceMobile();
}
