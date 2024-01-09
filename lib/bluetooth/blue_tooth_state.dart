import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';


abstract class BluetoothInfoState {
  const BluetoothInfoState();
}

class BluetoothDataState extends BluetoothInfoState {
  final  Uint8List bluetoothCommData;

  const BluetoothDataState(this.bluetoothCommData);
}

class BluetoothErrorState extends BluetoothInfoState {
  final String bluetoothError;

  BluetoothErrorState(this.bluetoothError);
}

class BluetoothPairedDeviceState extends BluetoothInfoState {
  final List<BluetoothDevice> pairedDevices;

  BluetoothPairedDeviceState(this.pairedDevices);
}
