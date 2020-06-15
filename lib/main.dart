import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

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

  showAlertDialog(BuildContext context) {

    // Initializing a global key, as it would help us in showing a SnackBar later
    final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
    // Get the instance of the bluetooth
    FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;

    // Define some variables, which will be required later
    List<BluetoothDevice> _devicesList = [];
    BluetoothDevice _device;
    bool _connected = false;
    bool _pressed = false;

    // We are using async callback for using await
    Future<void> bluetoothConnectionState() async {
      List<BluetoothDevice> devices = [];

      // To get the list of paired devices
      try {
        devices = await bluetooth.getBondedDevices();
      } on PlatformException {
        print("Error");
      }

      // For knowing when bluetooth is connected and when disconnected
      bluetooth.onStateChanged().listen((state) {
        switch (state) {
          case FlutterBluetoothSerial.CONNECTED:
            setState(() {
              _connected = true;
              _pressed = false;
            });

            break;

          case FlutterBluetoothSerial.DISCONNECTED:
            setState(() {
              _connected = false;
              _pressed = false;
            });
            break;

          default:
            print(state);
            break;
        }
      });
      // It is an error to call [setState] unless [mounted] is true.
      if (!mounted) {
        return;
      }

      // Store the [devices] list in the [_devicesList] for accessing
      // the list outside this class
      setState(() {
        _devicesList = devices;
      });
    }

    Future show(
        String message, {
          Duration duration: const Duration(seconds: 3),
        }) async {
      await new Future.delayed(new Duration(milliseconds: 100));
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(
          content: new Text(
            message,
          ),
          duration: duration,
        ),
      );
    }

    // Method to connect to bluetooth
    void _connect() {
      if (_device == null) {
        show('No device selected');
      } else {
        bluetooth.isConnected.then((isConnected) {
          if (!isConnected) {
            bluetooth
                .connect(_device)
                .timeout(Duration(seconds: 10))
                .catchError((error) {
              setState(() => _pressed = false);
            });
            setState(() => _pressed = true);
          }
        });
      }
    }

    // Method to disconnect bluetooth
    void _disconnect() {
      bluetooth.disconnect();
      setState(() => _pressed = true);
    }
    // set up the button
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () => Navigator.pop(context, true),
    );

    List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
      List<DropdownMenuItem<BluetoothDevice>> items = [];
      if (_devicesList.isEmpty) {
        items.add(DropdownMenuItem(
          child: Text('NONE'),
        ));
      } else {
        _devicesList.forEach((device) {
          items.add(DropdownMenuItem(
            child: Text(device.name),
            value: device,
          ));
        });
      }
      return items;
    }

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Peripheriques Bluetooth"),
      content:
      DropdownButton(
        // To be implemented : _getDeviceItems()
        items: _getDeviceItems(),
        onChanged: (value) => setState(() => _device = value),
        value: _device,
      ),
      actions: [
        okButton,
        RaisedButton(
          onPressed:
          // To be implemented : _disconnect and _connect
          _pressed ? null : _connected ? _disconnect : _connect,
          child: Text(_connected ? 'Disconnect' : 'Connect'),
        )],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
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
                      showAlertDialog(context);
                    },
                    child: Center(
                      child: Text(
                        "Connection Bluetooth",
                      ),
                    ),
                  ),
                ),
              ),
              Icon(Icons.home),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FloatingActionButton(
                            onPressed: null,
                            child: Center(child: Icon(Icons.arrow_back)),
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
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: FloatingActionButton(
                              onPressed: null,
                              child: Center(child: Icon(Icons.arrow_downward)),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          FloatingActionButton(
                            onPressed: null,
                            child: Center(child: Icon(Icons.arrow_forward)),
                          )
                        ],
                      ),
                    ],
                  )),
                  Container(
                      
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
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: FloatingActionButton(
                                  onPressed: null,
                                  child: Center(child: Icon(Icons.arrow_downward)),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              FloatingActionButton(
                                onPressed: null,
                                child: Center(child: Icon(Icons.arrow_forward)),
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
