import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'audio_engine.dart';
import 'payment_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walkie-Talkie',
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFFFFD700), // gold
        hintColor: Color(0xFFFFD700),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String userName = 'User${DateTime.now().millisecondsSinceEpoch}';
  final Strategy strategy = Strategy.P2P_STAR;
  AudioEngine audioEngine = AudioEngine();
  String? currentEndpointId;

  @override
  void initState() {
    super.initState();
    audioEngine.init();
    _showPermissionDialog();
  }

  @override
  void dispose() {
    audioEngine.dispose();
    super.dispose();
  }

  void _showPermissionDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Permissions Required'),
            content: Text(
              'This app requires Bluetooth, Location, and Microphone permissions to enable offline walkie-talkie communication. Please grant these permissions to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _requestPermissions();
                },
                child: Text('Grant Permissions'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.microphone,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permissions Denied'),
          content: Text(
            'Some permissions are required for the app to function. Please go to settings and enable them.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: Text('Open Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _startAdvertising() async {
    try {
      bool a = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            setState(() {
              currentEndpointId = id;
            });
          }
        },
        onDisconnected: (id) {
          setState(() {
            if (currentEndpointId == id) {
              currentEndpointId = null;
            }
          });
        },
      );
    } catch (exception) {
      // handle
    }
  }

  void _startDiscovery() async {
    try {
      bool a = await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(userName, id, strategy);
        },
        onEndpointLost: (id) {
          // lost
        },
      );
    } catch (exception) {
      // handle
    }
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    // accept connection
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) {
        // receive audio data
        if (payload.type == PayloadType.BYTES) {
          audioEngine.playAudioChunk(payload.bytes!);
        }
      },
    );
  }

  void _sendAudio(Uint8List audioData) {
    if (currentEndpointId != null) {
      Nearby().sendBytesPayload(currentEndpointId!, audioData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Walkie-Talkie'),
        actions: [
          IconButton(
            icon: Icon(Icons.payment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startAdvertising,
              child: Text('Start Advertising'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
            ),
            ElevatedButton(
              onPressed: _startDiscovery,
              child: Text('Start Discovery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
            ),
            GestureDetector(
              onLongPressStart: (details) {
                audioEngine.startRecording(_sendAudio);
              },
              onLongPressEnd: (details) {
                audioEngine.stopRecording();
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'Hold to Talk',
                    style: TextStyle(color: Colors.black),
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