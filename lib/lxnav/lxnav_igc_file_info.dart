
/// Holds details on igc file on LxNav device
class LxNavIgcFileInfo {
  final String fileName;
  final String date;    // YYYY-MM-DD  Note LxNav sends as  DD.MM.YYYY
  final String startTime;  // HH:MM:SS
  final String endTime;    // HH:MM:SS
  LxNavIgcFileInfo(this.fileName, this.date, this.startTime, this.endTime);
}