import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';

final isSaverProvider = StateProvider<bool>((ref) {
  return false;
});

class StatusData {
  int state = 0;
  int retry = 0;
  DateTime? startTime;
  DateTime? connectTime;
  bool isSaver = false;
}

final statusProvider = ChangeNotifierProvider((ref) => statusNotifier(ref));
class statusNotifier extends ChangeNotifier {
  StatusData statsu = StatusData();
  statusNotifier(ref){}

  stop() {
    statsu.state = 0;
    statsu.retry = 0;
    statsu.startTime = null;
    statsu.connectTime = null;
    this.notifyListeners();
  }
  running() {
    statsu.state = 1;
    statsu.retry = 0;
    statsu.startTime = DateTime.now();
    statsu.connectTime = null;
    this.notifyListeners();
  }
  connecting() {
    statsu.state = 2;
    statsu.retry = 0;
    statsu.startTime = null;
    statsu.connectTime = DateTime.now();
    this.notifyListeners();
  }
  retry() {
    statsu.state = 2;
    statsu.retry += 1;
    //statsu.startTime = statsu.startTime;
    statsu.connectTime = DateTime.now();
    this.notifyListeners();
  }
  SwitchSaver() {
    statsu.isSaver = !statsu.isSaver;
    this.notifyListeners();
  }
}