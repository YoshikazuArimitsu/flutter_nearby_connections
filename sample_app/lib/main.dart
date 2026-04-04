import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nearby_riverpod/nearby_riverpod/provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nearby + Riverpod Sample',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NearbyHomePage(),
    );
  }
}

final logProvider = StateProvider<String>((ref) => "");

class NearbyHomePage extends ConsumerStatefulWidget {
  const NearbyHomePage({super.key});

  @override
  ConsumerState<NearbyHomePage> createState() => _NearbyHomePageState();
}

class _NearbyHomePageState extends ConsumerState<NearbyHomePage> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    ref.read(nearbyProvider.notifier).requestPermissions();

    _subscription = ref.read(nearbyProvider.notifier).nearby.events.listen((
      event,
    ) {
      switch (event.type) {
        case "startAdvertising":
          _appendLog(ref, 'Start advertising...');
          break;
        case "stopAdvertising":
          _appendLog(ref, 'Stop advertising.');
          break;
        case "startDiscovery":
          _appendLog(ref, 'Start discovery...');
          break;
        case "stopDiscovery":
          _appendLog(ref, 'Stop discovery.');
          break;

        case "connectionInitiated":
          _appendLog(ref, 'Connection initiated: ${event.endpointId}');
          break;
        case "endpointFound":
          _appendLog(ref, 'Endpoint found: ${event.endpointId}');
          break;
        case "endpointLost":
          _appendLog(ref, 'Endpoint lost: ${event.endpointId}');
          break;
        case "disconnected":
          _appendLog(ref, 'Disconnected: ${event.endpointId}');
          break;
        case "connectionResult":
          _appendLog(ref, 'Connection result: ${event.data}');
          break;

        case "startSendPayload":
          _appendLog(ref, 'Start sending payload: ${event.data}');
          break;

        case "payloadReceived":
          final payload = event.data;
          _appendLog(
            ref,
            'Payload received: EndpointID: ${event.endpointId} PayloadID: ${payload.id}',
          );
          break;

        case "payloadTransferUpdate":
          final payload = event.data;
          _appendLog(
            ref,
            'Payload transfer update: EndpointID: ${event.endpointId} PayloadID: ${payload.id} status: ${payload.status} data: ${payload.bytesTransferred}/${payload.totalBytes}',
          );
          break;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  void _appendLog(WidgetRef ref, String msg) {
    ref.read(logProvider.notifier).state += '$msg\n';
  }

  Future<void> _sendFile(WidgetRef ref, String? endpointId) async {
    final controller = ref.read(nearbyProvider.notifier);

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) {
      _appendLog(ref, 'File picking cancelled');
      return;
    }

    final file = File(result.files.single.path!);
    _appendLog(ref, 'Selected file: ${file.path}');

    try {
      var endpoints = endpointId != null
          ? [endpointId]
          : ref.read(nearbyProvider).endpoints;

      for (final endpoint in endpoints) {
        final payloadId = await controller.sendFile(endpoint, file.path);
        _appendLog(ref, 'Sending to $endpoint, payloadId=$payloadId');
      }
    } catch (e) {
      _appendLog(ref, 'Error sendPayload: $e');
    }
  }

  Future<void> _disconnect(WidgetRef ref, String endpointId) async {
    final controller = ref.read(nearbyProvider.notifier);

    try {
      await controller.disconnectEndpoint(endpointId);
      _appendLog(ref, 'Disconnect from $endpointId ...');
    } catch (e) {
      _appendLog(ref, 'Error Disconnect: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyProvider);
    final logText = ref.watch(logProvider);
    final controller = ref.read(nearbyProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby File Transfer Demo')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // モード切り替え・接続状態
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: state.isAdvertising
                      ? controller.stopAdvertising
                      : controller.startAdvertising,
                  child: Text(
                    state.isAdvertising
                        ? 'Stop Advertising'
                        : 'Start Advertising',
                  ),
                ),
                ElevatedButton(
                  onPressed: state.isDiscovering
                      ? controller.stopDiscovery
                      : controller.startDiscovery,
                  child: Text(
                    state.isDiscovering ? 'Stop Discovery' : 'Start Discovery',
                  ),
                ),
              ],
            ),
            Column(
              children: state.endpoints
                  .map(
                    (e) => Row(
                      children: [
                        Text('EndpointID : $e'),
                        const SizedBox(width: 16),
                        // 送信ボタン
                        ElevatedButton.icon(
                          onPressed: () => _sendFile(ref, e),
                          icon: const Icon(Icons.send),
                          label: Text('Send to $e'),
                        ),
                        const SizedBox(width: 16),
                        // 切断ボタン
                        ElevatedButton.icon(
                          onPressed: () => _disconnect(ref, e),
                          icon: const Icon(Icons.close),
                          label: Text('Disconnect from $e'),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),

            state.endpoints.isEmpty
                ? const SizedBox.shrink()
                : ElevatedButton.icon(
                    onPressed: () => _sendFile(ref, null),
                    icon: const Icon(Icons.send),
                    label: Text('Send to All Endpoints'),
                  ),

            const Divider(),
            const Align(alignment: Alignment.centerLeft, child: Text('Log')),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          logText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
