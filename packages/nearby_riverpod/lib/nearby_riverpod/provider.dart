import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nearby_controller.dart';
import 'nearby_impl.dart';
import 'nearby_interface.dart';
import 'nearby_mock.dart';

final nearbyServiceProvider = Provider<INearbyService>((ref) {
  const useMock = bool.fromEnvironment("USE_MOCK", defaultValue: false);

  return useMock ? NearbyServiceMock() : NearbyServiceImpl();
});

final nearbyProvider = NotifierProvider<NearbyController, NearbyState>(
  () => NearbyController(),
);
