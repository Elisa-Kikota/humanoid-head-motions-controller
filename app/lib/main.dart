import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SelectBondedDevicePage.dart';
import 'RobotControlPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Head Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkPreviousConnection();
  }

  void _checkPreviousConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedAddress = prefs.getString('last_connected_device');

    if (savedAddress != null) {
      final BluetoothDevice device = BluetoothDevice(
        address: savedAddress,
        name: prefs.getString('last_connected_device_name') ?? 'Unknown Device',
      );
      _navigateToControlPage(device);
    } else {
      _navigateToDeviceSelection();
    }
  }

  void _navigateToDeviceSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SelectBondedDevicePage(
          onDeviceSelected: (device) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_connected_device', device.address);
            await prefs.setString('last_connected_device_name', device.name ?? 'Unknown Device');
            _navigateToControlPage(device);
          },
        ),
      ),
    );
  }

  void _navigateToControlPage(BluetoothDevice device) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => RobotControlPage(
          server: device,
          onDisconnect: () => _navigateToDeviceSelection(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}