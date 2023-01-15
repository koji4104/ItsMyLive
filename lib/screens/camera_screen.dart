import 'package:flutter/material.dart';
import 'settings_screen.dart';

import 'package:native_device_orientation/native_device_orientation.dart';
import 'dart:math';

import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/controllers/camera_controller.dart';
import '/models/camera_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'log_screen.dart';
import '/common.dart';
import '/controllers/environment.dart';
import '/constants.dart';
import 'widgets.dart';
import 'base_screen.dart';

class CameraScreen extends BaseScreen with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StateData _state = StateData();
  Timer? _timer;
  final Battery _battery = Battery();
  int _batteryLevel = -1;
  int _batteryLevelStart = -1;
  StateWidget _stateWidget = StateWidget();

  @override
  Future init() async {
    print('-- CameraScreen.init()');
    ref.read(stateProvider).initHaishinKit(env);
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(Duration(seconds: 1), onTimer);
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        print('-- inactive');
        break;
      case AppLifecycleState.paused:
        print('-- paused');
        break;
      case AppLifecycleState.resumed:
        print('-- resumed');
        break;
      case AppLifecycleState.detached:
        print('-- detached');
        break;
    }
    if (state != null) {
      if (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached) {
        MyLog.warn("App stopped or background");
        onStop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context, ref);
    this._state = ref.watch(stateProvider).state;
    bool _isSaver = _state.isSaver;
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      body: Container(
        margin: edge.homebarEdge,
        child: Stack(children: <Widget>[
          // screen saver
          if (_isSaver)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: TextButton(
                child: Text(''),
                style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.black)),
                onPressed: () {},
              ),
            ),

          if (_isSaver == false) _cameraWidget(context),

          // Start
          MyIconButton(
            top: 0.0,
            bottom: 0.0,
            right: 40,
            icon: Icon(Icons.lens_rounded,
                color: _state.state == 2
                    ? Colors.blueAccent
                    : _state.state == 1
                        ? Colors.redAccent
                        : Colors.white),
            onPressed: () {
              _state.state == 0 ? onStart() : onStop();
            },
          ),

          // Camera Switch
          if (_isSaver == false)
            MyIconButton(
              bottom: 40.0,
              right: 40.0,
              icon: Icon(Icons.autorenew, color: Colors.white),
              onPressed: () => onSwitchCamera(),
            ),

          // Settings
          if (_isSaver == false)
            MyIconButton(
              top: 50.0,
              left: 40.0,
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () async {
                int old_video_kbps = env.video_kbps.val;
                int old_camera_height = env.camera_height.val;
                int old_video_fps = env.video_fps.val;

                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ));

                if (old_video_kbps != env.video_kbps.val ||
                    old_camera_height != env.camera_height.val ||
                    old_video_fps != env.video_fps.val) {
                  print('-- change env');
                  ref.read(stateProvider).changeVideoSettings(env);
                }
              },
            ),

          // State
          Positioned(
            top: 60,
            left: edge.width / 2 - 80,
            right: edge.width / 2 - 80,
            child: Container(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: _stateWidget,
            ),
          ),

          // Black Screen
          MyIconButton(
            bottom: 40.0,
            left: 40.0,
            icon: Icon(Icons.dark_mode, color: Colors.white),
            onPressed: () {
              ref.read(stateProvider).switchSaver();
            },
          ),
        ]),
      ),
    );
  }

  /// Camera Widget
  Widget _cameraWidget(BuildContext context) {
    if (IS_TEST) {
      return Center(
        child: Transform.scale(
          scale: 4.1,
          child: kIsWeb
              ? Image.network('/lib/assets/sample.png', fit: BoxFit.cover)
              : Image(image: AssetImage('lib/assets/sample.png')),
        ),
      );
    }
    return ref.read(stateProvider).getCameraWidget();
  }

  /// Switch
  void onSwitchCamera() {
    int pos = env.camera_pos.val == 0 ? 1 : 0;
    ref.read(environmentProvider).saveData(env.camera_pos, pos);
    ref.read(stateProvider).switchCamera(pos);
  }

  /// onStart
  Future<bool> onStart() async {
    if (kIsWeb) {
      _batteryLevelStart = await _battery.batteryLevel;
      ref.read(stateProvider).start(env);
      return true;
    }

    if (env.getUrl() == '') {
      showSnackBar('Error: url is empty');
      return false;
    }

    try {
      _batteryLevelStart = await _battery.batteryLevel;
      ref.read(stateProvider).start(env);
      MyLog.info("Start " + env.getUrl());
    } catch (e) {
      MyLog.err('${e.toString()}');
    }
    return true;
  }

  /// onStop
  Future<void> onStop() async {
    print('-- onStop');
    try {
      String s = 'Stop';
      if (_state.publishStartedTime != null) {
        Duration dur = DateTime.now().difference(_state.publishStartedTime!);
        if (dur.inMinutes > 0) s += ' ${dur.inMinutes}min';
      }
      if (_batteryLevelStart - _batteryLevel > 0) {
        s += ' batt ${_batteryLevelStart}->${_batteryLevel}%';
      }
      MyLog.info(s);
      ref.read(stateProvider).stop();
    } on Exception catch (e) {
      MyLog.err('${e.toString()}');
    }
  }

  /// Timer
  void onTimer(Timer timer) async {
    if (kIsWeb) return;

    // Autostop
    if (_state.state == 1 && _state.publishStartedTime != null) {
      Duration dur = DateTime.now().difference(_state.publishStartedTime!);
      if (env.autostop_sec.val > 0 && dur.inSeconds > env.autostop_sec.val) {
        MyLog.info("Autostop by settings");
        onStop();
        return;
      }
    }

    // check battery (every 1min)
    if (_state.state == 1 && DateTime.now().second == 0) {
      this._batteryLevel = await _battery.batteryLevel;
      if (this._batteryLevel < 10) {
        await MyLog.warn("Low battery");
        onStop();
        return;
      }
    }
  }

  void showSnackBar(String msg) {
    if (context != null) {
      final snackBar = SnackBar(content: Text(msg));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}

final stateWidgetProvider = StateProvider<String>((ref) {
  return '';
});

class StateWidget extends ConsumerWidget {
  Timer? _timer;
  late WidgetRef ref;
  StateData _state = StateData();
  String _oldStr = '';

  StateWidget() {}

  void init(BuildContext context, WidgetRef ref) {
    if (_timer == null) {
      _timer = Timer.periodic(Duration(seconds: 1), onTimer);
    }
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    this.ref = ref;
    this._state = ref.watch(stateProvider).state;
    String str = ref.watch(stateWidgetProvider);
    Future.delayed(Duration.zero, () => init(context, ref));
    return Text(str, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white));
  }

  void onTimer(Timer timer) async {
    String str = 'Stop';
    if (_state.state == 2) {
      str = (_state.retry > 0) ? 'Retry (${_state.retry})' : 'Connecting';
      if (_state.connectStartedTime != null) {
        Duration dur = DateTime.now().difference(_state.connectStartedTime!);
        if (dur.inSeconds >= 0) str += ' ${dur.inSeconds}s';
      }
    } else if (_state.state == 1) {
      Duration dur = DateTime.now().difference(_state.publishStartedTime!);
      str = dur2str(dur);
    }
    if (_oldStr != str) {
      _oldStr = str;
      ref.read(stateWidgetProvider.state).state = str;
    }
  }

  /// 01:00:00
  String dur2str(Duration dur) {
    String s = "";
    if (dur.inHours > 0) s += dur.inHours.toString() + ':';
    s += dur.inMinutes.remainder(60).toString().padLeft(2, '0') + ':';
    s += dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    return s;
  }
}

/// OrientationCamera
class OrientationCamera extends StatelessWidget {
  Widget child;
  OrientationCamera({required this.child});
  @override
  Widget build(BuildContext context) {
    return NativeDeviceOrientationReader(
        useSensor: true,
        builder: (context) {
          double angle = 0.0;
          switch (NativeDeviceOrientationReader.orientation(context)) {
            case NativeDeviceOrientation.landscapeRight:
              angle = pi * 1 / 2;
              break;
            case NativeDeviceOrientation.landscapeLeft:
              angle = pi * 3 / 2;
              break;
            case NativeDeviceOrientation.portraitDown:
              angle = pi * 2 / 2;
              break;
            default:
              break;
          }
          return Transform.rotate(angle: angle, child: child);
        });
  }
}
