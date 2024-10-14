import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class RobotControlPage extends StatefulWidget {
  final BluetoothDevice server;
  final VoidCallback onDisconnect;

  const RobotControlPage({Key? key, required this.server, required this.onDisconnect}) : super(key: key);

  @override
  _RobotControlPageState createState() => _RobotControlPageState();
}

class _RobotControlPageState extends State<RobotControlPage> {
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;

  bool _underAutoControl = false;
  Timer? _heartbeatTimer;
  bool _pongReceived = false;

  double _lateralPosition = 0.5;
  double _eyeVerticalPosition = 0.5;
  double _eyeHorizontalPosition = 0.5;
  double _noddingPosition = 0.5;
  double _jawPosition = 0.5;

  Color _currentColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
    _startHeartbeat();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
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
      _listenForDisconnection();
    }).catchError((error) {
      print('Cannot connect, exception occurred');
      print(error);
    });
  }

  void _listenForDisconnection() {
    connection?.input?.listen(
      (Uint8List data) {
        // Handle incoming data
        _handleIncomingData(utf8.decode(data));
      },
      onDone: () {
        // The connection has been closed
        _handleDisconnection();
      },
      onError: (error) {
        // An error occurred
        print('Error: $error');
        _handleDisconnection();
      },
    );
  }

  void _handleDisconnection() {
    setState(() {
      isConnecting = false;
      connection = null;
    });
    widget.onDisconnect();
  }

  void _attemptReconnection() {
    setState(() {
      isConnecting = true;
    });
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Reconnected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
      });
      _listenForDisconnection();
    }).catchError((error) {
      print('Cannot reconnect, exception occurred');
      setState(() {
        isConnecting = false;
      });
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (isConnected) {
        _sendCommand('PING');
        // Start a timeout timer
        Timer(Duration(seconds: 2), () {
          if (!_pongReceived) {
            // Connection lost
            _handleDisconnection();
          }
        });
      }
    });
  }

  void _handleIncomingData(String data) {
    if (data.trim() == 'PONG') {
      _pongReceived = true;
    }
    // Handle other incoming data
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
      _underAutoControl = !_underAutoControl;
    });
    _sendCommand('TOGGLE_CONTROL');
  }

  void _resetServos() {
    setState(() {
      _lateralPosition = 0.5;
      _eyeVerticalPosition = 0.5;
      _eyeHorizontalPosition = 0.5;
      _noddingPosition = 0.5;
      _jawPosition = 0.5;
    });
    _sendCommand('RESET');
  }

  void _changeColor(Color color) {
    setState(() => _currentColor = color);
    _sendCommand('RGB,${color.red},${color.green},${color.blue}');
  }

  Widget _buildColorButton(Color color, String label) {
    return ElevatedButton(
      child: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () => _changeColor(color),
    );
  }

  Widget _buildControlSlider(String label, String command, double value, Function(double) onChanged, {Widget? leftIcon, Widget? rightIcon}) {
    return Opacity(
      opacity: _underAutoControl ? 0.5 : 1.0,
      child: AbsorbPointer(
        absorbing: _underAutoControl,
        child: Row(
          children: [
            if (leftIcon != null) leftIcon,
            Expanded(
              child: Column(
                children: [
                  Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade900, Colors.blue, Colors.blue.shade900],
                          ),
                        ),
                      ),
                      Positioned(
                        left: value * MediaQuery.of(context).size.width * 0.7,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (rightIcon != null) rightIcon,
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
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetServos,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildConnectionStatus(),
                SizedBox(height: 20),
                Text('Connected to: ${widget.server.name ?? "Unknown"}',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('App Control', style: TextStyle(color: Colors.white)),
                    Switch(
                      value: _underAutoControl,
                      onChanged: (value) => _toggleControl(),
                      activeColor: Colors.blue,
                    ),
                    Text('Auto Control', style: TextStyle(color: Colors.white)),
                  ],
                ),
                SizedBox(height: 20),
                _buildControlSlider('Lateral', 'L', _lateralPosition, (value) {
                  setState(() => _lateralPosition = value);
                  _sendCommand('L,${(value * 180).round()}');
                }, leftIcon: Icon(Icons.arrow_left, color: Colors.white), rightIcon: Icon(Icons.arrow_right, color: Colors.white)),
                SizedBox(height: 10),
                _buildControlSlider('Eye Vertical', 'V', _eyeVerticalPosition, (value) {
                  setState(() => _eyeVerticalPosition = value);
                  _sendCommand('V,${(value * 180).round()}');
                }, leftIcon: Icon(Icons.arrow_upward, color: Colors.white), rightIcon: Icon(Icons.arrow_downward, color: Colors.white)),
                SizedBox(height: 10),
                _buildControlSlider('Eye Horizontal', 'H', _eyeHorizontalPosition, (value) {
                  setState(() => _eyeHorizontalPosition = value);
                  _sendCommand('H,${(value * 180).round()}');
                }, leftIcon: Icon(Icons.arrow_left, color: Colors.white), rightIcon: Icon(Icons.arrow_right, color: Colors.white)),
                SizedBox(height: 10),
                _buildControlSlider('Nodding', 'N', _noddingPosition, (value) {
                  setState(() => _noddingPosition = value);
                  _sendCommand('N,${(value * 180).round()}');
                }),
                SizedBox(height: 10),
                _buildControlSlider('Jaw', 'J', _jawPosition, (value) {
                  setState(() => _jawPosition = value);
                  _sendCommand('J,${(value * 180).round()}');
                }, leftIcon: Icon(Icons.compress, color: Colors.white), rightIcon: Icon(Icons.open_in_full, color: Colors.white)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorButton(Colors.blue, 'Blue'),
                    _buildColorButton(Colors.green, 'Green'),
                    _buildColorButton(Colors.yellow, 'Yellow'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isConnected ? 'Connected' : 'Disconnected',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}