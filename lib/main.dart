import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';
import 'dart:async';

import './DiscoveryPage.dart';
import './ChatPage.dart';
import './SelectBoundedDevicePage.dart';
import './BackgroundCollectingTask.dart';
import './BackgroundCollectPage.dart';

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

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // The home page of your application.
  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  //Main page
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask _collectingTask;

  bool _autoAcceptPairingRequests = false;

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
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }

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

  //BackgroundCollect
  showAlertDialog(BuildContext context) {
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
        title: Text("Bluetooth"),
        content: Text("Connexion"),
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
                            _startChat(context, selectedDevice);
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
                                onPressed: null,
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
                                  onPressed: null,
                                  child: Center(
                                      child: Icon(Icons.arrow_upward)),
                                  backgroundColor: Colors.blueGrey,
                                  focusColor: Colors.black26,

                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: FloatingActionButton(
                                  onPressed: null,
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
                                onPressed: null,
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
                                onPressed: null,
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
                                  onPressed: null,
                                  child: Center(
                                      child: Icon(Icons.arrow_upward)),
                                  backgroundColor: Colors.red,
                                  focusColor: Colors.black26,

                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: FloatingActionButton(
                                  onPressed: null,
                                  child: Center(
                                      child: Icon(Icons.arrow_downward)),
                                  backgroundColor: Colors.red,
                                  focusColor: Colors.black26,

                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              FloatingActionButton(
                                onPressed: null,
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
                          onPressed: null,
                          child: Center(child: Text("EAU")),
                        ),
                        FloatingActionButton(
                          onPressed: null,
                          backgroundColor: Colors.red,
                          child: Center(child: Icon(Icons.volume_up),),
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