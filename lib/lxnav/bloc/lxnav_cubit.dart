import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:lxnav_bluetooth/lxnav/data/lxnav_logbook_entry.dart';

import 'lxnav_data_state.dart';
import '../lxnav.dart';
import 'package:collection/collection.dart';

class LxNavCubit extends Cubit<LxNavDataState> {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothConnectionState = BluetoothState.UNKNOWN;

  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // Track the Bluetooth connection with the remote device
  BluetoothConnection? _connection;
  int _deviceState = 0;
  bool isDisconnecting = false;
  bool _startedDisconnect = false;

  List<BluetoothDevice> _bondedDevices = [];

  String _processCommand = "";

  // To track whether the device is still connected to Bluetooth
  bool get _isConnected => _connection != null && _connection!.isConnected;

  // Define some variables, which will be required later
  List<BluetoothDevice> _deviceList = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  List<LxNavLogbookEntry> _logbookEntries = [];
  int _logbookSize = 0;
  int _startFlight = 0;
  int _endFlight = 0;

  LxNavCubit() : super(LxNavInitialState()) {
    enableBluetooth();
  }

  void _indicateWorking(bool isWorking) {
    emit(LxNavBtIsWorkingState(isWorking));
  }

  void getBluetoothState() {
    _indicateWorking(true);
    FlutterBluetoothSerial.instance.state.then((state) {
      _bluetoothConnectionState = state;
      emit(LxNavBtState(_bluetoothConnectionState));
    });
    _indicateWorking(false);
  }

  Future<void> enableBluetooth() async {
    _indicateWorking(true);
    try {
      bool? enabled = await FlutterBluetoothSerial.instance.requestEnable();
      if (enabled != null) {
        emit(LxNavBtEnabledState(enabled));
        if (enabled) {
          await _sendBondedDeviceList(null);
        }
      } else {
        emit(LxNavBtEnabledState(false));
      }
    } catch (e) {
      emit(LxNavBtEnabledState(false));
      emit(LxNavErrorState(e.toString()));
    }
    _indicateWorking(false);
  }

  Future<void> disableBluetooth() async {
    _indicateWorking(true);
    try {
      bool? enabled = await FlutterBluetoothSerial.instance.requestDisable();
      emit(LxNavBtEnabledState(enabled != null ? !enabled : true));
    } catch (e) {
      emit(LxNavErrorState(e.toString()));
    }
    _indicateWorking(false);
  }

  Future<void> connectToDevice(BluetoothDevice bluetoothDevice) async {
    _indicateWorking(true);
    // if currently connected, disconnect existing device then connect to new device
    if (_isConnected && bluetoothDevice.name != _selectedDevice?.name) {
      // disconnect current device/connection
      // this will trigger onDone() (below) on current connection
      await _connection!.finish();
    }
    _selectedDevice = bluetoothDevice;
    if (!_isConnected) {
      // connect to the device
      final connectingToDevice = bluetoothDevice;
      await BluetoothConnection.toAddress(_selectedDevice!.address)
          .then((deviceConnection) async {
        // made connection, so good to go
        debugPrint('Connected to the device');
        _connection = deviceConnection;
        _markDeviceAsConnected(connectingToDevice, true);
        await _sendBondedDeviceList(connectingToDevice);
        await getLxNavDeviceInfo();
        _connection!.input!.listen(_processBtData).onDone(() {
          _markDeviceAsConnected(connectingToDevice, false);
          _sendBondedDeviceList(connectingToDevice);
        });
      }).catchError((error) {
        emit(LxNavErrorState(
            "Could not connect to ${_selectedDevice!.name}. Check to make sure it is on or connected to another device"));
        _sendBondedDeviceList(_selectedDevice);
      });
    }
    _indicateWorking(false);
  }

  BluetoothDevice? _markDeviceAsConnected(
      BluetoothDevice bluetoothDevice, bool isConnected) {
    BluetoothDevice? device = _bondedDevices.firstWhereOrNull(
        (device) => device.address == bluetoothDevice.address);
    if (device == null) {
      emit(LxNavErrorState(
          "Uh-Oh. ${bluetoothDevice.name} missing from bonded device list"));
      return null;
    } else {
      device.isConnected = isConnected;
      return device;
    }
  }

  Future<void> disconnectDevice(BluetoothDevice bluetoothDevice) async {
    _indicateWorking(true);
    await _connection?.finish();
    bluetoothDevice.isConnected = false;
    _markDeviceAsConnected(bluetoothDevice, false);
    _indicateWorking(false);
  }



  /// If currentDevice not null, set that device to the one the ui should display
  ///  as selected.
  Future<void> getPairedDeviceList({BluetoothDevice? currentDevice}) async {
    _indicateWorking(true);
    _getBondedDevices();
    _indicateWorking(false);
  }

  Future<void> _getBondedDevices() async {
    await _bluetooth.getBondedDevices().then((devices) {
      _bondedDevices = devices;
    }).catchError((e) {
      emit(LxNavErrorState(e.toString()));
    });
  }

  // Clone the list for UI display
  // The bt plugin is slow in updating the bonded list after device disconnected
  // reconnected. So just get the list once and save it, then update it as needed
  Future<void> _sendBondedDeviceList(
      final BluetoothDevice? currentDevice) async {
    BluetoothDevice? currentSelectedDevice = currentDevice;
    List<BluetoothDevice> uiList = [];
    if (_bondedDevices.isEmpty) {
      await _getBondedDevices();
    }
    for (var device in _bondedDevices) {
      uiList.add(BluetoothDevice(
          name: device.name,
          address: device.address,
          type: device.type,
          isConnected: device.isConnected,
          bondState: device.bondState));
      // send out latest data in case other settings changed
      if (currentDevice != null &&
          device.address == currentSelectedDevice!.address) {
        currentSelectedDevice = device;
      }
    }
    BluetoothDevice? connectedDevice = _checkIfDeviceConnected(uiList,
        selectedDevice: currentSelectedDevice);
    emit(LxNavPairedDevicesState(
        uiList,
        _checkIfDeviceConnected(uiList,
            selectedDevice: connectedDevice)));
    if (connectedDevice != null && connectedDevice.isConnected){
      getLxNavDeviceInfo();
    }
  }

  // Method to send message,
  Future<void> _sendOnMessageToBluetooth(List<int> message) async {
    debugPrint("String to Nano: " + String.fromCharCodes(message));
    try {
      _connection!.output.add(Uint8List.fromList(message));
      debugPrint("Message sent");
    } catch (e) {
      emit(LxNavErrorState(e.toString()));
    }
  }

  BluetoothDevice? _checkIfDeviceConnected(List<BluetoothDevice> pairedDevices,
      {BluetoothDevice? selectedDevice}) {
    for (var device in pairedDevices) {
      // if selected not null and in list send that one
      if (selectedDevice != null && device.name == selectedDevice.name) {
        return device;
      } else {
        // if selectedDevice is null return first in list that is connected (if there is one)
        if (selectedDevice == null && device.isConnected == true) {
          return device;
        }
      }
    }
    if (pairedDevices.isNotEmpty) {
      // none connected so just set to first device in list
      return pairedDevices[0];
    }
    // no paired devices
    return null;
  }

  void dispose() {
    if (_isConnected) {
      isDisconnecting = true;
      _connection!.dispose();
      _connection = null;
    }
  }

  /// Get basic info on device
  Future<void> getLxNavDeviceInfo() async {
    _processCommand = LxNav.DEVICE_INFO;
    _sendOnMessageToBluetooth(LxNav.getLxNavDeviceInfo());
  }

  Future<void> getPilotInfo() async {
    debugPrint("Implement");
  }

  Future<void> getLogBook() async {
    emit(LxNavBtIsWorkingState(true));
    _processCommand = LxNav.LOGBOOK_SIZE;
    await _sendOnMessageToBluetooth(LxNav.getLogBookSize());
  }

  Future<void> getLoggedFlights(int start, int end) async {
    _processCommand = LxNav.LOGBOOK;
    await _sendOnMessageToBluetooth(LxNav.getFlightLogs(start, end));
  }

  // anything coming back from the communicator will be sent on a stream
  // so process it here
  void _processBtData(Uint8List bluetoothCommData) {
    // doesn't handle backspace or delete - see original code if needed
    String dataString = String.fromCharCodes(bluetoothCommData);
    debugPrint("String from LxDevice: " + dataString);
    (bool, String) data = LxNav.validateMessage(dataString);
    if (data.$1) {
      switch (_processCommand) {
        case LxNav.DEVICE_INFO:
          _processDeviceInfo(data.$1, data.$2);
          break;
        case LxNav.LOGBOOK_SIZE:
          _processLogbookSize(data.$1, data.$2);
          break;
        case LxNav.LOGBOOK:
          _processLogbookEntry(data.$1, data.$2);
          break;
      }
    }
    else {
       emit(LxNavErrorState(
          "UH-OH. Invalid message received: ${data.$2}"));
    }
  }

// Process general info about device
// LXNav doc Ver 1.04, Date: 20322-07-19, version 3 bt protocol
// PLXVC,INFO,A,<Device name>,<Application version>,<Version date and
//time>,<Hardware serial>,<Battery voltage>,<Backup battery voltage>,<Press
//Alt>,<Is charging>,<Enl>,<Logger status>,<Power consumption>,<Battery
//current>,<Battery percent>,<Remaining time>,<Serial number>,<Security key
//valid>,<Gps status>,<Gps char count>
// 3 command info fields  + 18 data fields
  Future<void> _processDeviceInfo(bool valid, String message) async {
    if (valid && message.startsWith(LxNav.DEVICE_INFO_ANSWER)) {
      var infoValues =
          message.replaceAll(LxNav.DEVICE_INFO_ANSWER, "").split(',');
      if (infoValues.length == LxNav.DEVICE_INFO_LABELS.length) {
        emit(LxNavInfoState(LxNav.DEVICE_INFO_LABELS, infoValues));
        emit(LxNavBtIsWorkingState(false));
        debugPrint("Emitted LxNavInfoState");
      } else {
        emit(LxNavBtIsWorkingState(false));
        emit(LxNavErrorState(
            "UH-OH. The number of device info fields doesn't match the expected number."));
      }
    } else {
      emit(LxNavBtIsWorkingState(false));
      emit(LxNavErrorState(
          "UH-OH. Invalid message or expected ${LxNav.DEVICE_INFO_ANSWER} but got ${message}"));
    }
  }

  Future<void> _processLogbookSize(bool valid, String message) async {
    _logbookEntries.removeRange(0, _logbookEntries.length);
    if (valid && message.startsWith(LxNav.LOGBOOK_SIZE_ANSWER)) {
      try {
        var size = message.replaceAll(LxNav.LOGBOOK_SIZE_ANSWER, "");
        _logbookSize = int.parse(size);
        if (_logbookSize == 0) {
          emit(LxNavLogBookState(_logbookEntries));
        } else {
          getLoggedFlights(1, _logbookSize + 1);
        }
      } catch (e) {
        emit(LxNavBtIsWorkingState(false));
        emit(LxNavErrorState("UH-OH. The logbooks size is not a number"));
        return;
      }
    } else {
      emit(LxNavBtIsWorkingState(false));
      emit(LxNavErrorState(
          "UH-OH. Invalid message or expected ${LxNav.LOGBOOK_SIZE} but got ${message}"));
    }
  }

  Future<void> _processLogbookEntry(bool valid, String message) async {
    if (valid && message.startsWith(LxNav.LOGBOOK_ANSWER)) {
      List<String> logEntry =
          message.replaceAll(LxNav.LOGBOOK_ANSWER, "").split(',');
      if (logEntry.length == 7) {
        try {
          final logbookEntry = LxNavLogbookEntry(
              flightNumber: int.parse(logEntry[0]),
              filename: logEntry[2],
              date: logEntry[3],
              startTime: logEntry[4],
              endTime: logEntry[5],
              filesize: int.parse(logEntry[6]));
          _logbookEntries.add(logbookEntry);
          if (logbookEntry.flightNumber == _logbookSize) {
            emit(LxNavLogBookState(_logbookEntries.reversed.toList()));
            emit(LxNavBtIsWorkingState(false));
          }
        } catch (e) {
          emit(LxNavErrorState("UH-OH. Invalid Logbook flight: ${message}"));
          emit(LxNavBtIsWorkingState(false));
        }
      } else if (logEntry.length == 1) {
        // this should only happen if no entries and the message contains a
        // flight number of 0
        try {
          if (int.parse(logEntry[0]) == 0) {
            emit(LxNavLogBookState(_logbookEntries));
            emit(LxNavBtIsWorkingState(false));
          }
        } catch (e) {
          debugPrint(e.toString());
          emit(LxNavBtIsWorkingState(false));
          emit(LxNavErrorState("UH-OH. Invalid Logbook entry: ${message}"));
        }
      } else {
        emit(LxNavBtIsWorkingState(false));
        emit(LxNavErrorState("UH-OH. Invalid Logbook entry: ${message}"));
      }
    } else {
      emit(LxNavBtIsWorkingState(false));
      emit(LxNavErrorState(
          "UH-OH. Invalid message or expected ${LxNav.LOGBOOK_SIZE_ANSWER} but got ${message}"));
    }
  }
}
