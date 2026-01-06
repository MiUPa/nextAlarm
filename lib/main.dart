import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Notifier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LocationNotifierHome(),
    );
  }
}

class LocationNotifierHome extends StatefulWidget {
  const LocationNotifierHome({super.key});

  @override
  State<LocationNotifierHome> createState() => _LocationNotifierHomeState();
}

class _LocationNotifierHomeState extends State<LocationNotifierHome> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // デフォルトエリア（東京タワー付近）
  double targetLatitude = 35.6586;
  double targetLongitude = 139.7454;
  double targetRadius = 100.0; // meters

  // シミュレート用の位置情報
  double? simulatedLatitude;
  double? simulatedLongitude;
  bool useSimulation = false;

  Position? currentPosition;
  bool isMonitoring = false;
  Timer? locationTimer;
  bool hasShownNotification = false;
  bool isInsideArea = false;

  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();
  final TextEditingController radiusController = TextEditingController();
  final TextEditingController simLatController = TextEditingController();
  final TextEditingController simLngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initializeControllers();
  }

  void _initializeControllers() {
    latController.text = targetLatitude.toString();
    lngController.text = targetLongitude.toString();
    radiusController.text = targetRadius.toString();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request notification permission
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'location_channel',
      'Location Notifications',
      channelDescription: 'Notifications for entering designated areas',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'エリア通知',
      '指定されたエリアに入りました！',
      platformChannelSpecifics,
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // 2 * R; R = 6371 km, result in meters
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied) {
      _showSnackBar('位置情報パーミッションが必要です');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (useSimulation && simulatedLatitude != null && simulatedLongitude != null) {
        setState(() {
          currentPosition = Position(
            latitude: simulatedLatitude!,
            longitude: simulatedLongitude!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        });
        _checkGeofence();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPosition = position;
      });
      _checkGeofence();
    } catch (e) {
      _showSnackBar('位置情報の取得に失敗しました: $e');
    }
  }

  void _checkGeofence() {
    if (currentPosition == null) return;

    final distance = _calculateDistance(
      currentPosition!.latitude,
      currentPosition!.longitude,
      targetLatitude,
      targetLongitude,
    );

    final wasInside = isInsideArea;
    isInsideArea = distance <= targetRadius;

    if (isInsideArea && !wasInside) {
      _showNotification();
      hasShownNotification = true;
    }

    setState(() {});
  }

  void _startMonitoring() async {
    await _requestLocationPermission();

    setState(() {
      isMonitoring = true;
      hasShownNotification = false;
    });

    // 初回チェック
    await _getCurrentLocation();

    // 5秒ごとに位置情報をチェック
    locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _getCurrentLocation();
    });

    _showSnackBar('モニタリングを開始しました');
  }

  void _stopMonitoring() {
    locationTimer?.cancel();
    setState(() {
      isMonitoring = false;
      hasShownNotification = false;
      isInsideArea = false;
    });
    _showSnackBar('モニタリングを停止しました');
  }

  void _updateTargetLocation() {
    final lat = double.tryParse(latController.text);
    final lng = double.tryParse(lngController.text);
    final radius = double.tryParse(radiusController.text);

    if (lat == null || lng == null || radius == null) {
      _showSnackBar('正しい数値を入力してください');
      return;
    }

    setState(() {
      targetLatitude = lat;
      targetLongitude = lng;
      targetRadius = radius;
      hasShownNotification = false;
      isInsideArea = false;
    });

    _showSnackBar('エリアを更新しました');
  }

  void _setSimulatedLocation() {
    final lat = double.tryParse(simLatController.text);
    final lng = double.tryParse(simLngController.text);

    if (lat == null || lng == null) {
      _showSnackBar('正しい数値を入力してください');
      return;
    }

    setState(() {
      simulatedLatitude = lat;
      simulatedLongitude = lng;
      useSimulation = true;
    });

    _showSnackBar('シミュレート位置を設定しました');

    if (isMonitoring) {
      _getCurrentLocation();
    }
  }

  void _clearSimulation() {
    setState(() {
      simulatedLatitude = null;
      simulatedLongitude = null;
      useSimulation = false;
    });
    simLatController.clear();
    simLngController.clear();
    _showSnackBar('シミュレートを解除しました');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    latController.dispose();
    lngController.dispose();
    radiusController.dispose();
    simLatController.dispose();
    simLngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distance = currentPosition != null
        ? _calculateDistance(
            currentPosition!.latitude,
            currentPosition!.longitude,
            targetLatitude,
            targetLongitude,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Location Notifier'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'エリア設定',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: latController,
                      decoration: const InputDecoration(
                        labelText: '緯度',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: lngController,
                      decoration: const InputDecoration(
                        labelText: '経度',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: radiusController,
                      decoration: const InputDecoration(
                        labelText: '半径 (メートル)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _updateTargetLocation,
                      child: const Text('エリアを更新'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: useSimulation ? Colors.amber.shade50 : null,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '位置情報シミュレート',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (useSimulation)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ON',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: simLatController,
                      decoration: const InputDecoration(
                        labelText: 'シミュレート緯度',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: simLngController,
                      decoration: const InputDecoration(
                        labelText: 'シミュレート経度',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _setSimulatedLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                            ),
                            child: const Text('シミュレート開始'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearSimulation,
                            child: const Text('シミュレート解除'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '現在の状態',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('モニタリング', isMonitoring ? '実行中' : '停止中'),
                    if (currentPosition != null) ...[
                      _buildInfoRow('現在の緯度', currentPosition!.latitude.toStringAsFixed(6)),
                      _buildInfoRow('現在の経度', currentPosition!.longitude.toStringAsFixed(6)),
                    ],
                    if (distance != null)
                      _buildInfoRow('目的地までの距離', '${distance.toStringAsFixed(1)} m'),
                    _buildInfoRow(
                      'エリア内',
                      isInsideArea ? '✅ はい' : '❌ いいえ',
                      color: isInsideArea ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isMonitoring ? _stopMonitoring : _startMonitoring,
              style: ElevatedButton.styleFrom(
                backgroundColor: isMonitoring ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isMonitoring ? 'モニタリングを停止' : 'モニタリングを開始',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}
