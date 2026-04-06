import 'dart:async';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'nearby_interface.dart';

const Strategy strategy = Strategy.P2P_CLUSTER;

class NearbyServiceImpl implements INearbyService {
  final _controller = StreamController<NearbyEvent>.broadcast();

  @override
  Stream<NearbyEvent> get events => _controller.stream;

  @override
  Future<void> requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ].request();
  }

  @override
  Future<void> startAdvertising() async {
    await Nearby().startAdvertising(
      "deviceName",
      strategy,
      onConnectionInitiated: (id, info) {
        _controller.add(NearbyEvent("connectionInitiated", endpointId: id));
        Nearby().acceptConnection(
          id,
          onPayLoadRecieved: (id, payload) {
            _controller.add(
              NearbyEvent(
                "payloadReceived",
                endpointId: id,
                payloadId: payload.id,
                data: payload,
              ),
            );
          },
          onPayloadTransferUpdate: (id, update) {
            _controller.add(
              NearbyEvent(
                "payloadTransferUpdate",
                endpointId: id,
                payloadId: update.id,
                data: update,
              ),
            );
          },
        );
      },
      onConnectionResult: (id, status) {
        _controller.add(
          NearbyEvent("connectionResult", endpointId: id, data: status),
        );
      },
      onDisconnected: (id) {
        _controller.add(NearbyEvent("disconnected", endpointId: id));
      },
    );

    _controller.add(NearbyEvent("startAdvertising"));
  }

  @override
  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
    _controller.add(NearbyEvent("stopAdvertising"));
  }

  @override
  Future<void> startDiscovery() async {
    await Nearby().startDiscovery(
      "serviceId",
      strategy,
      onEndpointFound: (id, name, serviceId) {
        _controller.add(NearbyEvent("endpointFound", endpointId: id));

        Nearby().requestConnection(
          "deviceName",
          id,
          onConnectionInitiated: (id, info) {
            _controller.add(NearbyEvent("connectionInitiated", endpointId: id));
            Nearby().acceptConnection(
              id,
              onPayLoadRecieved: (id, payload) {
                _controller.add(
                  NearbyEvent(
                    "payloadReceived",
                    endpointId: id,
                    payloadId: payload.id,
                    data: payload,
                  ),
                );
              },
              onPayloadTransferUpdate: (id, update) {
                _controller.add(
                  NearbyEvent(
                    "payloadTransferUpdate",
                    endpointId: id,
                    payloadId: update.id,
                    data: update,
                  ),
                );
              },
            );
          },
          onConnectionResult: (id, status) {
            _controller.add(
              NearbyEvent("connectionResult", endpointId: id, data: status),
            );
          },
          onDisconnected: (id) {
            _controller.add(NearbyEvent("disconnected", endpointId: id));
          },
        );
      },
      onEndpointLost: (id) {
        _controller.add(NearbyEvent("endpointLost", endpointId: id));
      },
    );

    _controller.add(NearbyEvent("startDiscovery"));
  }

  @override
  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
    _controller.add(NearbyEvent("stopDiscovery"));
  }

  @override
  Future<void> disconnectEndpoint(String endpointId) async {
    await Nearby().disconnectFromEndpoint(endpointId);
  }

  @override
  Future<int> sendFile(String endpointId, String filePath) async {
    final payloadId = await Nearby().sendFilePayload(endpointId, filePath);
    _controller.add(
      NearbyEvent("startSendPayload", endpointId: endpointId, data: payloadId),
    );
    return payloadId;
  }
}
