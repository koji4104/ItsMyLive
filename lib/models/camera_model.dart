import 'package:flutter/material.dart';

class StateData {
  /// 0 stop 1 running 2 connecting or retry
  int state = 0;
  int retry = 0;
  DateTime? publishStartedTime;
  DateTime? connectStartedTime;
  bool isSaver = false;
}
