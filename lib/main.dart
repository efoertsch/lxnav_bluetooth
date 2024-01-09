import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lxnav_bluetooth/app/permission_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'lxnav/bloc/lxnav_cubit.dart';
import 'lxnav/ui/lxnav_bluetooth.dart';

void main() => runApp(LxNav());

class LxNav extends StatefulWidget {
  @override
  State<LxNav> createState() => _LxNavState();
}

class _LxNavState extends State<LxNav> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'LxNav Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: BlocProvider<LxNavCubit>(
          create: (BuildContext context) => LxNavCubit(),
          child: LxNavTabScreen(),
        ));
  }
}

class LxNavTabScreen extends StatefulWidget {
  @override
  _LxNavTabScreenState createState() => _LxNavTabScreenState();
}

class _LxNavTabScreenState extends State<LxNavTabScreen>
    with TickerProviderStateMixin{
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late final TabController _tabController;

  final List<Tab> _tab = [
    Tab(text: 'Connect'),
    Tab(text: 'Pilot'),
    Tab(text: 'Task'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tab.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(),
      body: _getBody(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
  }

  TabBarView _getBody() {
    return TabBarView(
      controller: _tabController,
      children: <Widget>[
        Center(
          child: LxNavBluetooth(),
        ),
        Center(
          child: Text("It's rainy here"),
        ),
        Center(
          child: Text("It's sunny here"),
        ),
      ],
    );
  }

  AppBar getAppBar() {
    return AppBar(
      title: Text(
        "LXNav Bluetooth",
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.blue,
      actions: _getMenu(),
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: <Widget>[
          Tab(
            text: "Connection",
          ),
          Tab(text: "Pilot"),
          Tab(text: "Logbook"),
        ],
      ),
    );
  }

  List<Widget> _getMenu() {
    return <Widget>[
      TextButton(
        child: Text("Refresh",
            style: TextStyle(
              color: Colors.white,
            )),
        onPressed: () async {
          // So, that when new devices are paired
          // while the app is running, user can refresh
          // the paired devices list.
          BlocProvider.of<LxNavCubit>(context).getPairedDeviceList();
        },
      ),
      PopupMenuButton(
          icon: Icon(Icons.more_vert, color:Colors.white),
          itemBuilder: (BuildContext bc) {
            return [
              PopupMenuItem(
                child: Text("Settings"),
                value: "Settings",
                onTap: openAppSettingsFunction,
              )
            ];
          }),
    ];
  }

  void checkForBluetoothConnectPermission() async {
    await checkPermission(
        permission: Permission.bluetoothConnect,
        permissionGrantedFunction: enableBluetooth,
        requestPermissionFunction: openAppSettingsFunction,
        permissionDeniedFunction: openAppSettingsFunction);
  }

  // Request Bluetooth permission from the user
  void enableBluetooth() async {
    BlocProvider.of<LxNavCubit>(context).getPairedDeviceList();
  }

  Future<void> openAppSettingsFunction() async {
    await openAppSettings();
  }

  // Method to show a Snackbar,
  // taking message as the text
  void showSnackbar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: new Text(
          message,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
