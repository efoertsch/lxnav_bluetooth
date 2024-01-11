import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/common_widgets.dart';
import '../../app/custom_styles.dart';
import '../../app/permission_utils.dart';
import '../bloc/lxnav_cubit.dart';
import '../bloc/lxnav_data_state.dart';


class LxNavWidget extends StatefulWidget {
  @override
  _LxNavWidgetState createState() => _LxNavWidgetState();
}

class _LxNavWidgetState extends State<LxNavWidget>
    with AfterLayoutMixin<LxNavWidget>, AutomaticKeepAliveClientMixin<LxNavWidget> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _btEnabled = false;
  bool _isWorking = false;
  List<BluetoothDevice> _pairedDevices = [];
  BluetoothDevice? _connectedDevice;

  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<LxNavCubit>(context).getBluetoothState();
  }

  @override
  void dispose() {
    //BlocProvider.of<LxNavCubit>(context).dispose();
    super.dispose();
  }

  // Now, its time to build the UI
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            _getEnableBluetoothTextAndSwitch(),
            _getPairedDevicesHeaderText(),
            _getDeviceWidgetRow(),
            _getLxNavInfoWidget(),
            _widgetForErrorMessages(),
          ],
        ),
        _getConnectionProgressIndicator(),
      ],
    );
  }

  Widget _getDeviceWidgetRow() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _getPairedDeviceDropDown(),
            _getConnectionButton(),
          ],
        ),
      ),
    );
  }

  Padding _getPairedDevicesHeaderText() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        "PAIRED DEVICES",
        style: TextStyle(fontSize: 18, color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _getConnectionProgressIndicator() {
    return BlocConsumer<LxNavCubit, LxNavDataState>(listener: (context, state) {
      if (state is LxNavBtIsWorkingState) {
        _isWorking = state.isWorking;
      }
    }, builder: (context, state) {
      return Visibility(
          visible: _isWorking,
          child: Container(
            child: AbsorbPointer(
                absorbing: true,
                child: CircularProgressIndicator(
                  color: Colors.blue,
                )),
            alignment: Alignment.center,
            color: Colors.transparent,
          ));
    });
  }

  Widget _getEnableBluetoothTextAndSwitch() {
    return BlocConsumer<LxNavCubit, LxNavDataState>(listener: (context, state) {
      if (state is LxNavBtEnabledState) {
        _btEnabled = state.btEnabled;
      }
    }, buildWhen: (previous, current) {
      return current is LxNavBtEnabledState;
    }, builder: (context, state) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                'Enable Bluetooth',
                style: textStyleBlackFontSize18,
                ),
              ),
            Switch(
                value: _btEnabled,
                // Add state to determine if bluetooth enabled or not
                onChanged: (bool value) async {
                  if (value) {
                    await BlocProvider.of<LxNavCubit>(context)
                        .enableBluetooth();
                  } else {
                    await BlocProvider.of<LxNavCubit>(context)
                        .disableBluetooth();
                  }
                  setState(() {});
                }),
          ],
        ),
      );
    });
  }

  Widget _getPairedDeviceDropDown() {
    return BlocConsumer<LxNavCubit, LxNavDataState>(listener: (context, state) {
      if (state is LxNavPairedDevicesState) {
        _pairedDevices = state.devices;
        _connectedDevice = state.connectedDevice;
      }
    }, buildWhen: (previous, current) {
      return current is LxNavPairedDevicesState;
    }, builder: (context, state) {
      if (!_btEnabled || _pairedDevices.isEmpty) {
        return Flexible(
          child: (Text('NONE - Is Bluetooth turned on?',
              style:textStyleBlackFontSize18)),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: DropdownButton<BluetoothDevice>(
            items: _pairedDevices.map<DropdownMenuItem<BluetoothDevice>>(
                (BluetoothDevice btDevice) {
              return DropdownMenuItem<BluetoothDevice>(
                value: btDevice,
                child: Text(btDevice.name!),
              );
            }).toList(),
            onChanged: (btDevice) {
              // print("Selected ${btDevice!.name}");
              setState(() {
                _connectedDevice = btDevice;
              });
            },
            value: (_pairedDevices.isNotEmpty && _connectedDevice != null)
                ? _pairedDevices.firstWhere(
                    (device) => device.address == _connectedDevice!.address)
                : (_pairedDevices.isNotEmpty ? _pairedDevices[0] : null),
          ),
        );
      }
    });
  }

  Widget _getConnectionButton() {
    return BlocConsumer<LxNavCubit, LxNavDataState>(listener: (context, state) {
      if (state is LxNavDeviceConnectedState) {
        _connectedDevice = state.connectedDevice;
      }
      if (state is LxNavPairedDevicesState) {
        _connectedDevice = state.connectedDevice;
      }
      if (state is LxNavDeviceConnectedState ||
          state is LxNavPairedDevicesState) {
        debugPrint(
            "_connectedDevice: ${_connectedDevice?.name} connected: ${_connectedDevice?.isConnected}");
      }
    }, buildWhen: (previous, current) {
      return current is LxNavDeviceConnectedState ||
          current is LxNavPairedDevicesState;
    }, builder: (BuildContext context, LxNavDataState state) {
      return Visibility(
        visible: (_connectedDevice != null && _btEnabled),
        child: ElevatedButton(
          onPressed: () {
            _toggleConnection(_connectedDevice);
          },
          child: Text(
            ((_connectedDevice != null && _connectedDevice!.isConnected)
                ? 'Disconnect'
                : 'Connect'),
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
      );
    });
  }

  Widget getRefreshButton() {
    return TextButton.icon(
      icon: Icon(
        Icons.refresh,
        color: Colors.white,
      ),
      label: Text(
        "Refresh",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      )),
      onPressed: () async {
        // So, that when new devices are paired
        // while the app is running, user can refresh
        // the paired devices list.
        BlocProvider.of<LxNavCubit>(context).getPairedDeviceList();
      },
    );
  }

  void getBluetoothState() {
    BlocProvider.of<LxNavCubit>(context).getBluetoothState();
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

  Future<void> checkForBluetoothScanPermission(
      Function connectToBtDevice) async {
    await checkPermission(
        permission: Permission.bluetoothScan,
        permissionGrantedFunction: connectToBtDevice,
        requestPermissionFunction: openAppSettingsFunction,
        permissionDeniedFunction: openAppSettingsFunction);
  }

  Future<void> openAppSettingsFunction() async {
    await openAppSettings();
  }

  void _connectToDevice(BluetoothDevice device) {
    BlocProvider.of<LxNavCubit>(context).connectToDevice(device);
  }

  void _toggleConnection(BluetoothDevice? device) async {
    if (device == null) return;
    if (device.isConnected) {
      BlocProvider.of<LxNavCubit>(context).disconnectDevice(device);
    } else {
      await checkForBluetoothScanPermission(
          () => _connectToDevice(_connectedDevice!));
    }
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

  Widget _getLxNavInfoWidget() {
    return BlocConsumer<LxNavCubit, LxNavDataState>(
        listener: (context, state) {},
        buildWhen: (previous, current) {
          return (current is LxNavInfoState ||
              current is LxNavDeviceConnectedState || // Depend on other widgets
              current is LxNavPairedDevicesState); // to set values
        },
        builder: (context, state) {
          if (state is LxNavInfoState) {
            return Visibility(
              visible:
                  (_connectedDevice != null && _connectedDevice!.isConnected),
              child: _getLxNavDisplay(state.deviceInfoLabels, state.infoValues),
            );
          } else {
            return SizedBox.shrink();
          }
        });
  }

  Widget _getLxNavDisplay(
    List<String> infoLabels,
    List<String> lxNavInfo,
  ) {
    List<DataRow> infoDisplay = [];
    for (var i = 0; i < infoLabels.length; ++i) {
      if (lxNavInfo[i].isNotEmpty) {
        infoDisplay.add(DataRow(cells: [
          DataCell(_getFormattedText(infoLabels[i])),
          DataCell(_getFormattedText(lxNavInfo[i])),
        ]));
      }
    }
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: DataTable(
            rows: infoDisplay,
            columns: [
              DataColumn(label: _getFormattedText("Parameter")),
              DataColumn(label: _getFormattedText("Value")),
            ],
            border: TableBorder.all(),
          ),
        ),
      ),
    );
  }

  Widget _getFormattedText(String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        value,
        style: textStyleBoldBlackFontSize18,
        softWrap: true,
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
