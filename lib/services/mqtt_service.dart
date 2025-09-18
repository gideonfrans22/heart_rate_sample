import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  static MqttService get instance => _instance;
  MqttService._internal();

  late MqttServerClient _client;
  final StreamController<double> _heartRateController =
      StreamController<double>.broadcast();

  Stream<double> get heartRateStream => _heartRateController.stream;
  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> initialize() async {
    // Configure MQTT client
    _client = MqttServerClient('139.59.251.61', 'flutter_client');
    _client.port = 1883; // Standard MQTT port
    _client.keepAlivePeriod = 60;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;

    try {
      await connect();
    } catch (e) {
      print('MQTT initialization failed: $e');
    }
  }

  Future<void> connect() async {
    try {
      print('Connecting to MQTT broker...');
      await _client.connect(
        "default",
        "12345",
      ); // Set authentication credentials

      if (_client.connectionStatus?.state == MqttConnectionState.connected) {
        print('MQTT connected successfully');
        _subscribeToHeartRate();
      }
    } catch (e) {
      print('MQTT connection failed: $e');
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

      // Parse heart rate value
      try {
        final heartRate = double.parse(message);
        _heartRateController.add(heartRate);
      } catch (e) {
        print('Failed to parse heart rate: $message');
      }
    });
  }

  void _onConnected() {
    print('MQTT client connected');
  }

  void _onDisconnected() {
    print('MQTT client disconnected');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void disconnect() {
    _client.disconnect();
  }

  void dispose() {
    _heartRateController.close();
    disconnect();
  }
}
