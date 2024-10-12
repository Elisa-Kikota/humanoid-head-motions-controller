import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class SelectBondedDevicePage extends StatefulWidget {
  final bool checkAvailability;
  final Function onChatPage;

  const SelectBondedDevicePage({
    this.checkAvailability = true,
    required this.onChatPage,
  });

  @override
  _SelectBondedDevicePageState createState() => _SelectBondedDevicePageState();
}

class _SelectBondedDevicePageState extends State<SelectBondedDevicePage> {
  List<BluetoothDevice> devices = [];
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() {
    setState(() {
      _isDiscovering = true;
      devices.clear();
    });

    FlutterBluetoothSerial.instance.getBondedDevices().then((bondedDevices) {
      setState(() {
        devices = bondedDevices;
        _isDiscovering = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: devices
                .map(
                  (device) => ListTile(
                    title: Text(device.name ?? "Unknown device"),
                    subtitle: Text(device.address.toString()),
                    trailing: ElevatedButton(
                      child: Text('Connect'),
                      onPressed: () => widget.onChatPage(device),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (_isDiscovering)
          Center(
            child: CircularProgressIndicator(),
          ),
        ElevatedButton(
          child: Text('Refresh'),
          onPressed: _startDiscovery,
        ),
      ],
    );
  }
}