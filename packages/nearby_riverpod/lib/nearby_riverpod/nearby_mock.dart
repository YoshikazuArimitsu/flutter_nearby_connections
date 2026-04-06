// nearby_mock.dart
import 'dart:async';
import 'package:nearby_connections/nearby_connections.dart';

import 'nearby_interface.dart';

class NearbyServiceMock implements INearbyService {
  final _controller = StreamController<NearbyEvent>.broadcast();

  @override
  Stream<NearbyEvent> get events => _controller.stream;

  @override
  Future<void> requestPermissions() async {
    await Future.delayed(Duration(milliseconds: 300));
    _controller.add(NearbyEvent("mock_request_permissions"));
  }

  @override
  Future<void> startAdvertising(
      {required String nickname,
      Strategy strategy = Strategy.P2P_CLUSTER}) async {
    await Future.delayed(Duration(milliseconds: 300));
    _controller.add(NearbyEvent("mock_advertising"));
  }

  @override
  Future<void> stopAdvertising() async {
    await Future.delayed(Duration(milliseconds: 300));
    _controller.add(NearbyEvent("mock_advertising"));
  }

  @override
  Future<void> startDiscovery(
      {required String nickname,
      Strategy strategy = Strategy.P2P_CLUSTER}) async {
    await Future.delayed(Duration(milliseconds: 300));
    _controller.add(NearbyEvent("mock_discovery"));
  }

  @override
  Future<void> stopDiscovery() async {
    await Future.delayed(Duration(milliseconds: 300));
    _controller.add(NearbyEvent("mock_discovery"));
  }

  @override
  Future<void> disconnectEndpoint(String endpointId) async {
    await Future.delayed(Duration(milliseconds: 300));
    _controller.add(NearbyEvent("mock_disconnect"));
  }

  @override
  Future<int> sendFile(String endpointId, String filePath) async {
    await Future.delayed(Duration(milliseconds: 500));
    _controller.add(NearbyEvent("mock_send"));
    return 1; // Return a mock payload ID
  }
}
