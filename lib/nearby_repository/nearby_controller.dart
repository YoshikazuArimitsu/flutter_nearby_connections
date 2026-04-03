// nearby_controller.dart
import 'package:flutter_nearby_connections/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nearby_interface.dart';

class NearbyState {
  final bool isAdvertising;
  final bool isDiscovering;
  final List<String> endpoints;

  const NearbyState({
    this.isAdvertising = false,
    this.isDiscovering = false,
    this.endpoints = const [],
  });

  NearbyState copyWith({
    bool? isAdvertising,
    bool? isDiscovering,
    List<String>? endpoints,
  }) {
    return NearbyState(
      isAdvertising: isAdvertising ?? this.isAdvertising,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      endpoints: endpoints ?? this.endpoints,
    );
  }
}

class NearbyController extends Notifier<NearbyState> {
  late final INearbyService nearby;

  @override
  NearbyState build() {
    nearby = ref.read(nearbyServiceProvider);
    _listenEvents();
    return const NearbyState();
  }

  void _listenEvents() {
    nearby.events.listen((event) {
      switch (event.type) {
        case "connectionInitiated":
          state = state.copyWith(
            endpoints: [...state.endpoints, event.endpointId!],
          );
          break;
        case "disconnected":
          state = state.copyWith(
            endpoints: state.endpoints
                .where((e) => e != event.endpointId)
                .toList(),
          );
          break;
      }
    });
  }

  Future<void> startAdvertising() async {
    await nearby.startAdvertising();
    state = state.copyWith(isAdvertising: true);
  }

  Future<void> stopAdvertising() async {
    await nearby.stopAdvertising();
    state = state.copyWith(isAdvertising: false);
  }

  Future<void> startDiscovery() async {
    await nearby.startDiscovery();
    state = state.copyWith(isDiscovering: true);
  }

  Future<void> stopDiscovery() async {
    await nearby.stopDiscovery();
    state = state.copyWith(isDiscovering: false);
  }

  Future<void> disconnectEndpoint(String endpointId) async {
    await nearby.disconnectEndpoint(endpointId);
  }

  Future<int> sendFile(String id, String path) async {
    return await nearby.sendFile(id, path);
  }
}
