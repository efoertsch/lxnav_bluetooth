import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../lxnav_igc_file_info.dart';

abstract class LxNavDataState {
  const LxNavDataState();
}

class LxNavInitialState extends LxNavDataState {
  const LxNavInitialState();
}

class LxNavBtIsWorkingState extends LxNavDataState {
  bool isWorking;

  LxNavBtIsWorkingState(this.isWorking);
}

class LxNavBtEnabledState extends LxNavDataState {
  bool btEnabled;

  LxNavBtEnabledState(this.btEnabled);
}

class LxNavBtState extends LxNavDataState {
  BluetoothState btState;

  LxNavBtState(this.btState);
}

class LxNavConnectionState extends LxNavDataState {
  final bool connected;
  final String? message;

  const LxNavConnectionState(this.connected, this.message);
}

class LxNavDeviceConnectedState extends LxNavDataState {
  BluetoothDevice? connectedDevice;

  LxNavDeviceConnectedState(this.connectedDevice);
}

class LxNavPairedDevicesState extends LxNavDataState {
  List<BluetoothDevice> devices;
  BluetoothDevice? connectedDevice;

  LxNavPairedDevicesState(this.devices, this.connectedDevice);
}

class LxNavLogBookState extends LxNavDataState {
  List<LxNavIgcFileInfo> logbook;

  LxNavLogBookState(this.logbook);
}

class LxNavIgcFileDataState extends LxNavDataState {
  List<String> igcFileData;

  LxNavIgcFileDataState(this.igcFileData);
}

class LxNavErrorState extends LxNavDataState {
  final String errorMsg;

  LxNavErrorState(this.errorMsg);
}

class LxNavInfoState extends LxNavDataState {
  final List<String> deviceInfoLabels;
  final List<String> infoValues;

  LxNavInfoState(this.deviceInfoLabels, this.infoValues, );

}
