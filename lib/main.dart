import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lxnav_bluetooth/app/common_widgets.dart';
import 'package:lxnav_bluetooth/app/permission_utils.dart';
import 'package:lxnav_bluetooth/lxnav/bloc/lxnav_data_state.dart';
import 'package:lxnav_bluetooth/lxnav/ui/lxnav_logbook.dart';
import 'package:permission_handler/permission_handler.dart';
import 'lxnav/bloc/lxnav_cubit.dart';
import 'lxnav/ui/lxnav_device_widget.dart';

void main() => runApp(LxNav());

class LxNav extends StatelessWidget {
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
    with TickerProviderStateMixin {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late TabController _tabController;
  bool _displayAllTabs = false;

  static final List<String> TAB_NAMES = [
    "MAIN",
    "PILOT",
    "LOGBOOK",
    "TASK",
    "SETTINGS"
  ];
  final List<Tab> _tabLabels = [Tab(text: TAB_NAMES[0])]; // always present
  final List<Widget> _tabWidgets = [
    Center(child: LxNavDeviceWidget())
  ]; // always present
  int selectedTabIndex = 0;

  @override
  void initState() {
    _tabController = TabController(
        length: _tabWidgets.length,
        vsync: this,
        initialIndex: selectedTabIndex);
    debugPrint("main.initState. _tabWidgets.length : ${_tabWidgets.length} "
        "_tabs.length : ${_tabLabels.length} ");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getAppBar(),
        body: _getBody(),
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
      bottom: _getTabBar(),
    );
  }

  TabBar _getTabBar() {
    debugPrint(
        "main._getTabBar. _tabController.length:  ${_tabController.length}");
    return TabBar(
      isScrollable: true,
      controller: _tabController,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
      tabs: _tabLabels,
    );
  }

  Widget _getBody() {
    debugPrint(
        "main._getBody() creating TabBarView. _tabController.length:  ${_tabController.length}");
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            // key: Key(Random().nextDouble().toString()), // to prevent crash when # tabs changes
            physics: AlwaysScrollableScrollPhysics(),
           controller: _tabController,
            children: _tabWidgets,
          ),
        ),
        _getConnectionListener(),
        _widgetForErrorMessages(),
      ],
    );
  }

  void _updateTabBarLabelsAndWidgets() {
    if (_tabLabels.length > 1) {
      _tabLabels.removeRange(1, _tabLabels.length);
    }
    if (_tabWidgets.length > 1) {
      // never remove first tab widget
      _tabWidgets.removeRange(1, _tabWidgets.length);
    }
    if (_displayAllTabs) {
      for (var i = 1; i < TAB_NAMES.length; ++i) {
        _tabLabels.add(Tab(
          text: TAB_NAMES[i],
          //child: GestureDetector(onTap: () => _tabController.animateTo(i)))
        ));
      }
      // TODO - replace with real widgets when you get there
      _tabWidgets.add(Center(
        child: Text(TAB_NAMES[1]),
      ));
      _tabWidgets.add(Center(
        child: LxNavLogbook(),
      ));
      _tabWidgets.add(Center(
        child: Text(TAB_NAMES[3]),
      ));
      _tabWidgets.add(Center(
        child: Text(TAB_NAMES[4]),
      ));
    }
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
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
          icon: Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (BuildContext bc) {
            return [
              PopupMenuItem(
                child: Text("App Settings"),
                value: "Settings",
                onTap: openAppSettingsFunction,
              ),
              PopupMenuItem(
                child: Text("Device Settings"),
                value: "Settings",
                onTap: openDeviceSettingsFunction,
              )
            ];
          }),
    ];
  }

  Widget _widgetForErrorMessages() {
    return BlocConsumer<LxNavCubit, LxNavDataState>(listener: (context, state) {
      if (state is LxNavErrorState) {
        CommonWidgets.showErrorDialog(context, "UH-OH", state.errorMsg);
      }
    }, builder: (context, state) {
      if (state is LxNavErrorState) {
        return SizedBox.shrink();
      } else {
        return SizedBox.shrink();
      }
    });
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

  Future<void> openDeviceSettingsFunction() async {
    try {
      await AppSettings.openAppSettings(
          type: AppSettingsType.bluetooth, asAnotherTask: true);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget _getConnectionListener() {
    return BlocListener<LxNavCubit, LxNavDataState>(
      listener: (context, state) {
        if (state is LxNavPairedDevicesState) {
          if (state.connectedDevice != null &&
              state.connectedDevice!.isConnected) {
            _displayAllTabs = true;
          } else {
            _displayAllTabs = false;
          }
        }
        if (state is LxNavDeviceConnectedState) {
          if (state.connectedDevice != null &&
              state.connectedDevice!.isConnected) {
            _displayAllTabs = true;
          } else {
            _displayAllTabs = false;
          }
        }
        if (state is LxNavPairedDevicesState ||
            state is LxNavDeviceConnectedState) {
          _updateTabController();
        }
      },
      child: SizedBox.shrink(),
    );
  }

  void _updateTabController() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _updateTabBarLabelsAndWidgets();
        debugPrint(
            "main._updateTabController. updating tab labels and tab widget");
        _tabController.dispose();
        try {
          _tabController = TabController(
            length: _tabWidgets.length,
            vsync: this,
            initialIndex: selectedTabIndex,
          );
          debugPrint(
              "main._updateTabController. _tabWidgets.length : ${_tabWidgets.length} "
              "_tabs.length : ${_tabLabels.length} ");
        } catch (e) {
          debugPrint(e.toString());
        }
        //_redrawKey = GlobalKey();
      });
    });
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
