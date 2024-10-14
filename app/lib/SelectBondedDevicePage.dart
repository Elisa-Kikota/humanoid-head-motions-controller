import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class SelectBondedDevicePage extends StatefulWidget {
  final Function(BluetoothDevice) onDeviceSelected;

  const SelectBondedDevicePage({Key? key, required this.onDeviceSelected}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Device'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _startDiscovery,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: devices
                  .map(
                    (device) => ListTile(
                      title: Text(device.name ?? "Unknown device"),
                      subtitle: Text(device.address.toString()),
                      onTap: () => widget.onDeviceSelected(device),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (_isDiscovering)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}