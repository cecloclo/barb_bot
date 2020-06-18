import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue/flutter_blue.dart';

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

  //We're making these three things global so that we-
//can check the state and device later in this class
  BluetoothDevice device;
  BluetoothState state;
  BluetoothDeviceState deviceState;

  //get okButton => null;

  get child => null;
  ///Initialisation and listening to device state
  @override
  void initState() {
    super.initState();
//checks bluetooth current state
    FlutterBlue.instance.state.listen((state) {
      if (state == BluetoothState.off) {
//Alert user to turn on bluetooth.
      } else if (state == BluetoothState.on) {
//if bluetooth is enabled then go ahead.
//Make sure user's device gps is on.
        scanForDevices();
      }
    });
  }

  var scanSubscription;
  ///// **** Scan and Stop Bluetooth Methods  ***** /////
  void scanForDevices() async {
    scanSubscription = FlutterBlue.instance.scan().listen((scanResult) async {
      if (scanResult.device.name == "your_device_name") {
        print("found device");
//Assigning bluetooth device
        device = scanResult.device;
//After that we stop the scanning for device
        stopScanning();
      }
    });
  }
  void stopScanning() {
    FlutterBlue.instance.stopScan();
    scanSubscription.cancel();
  }

  ///// ******* Bluetooth device Handling Methods ******** //////
  connectToDevice() async {
//flutter_blue makes our life easier
    await device.connect();
//After connection start dicovering services
    discoverServices();
  }

  // ADD YOUR OWN SERVICES & CHAR UUID, EACH DEVICE HAS DIFFERENT UUID
// device Proprietary characteristics of the ISSC service
  static const ISSC_PROPRIETARY_SERVICE_UUID = "35111C0000110100001000800000805F9B34FB";
//device char for ISSC characteristics
  static const UUIDSTR_ISSC_TRANS_TX = "35111C0000110100001000800000805F9B34FB";
  static const UUIDSTR_ISSC_TRANS_RX = "35111C0000110100001000800000805F9B34FB";
// This characteristic to send command to device
  BluetoothCharacteristic c;
//This stream is for taking characteristic's value
//for reading data provided by device
  Stream<List<int>> listStream;
  discoverServices() async {
    List<BluetoothService> services = await device.discoverServices();
//checking each services provided by device
    services.forEach((service) {
      if (service.uuid.toString() == ISSC_PROPRIETARY_SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == UUIDSTR_ISSC_TRANS_RX) {
//Updating characteristic to perform write operation.
            c = characteristic;
          } else if (characteristic.uuid.toString() == UUIDSTR_ISSC_TRANS_TX) {
//Updating stream to perform read operation.
            listStream = characteristic.value;
            characteristic.setNotifyValue(!characteristic.isNotifying);
          }
        });
      }
    });
  }

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

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

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
              Center(
                child: SizedBox(
                  width: 150.0,
                  height: 150.0,
                  child: FloatingActionButton(
                    onPressed: () {
                      connectToDevice();
                      showAlertDialog(context);
                    },
                    child: Center(
                      child: Text(
                        "Connection Bluetooth",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row( children: [
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
                      Row( children: [
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
                                  if (_currentPosition != null) Text(_currentAddress),
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
                              child: Center(child: Icon(Icons.arrow_upward)),
                              backgroundColor: Colors.blueGrey,
                              focusColor: Colors.black26,

                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: FloatingActionButton(
                              onPressed: null,
                              child: Center(child: Icon(Icons.arrow_downward)),
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
                                  child: Center(child: Icon(Icons.arrow_upward)),
                                  backgroundColor: Colors.red,
                                  focusColor: Colors.black26,

                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: FloatingActionButton(
                                  onPressed: null,
                                  child: Center(child: Icon(Icons.arrow_downward)),
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

showManualControlMode(BuildContext context) {}

/* Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    Align(
      alignment: Alignment.centerLeft,
    );
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title), centerTitle: true,
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child : TabBar({)
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          children: <Widget>[
            Image.asset('assets/Image/safe.png', height: 80, width: 80,),
            Text('Volume eau'),
            SizedBox(
                width: 100.0,
                height: 100.0,
                child: FloatingActionButton(
                  onPressed: () {
                    showAlertDialog(context);
                  },
                  child: Text(
                    "Connection Bluetooth",
                  ),
                )
            ),
          SizedBox(
          width: 100.0,
          height: 100.0,
          child: FloatingActionButton(
              onPressed: () {

              },
              child: Text(
                "Mode Manuel",
              ),
            )
          ),
          ]
        ),
      ),
    );
  }
*/
