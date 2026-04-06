import 'package:nearby_connections/nearby_connections.dart';

abstract class INearbyService {
  // 必要なパーミッションの要求
  Future<void> requestPermissions();

  // Advertiseの開始と停止
  Future<void> startAdvertising(
      {required String nickname, Strategy strategy = Strategy.P2P_CLUSTER});
  Future<void> stopAdvertising();

  // Discoveryの開始と停止
  Future<void> startDiscovery(
      {required String nickname, Strategy strategy = Strategy.P2P_CLUSTER});
  Future<void> stopDiscovery();

  // エンドポイントの切断
  Future<void> disconnectEndpoint(String endpointId);

  // ファイルの送信
  Future<int> sendFile(String endpointId, String filePath);

  // Nearbyからのイベントストリーム
  Stream<NearbyEvent> get events;
}

// Nearbyイベントの定義
class NearbyEvent {
  // イベントの種類
  // endpointFound
  // endpointLost
  // connectionInitiated
  // connectionResult
  // disconnected
  // startAdvertising
  // stopAdvertising
  // startDiscovery
  // stopDiscovery
  // startSendPayload
  // payloadReceived
  // payloadTransferUpdate
  final String type;

  // イベント対象エンドポイント/ペイロードID
  final String? endpointId;
  final int? payloadId;

  // 追加イベントデータ(Status, Payload, PayloadTransferUpdate)
  final dynamic data;

  NearbyEvent(this.type, {this.endpointId, this.payloadId, this.data});
}
