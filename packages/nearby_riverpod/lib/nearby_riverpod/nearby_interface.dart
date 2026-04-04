abstract class INearbyService {
  Future<void> requestPermissions();
  Future<void> startAdvertising();
  Future<void> stopAdvertising();
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<void> disconnectEndpoint(String endpointId);
  Future<int> sendFile(String endpointId, String filePath);

  Stream<NearbyEvent> get events;
}

class NearbyEvent {
  final String type;
  final String? endpointId;
  final int? payloadId;
  final dynamic data;

  NearbyEvent(this.type, {this.endpointId, this.payloadId, this.data});
}
