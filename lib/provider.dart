import 'package:flutter_nearby_connections/nearby_repository/nearby_controller.dart';
import 'package:flutter_nearby_connections/nearby_repository/nearby_impl.dart';
import 'package:flutter_nearby_connections/nearby_repository/nearby_interface.dart';
import 'package:flutter_nearby_connections/nearby_repository/nearby_mock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nearbyServiceProvider = Provider<INearbyService>((ref) {
  const useMock = bool.fromEnvironment("USE_MOCK", defaultValue: false);

  return useMock ? NearbyServiceMock() : NearbyServiceImpl();
});

final nearbyProvider = NotifierProvider<NearbyController, NearbyState>(
  () => NearbyController(),
);
