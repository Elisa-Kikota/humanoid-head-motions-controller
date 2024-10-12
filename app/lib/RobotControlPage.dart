import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class RobotControlPage extends StatefulWidget {
  final BluetoothDevice server;

  const RobotControlPage({Key? key, required this.server}) : super(key: key);

  @override
  _RobotControlPageState createState() => _RobotControlPageState();
}

class _RobotControlPageState extends State<RobotControlPage> with SingleTickerProviderStateMixin {
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;

  bool _underRaspberryPi = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  double _lateralPosition = 90;
  double _eyeVerticalPosition = 90;
  double _eyeHorizontalPosition = 90;
  double _noddingPosition = 90;
  double _jawPosition = 90;

  Color _currentColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _connectToDevice();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }
    super.dispose();
  }

  void _connectToDevice() {
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });
    }).catchError((error) {
      print('Cannot connect, exception occurred');
      print(error);
    });
  }

  void _sendCommand(String command) {
    if (isConnected) {
      try {
        print('Sending: $command');
        connection!.output.add(Uint8List.fromList(utf8.encode('$command\n')));
        connection!.output.allSent.then((_) {
          print('Message sent successfully');
        });
      } catch (e) {
        print('Error sending command: $e');
      }
    } else {
      print('Not connected to any device');
    }
  }

  void _toggleControl() {
    setState(() {
      _underRaspberryPi = !_underRaspberryPi;
      if (_underRaspberryPi) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    _sendCommand('TOGGLE_CONTROL');
  }

  void _resetServos() {
    setState(() {
      _lateralPosition = 90;
      _eyeVerticalPosition = 90;
      _eyeHorizontalPosition = 90;
      _noddingPosition = 90;
      _jawPosition = 90;
    });
    _sendCommand('RESET');
  }

  void _changeColor(Color color) {
    setState(() => _currentColor = color);
    _sendCommand('RGB,${color.red},${color.green},${color.blue}');
  }

  Widget _buildSlider(String label, String command, double value, Function(double) onChanged) {
    return Opacity(
      opacity: _underRaspberryPi ? 0.5 : 1.0,
      child: AbsorbPointer(
        absorbing: _underRaspberryPi,
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 16)),
            Slider(
              value: value,
              min: 0,
              max: 180,
              divisions: 180,
              label: value.round().toString(),
              onChanged: (newValue) {
                setState(() {
                  onChanged(newValue);
                });
                _sendCommand('$command,${newValue.round()}');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Robot Head Control'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetServos,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animation.value * 2 * 3.14159,
                    child: Image.asset('assets/robot_head.png', width: 200, height: 200),
                  );
                },
              ),
              SizedBox(height: 20),
              Text('Connected to: ${widget.server.name ?? "Unknown"}',
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('App Control'),
                  Switch(
                    value: _underRaspberryPi,
                    onChanged: (value) => _toggleControl(),
                  ),
                  Text('RaspberryPi Control'),
                ],
              ),
              SizedBox(height: 20),
              _buildSlider('Lateral', 'L', _lateralPosition, (value) => _lateralPosition = value),
              _buildSlider('Eye Vertical', 'V', _eyeVerticalPosition, (value) => _eyeVerticalPosition = value),
              _buildSlider('Eye Horizontal', 'H', _eyeHorizontalPosition, (value) => _eyeHorizontalPosition = value),
              _buildSlider('Nodding', 'N', _noddingPosition, (value) => _noddingPosition = value),
              _buildSlider('Jaw', 'J', _jawPosition, (value) => _jawPosition = value),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Change LED Color'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Pick a color'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: _currentColor,
                            onColorChanged: _changeColor,
                            showLabel: true,
                            pickerAreaHeightPercent: 0.8,
                          ),
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            child: const Text('Done'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}