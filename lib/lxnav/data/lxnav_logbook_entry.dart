

import 'package:flutter/material.dart';

/// Holds details on igc file on LxNav device
class LxNavLogbookEntry {
  final int flightNumber;
  final String filename;
  final String date; // LxNav sends as  DD.MM.YYYY
  final String startTime; // HH:MM:SS
  final String endTime; // HH:MM:SS
  final int filesize;

  static const String zeroDate = "0000-00-00 ";

  LxNavLogbookEntry(
      {required this.flightNumber  ,
        required this.filename ,
        required  this.date ,
        required this.startTime ,
        required this.endTime,
        required this.filesize});

  String getFlightTime(){
    try {
      // Returns start DateTime
      var startDateTime = DateTime.parse(zeroDate + startTime);
      var endDateTime = DateTime.parse(zeroDate + endTime);
      Duration flightTime = endDateTime.difference(startDateTime);
      return format(flightTime);
    } catch (e){
      debugPrint(e.toString());
      return "00:00:00";
    }
  }

  String reformattedDate(){
    return date.substring(6) + '-' + date.substring(3,5)+ '-'+ date.substring(0,2);
  }

  format(Duration d) => d.toString().split('.').first.padLeft(8, "0");
}
