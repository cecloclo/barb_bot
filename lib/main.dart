import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import './DiscoveryPage.dart';
//import './ChatPage.dart';
import './SelectBoundedDevicePage.dart';
import './BackgroundCollectingTask.dart';
//import './BackgroundCollectPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'BARBOT : le robot pompier'),
    );
  }
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.server}) : super(key: key);

  // The home page of your application.
  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  final BluetoothDevice server;
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  //Connexion Bluetooth
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask _collectingTask;

  bool _autoAcceptPairingRequests = false;

  static final clientID = 0;
  BluetoothConnection connection;

  List<_Message> messages = List<_Message>();
  String _messageBuffer = '';

  final TextEditingController textEditingController =
  new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    super.dispose();
  }

  /*void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }*/

  Future<void> _startBackgroundTask(
      BuildContext context,
      BluetoothDevice server,
      ) async {
    try {
      _collectingTask = await BackgroundCollectingTask.connect(server);
      await _collectingTask.start();
    } catch (ex) {
      if (_collectingTask != null) {
        _collectingTask.cancel();
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while connecting'),
            content: Text("${ex.toString()}"),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  //Recevoir et transmettre des données

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  Future<void> _sendMessage(String text) async {
    text = text.trim();
    //textEditingController.clear();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  //BackgroundCollect
  showAlertDialog(BuildContext context) {
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
        title: Text("Bluetooth"),
        content: Text("Connecté"),
        actions: [
          FlatButton(
            child: Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ]);

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  //Localisation
  final Geolocator geolocator = Geolocator()
    ..forceAndroidLocationManager;

  Position _currentPosition;
  String _currentAddress;

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
        "${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.bluetooth)),
                Tab(icon: Icon(Icons.home)),
                Tab(icon: Icon(Icons.settings_remote)),
              ],
              unselectedLabelColor: Colors.black38,
              indicatorColor: Colors.white,
            ),
            title: Text('Barbot : Le robot pompier'),
          ),
          body: TabBarView(
            children: [
              Container(
                child: ListView(
                  children: <Widget>[
                    Divider(),
                    ListTile(title: const Text('General')),
                    SwitchListTile(
                      title: const Text('Enable Bluetooth'),
                      value: _bluetoothState.isEnabled,
                      onChanged: (bool value) {
                        // Do the request and update with the true value then
                        future() async {
                          // async lambda seems to not working
                          if (value)
                            await FlutterBluetoothSerial.instance.requestEnable();
                          else
                            await FlutterBluetoothSerial.instance.requestDisable();
                        }

                        future().then((_) {
                          setState(() {});
                        });
                      },
                    ),
                    ListTile(
                      title: const Text('Bluetooth status'),
                      subtitle: Text(_bluetoothState.toString()),
                      trailing: RaisedButton(
                        child: const Text('Settings'),
                        onPressed: () {
                          FlutterBluetoothSerial.instance.openSettings();
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Local adapter address'),
                      subtitle: Text(_address),
                    ),
                    ListTile(
                      title: const Text('Local adapter name'),
                      subtitle: Text(_name),
                      onLongPress: null,
                    ),
                    Divider(),
                    ListTile(title: const Text('Devices discovery and connection')),
                    ListTile(
                      title: RaisedButton(
                          child: const Text('Explore discovered devices'),
                          onPressed: () async {
                            final BluetoothDevice selectedDevice =
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return DiscoveryPage();
                                },
                              ),
                            );

                            if (selectedDevice != null) {
                              print('Discovery -> selected ' + selectedDevice.address);
                            } else {
                              print('Discovery -> no device selected');
                            }
                          }),
                    ),
                    ListTile(
                      title: RaisedButton(
                        child: const Text('Connect to paired device to chat'),
                        onPressed: () async {
                          final BluetoothDevice selectedDevice =
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return SelectBondedDevicePage(checkAvailability: false);
                              },
                            ),
                          );

                          if (selectedDevice != null) {
                            print('Connect -> selected ' + selectedDevice.address);
                            showAlertDialog(context);
                            //_startChat(context, selectedDevice);
                          } else {
                            print('Connect -> no device selected');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(children: [
                      Card(
                        //color: Colors.red,
                        child: Container(
                          width: 170,
                          height: 200,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                    padding: new EdgeInsets.all(15.0),
                                    height: 110.0,
                                    child: Image.asset('assets/Image/safe.png')
                                ),
                                Text("Alerte Feu",
                                    style: TextStyle(
                                      fontSize: 24.0,
                                    )),
                              ]),
                        ),
                      ),
                      Card(
                        //color: Colors.red,
                        child: Container(
                          width: 170,
                          height: 200,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                    padding: new EdgeInsets.all(15.0),
                                    height: 110.0,
                                    child: Image.asset('assets/Image/eau.png')
                                ),
                                Text("Réservoir",
                                    style: TextStyle(
                                      fontSize: 24.0,
                                    )),
                              ]),
                        ),
                      ),
                    ]),
                    Row(children: [
                      Card(
                        //color: Colors.red,
                        child: Container(
                          width: 170,
                          height: 200,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                    padding: new EdgeInsets.all(15.0),
                                    height: 110.0,
                                    child: Image.asset('assets/Image/temp.png')
                                ),
                                Text("Température",
                                    style: TextStyle(
                                      fontSize: 24.0,
                                    )),
                              ]),
                        ),
                      ),
                      Card(
                        //color: Colors.red,
                        child: Container(
                          width: 170,
                          height: 200,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text("Localisation",
                                    style: TextStyle(
                                      fontSize: 24.0,)),
                                if (_currentPosition != null) Text(
                                    _currentAddress),
                                FlatButton(
                                  child: Container(
                                      padding: new EdgeInsets.all(15.0),
                                      height: 110.0,
                                      child: Image.asset('assets/Image/gps.png')
                                  ),
                                  onPressed: () {
                                    _getCurrentLocation();
                                  },
                                ),

                              ]),
                        ),
                      ),
                    ]),
                  ]),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(
                    "CONTROLE LANCE",
                    style: TextStyle(
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,

                    ),
                  ),
                  Container(
                      color: Colors.lightBlue,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              FloatingActionButton(
                                onPressed: () => _sendMessage("SL"),
                                child: Center(child: Icon(Icons.arrow_back)),
                                backgroundColor: Colors.red,
                                focusColor: Colors.black26,
                              )
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: FloatingActionButton(
                                  onPressed: () => _sendMessage("SU"),
                                  child: Center(
                                      child: Icon(Icons.arrow_upward)),
                                  backgroundColor: Colors.blueGrey,
                                  focusColor: Colors.black26,

                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: FloatingActionButton(
                                  onPressed: () => _sendMessage("SD"),
                                  child: Center(
                                      child: Icon(Icons.arrow_downward)),
                                  backgroundColor: Colors.blueGrey,
                                  focusColor: Colors.black26,

                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              FloatingActionButton(
                                onPressed: () => _sendMessage("SR"),
                                child: Center(child: Icon(Icons.arrow_forward)),
                                backgroundColor: Colors.red,
                                focusColor: Colors.black26,

                              )
                            ],
                          ),
                        ],
                      )),
                  Text(
                    "CONTROLE ROBOT",
                    style: TextStyle(
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,

                    ),
                  ),
                  Container(
                      color: Colors.grey,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              FloatingActionButton(
                                onPressed: () => _sendMessage("ML"),
                                child: Center(child: Icon(Icons.arrow_back)),
                                backgroundColor: Colors.blueGrey,
                                focusColor: Colors.black26,

                              )
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: FloatingActionButton(
                                  onPressed: () => _sendMessage("MU"),
                                  child: Center(
                                      child: Icon(Icons.arrow_upward)),
                                  backgroundColor: Colors.red,
                                  focusColor: Colors.black26,

                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: FloatingActionButton(
                                  onPressed: () => _sendMessage("MD"),
                                  child: Center(
                                      child: Icon(Icons.arrow_downward)),
                                  backgroundColor: Colors.grey,
                                  focusColor: Colors.black26,

                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              FloatingActionButton(
                                onPressed: () => _sendMessage("MR"),
                                child: Center(child: Icon(Icons.arrow_forward)),
                                backgroundColor: Colors.blueGrey,
                                focusColor: Colors.black26,

                              )
                            ],
                          ),
                        ],
                      )),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        FloatingActionButton(
                          onPressed: () => _sendMessage("W"),
                          child: Center(child: Text("EAU")),
                        ),
                        FloatingActionButton(
                          onPressed: () => _sendMessage("H"),
                          backgroundColor: Colors.red,
                          child: Center(child: Icon(Icons.volume_up),),
                        ),
                        FloatingActionButton(
                          onPressed: () => _sendMessage("ST"),
                          child: Center(child: Text("START")),
                        ),
                        FloatingActionButton(
                          onPressed: () => _sendMessage("SP"),
                          backgroundColor: Colors.red,
                          child: Center(child: Text("STOP")),
                        )
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}