import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';

final isSaverProvider = StateProvider<bool>((ref) {
  return false;
});

class StateData {
  /// 0 stop 1 running 2 connecting or retry
  int state = 0;
  int retry = 0;
  DateTime? publishStartedTime;
  DateTime? connectStartedTime;
  bool isSaver = false;
}

final stateProvider = ChangeNotifierProvider((ref) => stateNotifier(ref));
class stateNotifier extends ChangeNotifier {
  StateData state = StateData();
  stateNotifier(ref){}

  stop() {
    state.state = 0;
    state.retry = 0;
    state.publishStartedTime = null;
    state.connectStartedTime = null;
    this.notifyListeners();
  }
  running() {
    state.state = 1;
    state.retry = 0;
    state.publishStartedTime = DateTime.now();
    state.connectStartedTime = null;
    this.notifyListeners();
  }
  connecting() {
    state.state = 2;
    state.retry = 0;
    state.publishStartedTime = null;
    state.connectStartedTime = DateTime.now();
    this.notifyListeners();
  }
  retry() {
    state.state = 2;
    state.retry += 1;
    //state.startTime = state.startTime;
    state.connectStartedTime = DateTime.now();
    this.notifyListeners();
  }
  switchSaver() {
    state.isSaver = !state.isSaver;
    this.notifyListeners();
  }
}