import 'dart:convert';

class LxNav {
  /// From LxNav Data Port Specification Document 2022-07-19  V1.04
  ///  All commands must start with a “$” (0x24) sign and end with a “*” (0x2A)
  ///  followed by two NMEA 0183 standard checksum characters and <CR><LF> (0x0D0A).
  ///  The checksum is two – digit hexadecimal representation of XOR of ASCII
  ///  codes of all characters between, but not including, the $ and * characters.
  ///  Fields are delimited with a comma (0x2C), even if a field is empty.
  ///  The field length is variable. Commands must always include valid ASCII characters.
  ///  The sentences are not case sensitive. The maximum number of characters in a sentence is 256.
  ///  Messages described in this document are version 3 protocol messages.
  ///  $<Sentence type>,<Key>,<Query type>,<Parameters>*<CHECKSUM><CR><LF>
  ///  Checksum reference logic  https://forum.arduino.cc/t/nmea-checksums-explained/1046083
  ///

  static const String DEVICE_INFO = "PLXVC,INFO";
  static const String DEVICE_INFO_REQUEST = DEVICE_INFO + ",R";
  static const String DEVICE_INFO_ANSWER = DEVICE_INFO + ",A,";

  static const String LOGBOOK_SIZE = "PLXVC,LOGBOOKSIZE";
  static const String LOGBOOK_SIZE_REQUEST = LOGBOOK_SIZE + ",R";
  static const String LOGBOOK_SIZE_ANSWER = LOGBOOK_SIZE + ",A,";

  static const List<int> crlf = [13, 10]; // '0x0D0A' <CR><LF>
  static const int dollarSign = 36; //  $ 0x24
  static const int asterisk = 42; // * 0x2A

  static const List<String> DEVICE_INFO_LABELS = [
    "Device name",
    "Application version",
    "Version date and time",
    "Hardware serial",
    "Battery voltage",
    "Backup battery voltage",
    "Press Alt",
    "Is charging",
    "Enl",
    "Logger status",
    "Power consumption",
    "Batterycurrent",
    "Battery percent",
    "Remaining time",
    "Serial number",
    "Security key valid",
    "Gps status",
    "Gps char count"
  ];

  static List<int> getLxNavDeviceInfo() {
    return getLxNavString(DEVICE_INFO);
  }

  static List<int> getLogBookSize() {
    return getLxNavString(LOGBOOK_SIZE_REQUEST);
  }

  static List<int> getLxNavString(message) {
    List<int> utf8ints = <int>[];
    utf8ints.add(dollarSign);
    var messageAsInts = utf8.encode(message);
    utf8ints.addAll(messageAsInts);
    utf8ints.add(asterisk);
    utf8ints.addAll(xorCommand(messageAsInts));
    utf8ints.addAll(crlf);
    return utf8ints;
  }

  // Return 2 hexidecimal digits  from the 8 bit xor result
  static List<int> xorCommand(List<int> commandAsInts) {
    int xor = 0;
    for (int i = 1; i < commandAsInts.length; i++) {
      if (i == 1) {
        xor = commandAsInts[i - 1] ^ commandAsInts[i];
      } else {
        xor = xor ^ commandAsInts[i];
      }
    }
    // Convert the xor to 2 hexidecimal digits (eg A0)
    //  '0' through '9' are represented by 0x30 through 0x39
    //  'A' through 'F' are represented by 0x41 through 0x46
    //  Separate the xor into 2 ints with values 0 - 15
    List<int> xorBytes = [xor >>> 4, xor & 15];
    // Convert each into into ASCII char value of 0-9, A-F
    xorBytes[0] = xorBytes[0] <= 9 ? xorBytes[0] + 48 : xorBytes[0] - 10 + 65;
    xorBytes[1] = xorBytes[1] <= 9 ? xorBytes[1] + 48 : xorBytes[1] - 10 + 65;
    return xorBytes;
    // String hexString = xor.toRadixString(16);
    // return hexString.padLeft(2, '0');
  }

  static (bool, String) validateMessage(String input) {
    // $...*(2 byte checksum)\r\n
    int messageLength = input.length;
    if (messageLength < 7)
      return (false, ""); // must have at least 1 char in message
    // remove leading $ and trailing checksum (2 bytes) <CR><LF>
    String message = input.substring(1, messageLength - 4);
    String checksum = input.substring(messageLength - 4, messageLength - 2);
    // remove the $ start char and last 5  (last 5 are *checksum\r\n , e.g. *6B<CR><LF>)
    String dataString = input.substring(1, input.length - 5);
    var xor = xorCommand(utf8.encode(dataString));
    bool valid = (String.fromCharCodes(xor) == checksum);
    return (valid, message);
  }
}
