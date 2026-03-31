import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const Strategy strategy = Strategy.P2P_CLUSTER;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nearby File Transfer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isAdvertising = false;
  bool isDiscovering = false;
  String? connectedEndpointId;
  String logText = '';
  bool isSender = false;
  double sendProgress = 0.0;
  double receiveProgress = 0.0;

  DateTime? transferStartTime;
  int totalBytes = 0;

  final Map<int, String> _incomingFileTempPath = {};

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ].request();
  }

  void _appendLog(String msg) {
    setState(() {
      logText += '$msg\n';
    });
  }

  Future<void> _startAdvertising() async {
    try {
      await Nearby().startAdvertising(
        'sender-device',
        strategy,
        onConnectionInitiated: (id, info) {
          _appendLog('onConnectionInitiated from $id (${info.endpointName})');
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: _onPayloadReceived,
            onPayloadTransferUpdate: _onPayloadTransferUpdate,
          );
          setState(() {
            connectedEndpointId = id;
          });
        },
        onConnectionResult: (id, status) {
          _appendLog('onConnectionResult: $id -> $status');
        },
        onDisconnected: (id) {
          _appendLog('onDisconnected: $id');
          setState(() {
            connectedEndpointId = null;
          });
        },
      );
      setState(() {
        isAdvertising = true;
      });
      _appendLog('Advertising started');
    } catch (e) {
      _appendLog('Error startAdvertising: $e');
    }
  }

  Future<void> _stopAdvertising() async {
    await Nearby().stopAdvertising();
    setState(() {
      isAdvertising = false;
    });
    _appendLog('Advertising stopped');
  }

  Future<void> _startDiscovery() async {
    try {
      await Nearby().startDiscovery(
        'receiver-device',
        strategy,
        onEndpointFound: (id, name, serviceId) {
          _appendLog('onEndpointFound: $id ($name)');
          Nearby().requestConnection(
            'receiver-device',
            id,
            onConnectionInitiated: (id, info) {
              _appendLog('onConnectionInitiated (receiver) from $id');
              Nearby().acceptConnection(
                id,
                onPayLoadRecieved: _onPayloadReceived,
                onPayloadTransferUpdate: _onPayloadTransferUpdate,
              );
              setState(() {
                connectedEndpointId = id;
              });
            },
            onConnectionResult: (id, status) {
              _appendLog('onConnectionResult (receiver): $id -> $status');
            },
            onDisconnected: (id) {
              _appendLog('onDisconnected (receiver): $id');
              setState(() {
                connectedEndpointId = null;
              });
            },
          );
        },
        onEndpointLost: (id) {
          _appendLog('onEndpointLost: $id');
        },
      );
      setState(() {
        isDiscovering = true;
      });
      _appendLog('Discovery started');
    } catch (e) {
      _appendLog('Error startDiscovery: $e');
    }
  }

  Future<void> _stopDiscovery() async {
    await Nearby().stopDiscovery();
    setState(() {
      isDiscovering = false;
    });
    _appendLog('Discovery stopped');
  }

  Future<void> _sendFile() async {
    if (connectedEndpointId == null) {
      _appendLog('No connected endpoint');
      return;
    }

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) {
      _appendLog('File picking cancelled');
      return;
    }

    final file = File(result.files.single.path!);
    _appendLog('Selected file: ${file.path}');

    try {
      // final payload = Payload.fromFile(file);
      // await Nearby().sendPayload(connectedEndpointId!, payload);
      var payloadId = await Nearby().sendFilePayload(
        connectedEndpointId!,
        file.path,
      );
      _appendLog('Sending file payloadId=$payloadId');

      setState(() {
        isSender = true;
      });
    } catch (e) {
      _appendLog('Error sendPayload: $e');
    }
  }

  void _onPayloadReceived(String endpointId, Payload payload) async {
    if (payload.type == PayloadType.FILE) {
      final tempPath = payload.filePath!;
      _appendLog(
        'File payload received (temp): id=${payload.id}, path=$tempPath',
      );
      _incomingFileTempPath[payload.id] = tempPath;
    } else if (payload.type == PayloadType.BYTES) {
      final data = String.fromCharCodes(payload.bytes!);
      _appendLog('Bytes payload received: $data');
    }
  }

  void _onPayloadTransferUpdate(
    String endpointId,
    PayloadTransferUpdate update,
  ) async {
    final progress = update.totalBytes == 0
        ? 0.0
        : update.bytesTransferred / update.totalBytes;

    if (update.status == PayloadStatus.IN_PROGRESS) {
      // 送信側・受信側どちらでも同じコールバックが来るので、
      // とりあえず両方に反映している
      setState(() {
        if (isSender) {
          sendProgress = progress;
        } else {
          receiveProgress = progress;
        }

        if (transferStartTime == null) {
          transferStartTime = DateTime.now();
          totalBytes = update.totalBytes;
        }
      });
    }

    if (update.status == PayloadStatus.SUCCESS) {
      final end = DateTime.now();
      final duration = end.difference(transferStartTime!);
      final seconds = duration.inMilliseconds / 1000;

      final mb = totalBytes / (1024 * 1024);
      final speed = mb / seconds; // MB/s

      _appendLog(
        'Payload SUCCESS: id=${update.id} File size: $totalBytes bytes, Time: ${seconds.toStringAsFixed(2)}s, Speed: ${speed.toStringAsFixed(2)} MB/s',
      );
      setState(() {
        isSender = false;
        sendProgress = 0.0;
        receiveProgress = 0.0;
        transferStartTime = null;
      });

      // FilePayload の場合、temp ファイルを正式な場所に移動
      if (_incomingFileTempPath.containsKey(update.id)) {
        final tempPath = _incomingFileTempPath[update.id]!;
        final dir = await getApplicationDocumentsDirectory();
        final newPath = '${dir.path}/received_${update.id}.bin';
        final file = File(tempPath);
        await file.rename(newPath);
        _appendLog('File saved: $newPath');
        _incomingFileTempPath.remove(update.id);
      }
    }

    if (update.status == PayloadStatus.FAILURE) {
      _appendLog('Payload FAILURE: id=${update.id}');
      setState(() {
        sendProgress = 0.0;
        receiveProgress = 0.0;
      });
    }
  }

  @override
  void dispose() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = connectedEndpointId != null;

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
                  onPressed: isAdvertising
                      ? _stopAdvertising
                      : _startAdvertising,
                  child: Text(
                    isAdvertising ? 'Stop Advertising' : 'Start Advertising',
                  ),
                ),
                ElevatedButton(
                  onPressed: isDiscovering ? _stopDiscovery : _startDiscovery,
                  child: Text(
                    isDiscovering ? 'Stop Discovery' : 'Start Discovery',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Connected endpoint: ${connectedEndpointId ?? "None"}'),

            const SizedBox(height: 16),
            // 送信ボタン
            ElevatedButton.icon(
              onPressed: isConnected ? _sendFile : null,
              icon: const Icon(Icons.send),
              label: const Text('Send File'),
            ),

            const SizedBox(height: 16),
            // 送信進捗
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Send Progress'),
                LinearProgressIndicator(value: sendProgress, minHeight: 6),
                const SizedBox(height: 8),
                const Text('Receive Progress'),
                LinearProgressIndicator(value: receiveProgress, minHeight: 6),
              ],
            ),

            const SizedBox(height: 16),
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
