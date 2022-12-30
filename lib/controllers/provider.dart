import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';

final isSaverProvider = StateProvider<bool>((ref) {
  return false;
});

class StateData {
  int state = 0;
  int retry = 0;
  DateTime? startTime;
  DateTime? connectTime;
  bool isSaver = false;
}

final stateProvider = ChangeNotifierProvider((ref) => stateNotifier(ref));
class stateNotifier extends ChangeNotifier {
  StateData state = StateData();
  stateNotifier(ref){}

  stop() {
    state.state = 0;
    state.retry = 0;
    state.startTime = null;
    state.connectTime = null;
    this.notifyListeners();
  }
  running() {
    state.state = 1;
    state.retry = 0;
    state.startTime = DateTime.now();
    state.connectTime = null;
    this.notifyListeners();
  }
  connecting() {
    state.state = 2;
    state.retry = 0;
    state.startTime = null;
    state.connectTime = DateTime.now();
    this.notifyListeners();
  }
  retry() {
    state.state = 2;
    state.retry += 1;
    //state.startTime = state.startTime;
    state.connectTime = DateTime.now();
    this.notifyListeners();
  }
  SwitchSaver() {
    state.isSaver = !state.isSaver;
    this.notifyListeners();
  }
}