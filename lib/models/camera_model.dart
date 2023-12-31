import 'package:flutter/material.dart';
import '/constants.dart';

enum MyState {
  uninitialized,
  stopped,
  connecting,
  streaming,
}

class StateData {
  MyState state = MyState.uninitialized;
  int retry = 0;
  DateTime? connectTime;
  DateTime? streamTime;
  bool isDispInfo = false;

  Color get stateColor {
    if (IS_TEST_SS) return Colors.redAccent;
    Color c = Colors.black;
    switch (this.state) {
      case MyState.stopped:
        c = Colors.grey;
        break;
      case MyState.connecting:
        c = Colors.blueAccent;
        break;
      case MyState.streaming:
        c = Colors.redAccent;
        break;
    }
    return c;
  }

  int get connectSec {
    return connectTime != null ? DateTime.now().difference(connectTime!).inSeconds : -1;
  }

  int get streamSec {
    return streamTime != null ? DateTime.now().difference(streamTime!).inSeconds : -1;
  }

  /// 01:10
  String get streamTimeString {
    String str = "";
    if (streamTime != null) {
      Duration dur = DateTime.now().difference(streamTime!);
      if (dur.inHours > 0) str += dur.inHours.toString() + ':';
      str += dur.inMinutes.remainder(60).toString().padLeft(2, '0') + ':';
      str += dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    }
    return str;
  }
}
