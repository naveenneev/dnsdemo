import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:screencoach/core/services/firebase/cloud_service.dart';
import 'package:screencoach/core/model/dnsmodel.dart';
import 'package:screencoach/vpn.dart';

import 'core/utils/connectivity_manager.dart';
import 'core/utils/storage_util.dart';
import 'mobx/dnslist.dart';

final dnsList = DNSList();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageUtil.getInstance();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DNS DEMO',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'List of available DNS'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}







class _MyHomePageState extends State<MyHomePage> {

  Map _source = {ConnectivityResult.none: false};
  MyConnectivity _connectivity = MyConnectivity.instance;

  int selectedIndex = 0;
  TextEditingController _textFieldController = TextEditingController();
  String codeDialog;
  String valueText;
  String currentDns;

  @override
  void initState() {
    currentDns = StorageUtil.getString('currentDns');
    _connectivity.initialise();
    _connectivity.myStream.listen((source) {
      setState(() => _source = source);
    });
    super.initState();
  }

  @override
  void dispose() {
    _connectivity.disposeStream();
    super.dispose();
  }

   _displayTextInputDialog(BuildContext context) {
    _textFieldController.text = "";
    valueText = "";
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter New DNS'),
            content: TextField(
              onChanged: (value) {
                valueText = value;
              },
              controller: _textFieldController,
              decoration: InputDecoration(hintText: "0.0.0.0"),
            ),
            actions: <Widget>[
              FlatButton(
                color: Colors.red,
                textColor: Colors.white,
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              FlatButton(
                color: Colors.green,
                textColor: Colors.white,
                child: Text('OK'),
                onPressed: () {
                  codeDialog = valueText;
                  print("The text is : ${valueText}");
                  Navigator.pop(context);
                  saveNewDNSToCloud();
                },
              ),
            ],
          );
        });
  }

  saveNewDNSToCloud ()
  {
     FirebaseAPIService().addDNS({"address" : valueText}).then((value) => {
       setState((){})
     });
  }

  bool isCurrentDnsServer(String dns) {
     if(currentDns == '') {
       return false;
     } else {
       if (dns == currentDns) {
         return true;
       } else {
         return false;
       }
     }
  }

  Widget getListBuilderForData(List<DNSModel> data)
  {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (BuildContext ctx, index) {
        return Card(
            margin: EdgeInsets.all(10),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: index + 1 == selectedIndex ? Colors.white : Colors.white,
            child: ListTile(
              onTap: (){
                StorageUtil.putString('currentDns', data[index].address);
                setState(() {
                  selectedIndex = index + 1;
                  try {
                    VPN.startVpn(data[index].address);
                  } on PlatformException catch (e) {
                    "Failed to Invoke: '${e.message}'.";
                  }
                  currentDns = StorageUtil.getString('currentDns');
                });
              },
              leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(index.toString())),
              trailing: Visibility(
                  visible: isCurrentDnsServer(data[index].address),
                  child: Image.asset('assets/images/connected.png', height: 25, width: 25,)
              ),
              title: Text(data[index].address),
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {

   switch (_source.keys.toList()[0]) {
      case ConnectivityResult.none:
        break;
      case ConnectivityResult.mobile:
          VPN.startVpn(currentDns);
        break;
      case ConnectivityResult.wifi:
          VPN.startVpn(currentDns);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Observer(
        builder: (_) => getListBuilderForData(dnsList.dnsList),
      ),
      // FutureBuilder<List<DNSModel>>(
      //   future:  FirebaseAPIService().fetchDNSList(), // async work
      //   builder: (BuildContext context, AsyncSnapshot<List<DNSModel>> snapshot) {
      //     switch (snapshot.connectionState)
      //     {
      //       case ConnectionState.waiting: return Text('Loading....');
      //       default:
      //         if (snapshot.hasError)
      //           return Text('Error: ${snapshot.error}');
      //         else
      //           return getListBuilderForData(snapshot.data);
      //     }
      //   },
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
              onPressed: (){
                dnsList.fetchDNSList();
              },
              child: Icon(Icons.refresh),
            ),
            FloatingActionButton(
              onPressed: (){
                _displayTextInputDialog(context);
              },
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
