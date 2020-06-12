// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

showAlertDialog(BuildContext context) {
  // set up the button
  Widget okButton = FlatButton(
    child: Text("OK"),
    onPressed: () => Navigator.pop(context, true),
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("My title"),
    content: Text("This is my message."),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
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
