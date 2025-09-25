import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'mqtt_service.dart';

class MqttServiceWeb implements MqttServiceBase {
  MqttBrowserClient? _client;
  final StreamController<double> _heartRateController =
      StreamController<double>.broadcast();
  bool _isInitialized = false;
  Timer? _reconnectTimer;

  @override
  Stream<double> get heartRateStream => _heartRateController.stream;

  @override
  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Add explicit debug logging
    print('🌐 WEB MQTT SERVICE: Initializing...');
    print('🌐 Platform check - kIsWeb: $kIsWeb');

    try {
      await _createClient();
      await _connect();
      _isInitialized = true;
      print('🌐 WEB MQTT SERVICE: Initialization completed successfully');
    } catch (e) {
      print('🌐 WEB MQTT SERVICE: Initialization failed: $e');
      _scheduleReconnect();
    }
  }

  Future<void> _createClient() async {
    // Dispose of existing client if any
    if (_client != null) {
      try {
        _client!.disconnect();
      } catch (e) {
        print('🌐 Error disconnecting existing client: $e');
      }
    }

    // Create new client with unique ID and explicit WebSocket URL
    final wsUrl = 'wss://ws.kasihkaruniakekalpt.com';
    final clientId = 'flutter_web_${DateTime.now().millisecondsSinceEpoch}';

    print('🌐 Creating MqttBrowserClient with URL: $wsUrl');
    print('🌐 Client ID: $clientId');

    _client = MqttBrowserClient(wsUrl, clientId);

    // Configure client
    _client!.keepAlivePeriod = 30;
    _client!.autoReconnect = true;
    _client!.resubscribeOnAutoReconnect = true;
    _client!.websocketProtocols = ['mqtt'];
    _client!.port = 443;

    // Set up event handlers
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.onAutoReconnect = _onAutoReconnect;
    _client!.onAutoReconnected = _onAutoReconnected;

    print('🌐 MqttBrowserClient created and configured');
  }

  Future<void> _connect() async {
    if (_client == null) return;

    try {
      print('🌐 Connecting to MQTT broker via WebSocket...');
      print('🌐 Connection URL: wss://ws.kasihkaruniakekalpt.com');

      // Connect with credentials
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(_client!.clientIdentifier)
          .keepAliveFor(30)
          .withWillTopic('willtopic')
          .withWillMessage('Will message')
          .startClean()
          .authenticateAs('default', '12345')
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      await _client!.connect();

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        print('🌐 MQTT connected successfully (Web) via WebSocket');
        _subscribeToHeartRate();
      } else {
        throw Exception(
          'Connection failed: ${_client!.connectionStatus?.returnCode}',
        );
      }
    } catch (e) {
      print('🌐 MQTT connection failed: $e');
      _scheduleReconnect();
      rethrow;
    }
  }

  void _subscribeToHeartRate() {
    if (_client == null || !isConnected) return;

    try {
      const topic = 'esp32/heartrate';
      print('🌐 Subscribing to topic: $topic');
      _client!.subscribe(topic, MqttQos.atMostOnce);

      _client!.updates!.listen(
        (List<MqttReceivedMessage<MqttMessage?>> messages) {
          if (messages.isEmpty) return;

          try {
            final recMess = messages[0].payload as MqttPublishMessage;
            final message = MqttPublishPayload.bytesToStringAsString(
              recMess.payload.message,
            );

            final heartRate = double.parse(message.trim());
            print('🌐 Received heart rate: $heartRate');
            _heartRateController.add(heartRate);
          } catch (e) {
            print('🌐 Failed to parse heart rate message: $e');
          }
        },
        onError: (error) {
          print('🌐 MQTT updates stream error: $error');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      print('🌐 Failed to subscribe to heart rate topic: $e');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (!isConnected && _isInitialized) {
        print('🌐 Attempting to reconnect...');
        try {
          await _createClient();
          await _connect();
        } catch (e) {
          print('🌐 Reconnection failed: $e');
          _scheduleReconnect();
        }
      }
    });
  }

  void _onConnected() {
    print('🌐 MQTT client connected (Web)');
    _reconnectTimer?.cancel();
  }

  void _onDisconnected() {
    print('🌐 MQTT client disconnected (Web)');
    if (_isInitialized) {
      _scheduleReconnect();
    }
  }

  void _onSubscribed(String topic) {
    print('🌐 Subscribed to topic: $topic (Web)');
  }

  void _onAutoReconnect() {
    print('🌐 MQTT auto-reconnecting (Web)...');
  }

  void _onAutoReconnected() {
    print('🌐 MQTT auto-reconnected (Web)');
    _subscribeToHeartRate();
  }

  @override
  void disconnect() {
    try {
      _reconnectTimer?.cancel();
      _client?.disconnect();
    } catch (e) {
      print('🌐 Error during disconnect: $e');
    }
  }

  @override
  void dispose() {
    _isInitialized = false;
    _reconnectTimer?.cancel();

    try {
      _client?.disconnect();
    } catch (e) {
      print('🌐 Error during disposal: $e');
    }

    if (!_heartRateController.isClosed) {
      _heartRateController.close();
    }
  }
}

// This is the factory function that will be used by the conditional import
MqttServiceBase createMqttService() {
  print('🌐 Creating MQTT Web service instance');
  return MqttServiceWeb();
}
