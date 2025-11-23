import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'dart:developer';
import 'dart:math' show pi; // duplicate log
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/controllers/camera_controller.dart';
import '/models/camera_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'log_screen.dart';
import '/controllers/environment.dart';
import '/constants.dart';
import '/commons/widgets.dart';
import '/commons/base_screen.dart';

class CameraScreen extends BaseScreen with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StateData _state = StateData();
  Timer? _timer;
  final Battery _battery = Battery();
  int _batteryLevel = -1;
  int _batteryLevelStart = -1;
  StateWidget _stateWidget = StateWidget();
  double _width = 1000.0;
  double _height = 1000.0;
  int _zoom = 10;

  @override
  Future init() async {
    log('CameraScreen.init()');
    if (IS_TEST_SS) return;
    ref.read(stateProvider).initController(env);
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(Duration(seconds: 1), onTimer);
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != null) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        MyLog.warn("App stopped or background");
        onStop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    myEnv = ref.watch(envProvider).env;
    this._state = ref.watch(stateProvider).state;
    _width = MediaQuery.of(context).size.width;
    _height = MediaQuery.of(context).size.height;

    double padtop = 50.0;
    double pad = 40.0;
    double padbottom = 40.0;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      body: Container(
        margin:
            IS_TEST_SS ? EdgeInsets.fromLTRB(100, 20, 100, 0) : EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: Stack(children: <Widget>[
          cameraWidget(context),

          // Start
          MyIconButton(
            top: 0.0,
            bottom: 0.0,
            right: pad,
            icon: Icon(Icons.lens_rounded, color: _state.stateColor),
            onPressed: () {
              _state.state == MyState.stopped ? onStart() : onStop();
            },
          ),

          // Camera Switch
          MyIconButton(
            bottom: padbottom,
            right: pad,
            icon: Icon(Icons.autorenew, color: Colors.white),
            onPressed: () => onSwitchCamera(),
          ),

          // Settings
          MyIconButton(
            top: padtop,
            left: pad,
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              int old_video_kbps = env.video_kbps.val;
              int old_camera_height = env.camera_height.val;
              int old_video_fps = env.video_fps.val;
              String old_url = env.getUrl();
              String old_key = env.getKey();

              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SettingsScreen(),
              ));

              if (old_video_kbps != env.video_kbps.val ||
                  old_camera_height != env.camera_height.val ||
                  old_video_fps != env.video_fps.val ||
                  old_url != env.getUrl() ||
                  old_key != env.getKey()) {
                log('change env');
                ref.read(stateProvider).initController(env);
              } else if (ref.read(stateProvider).state == MyState.uninitialized) {
                log('initController');
                ref.read(stateProvider).initController(env);
              }
            },
          ),

          // State
          Positioned(
            top: padtop + 6.0,
            left: IS_TEST_SS ? 310 : _width / 2 - 95,
            right: IS_TEST_SS ? 310 : _width / 2 - 95,
            child: Container(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: _stateWidget,
            ),
          ),

          // State (Info)
          if (_state.isDispInfo)
            Positioned(
              bottom: pad + 70.0,
              left: pad + 2,
              width: 340.0,
              height: 84.0,
              child: Container(
                padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: getInfo(),
              ),
            ),

          // Info button
          MyIconButton(
            bottom: padbottom,
            left: pad,
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              ref.read(stateProvider).switchDispInfo();
            },
          ),

          MyIconButton(
            bottom: padbottom,
            left: pad + 70,
            icon: Icon(Icons.remove, color: Colors.white),
            onPressed: () {
              _zoom -= 5;
              if (_zoom < 10) _zoom = 10;
              ref.read(stateProvider).setCameraZoom(_zoom);
              redraw();
            },
          ),
          Positioned(
            bottom: padbottom + 12,
            left: pad + 140,
            width: 40.0,
            height: 40.0,
            child: Container(
              padding: EdgeInsets.fromLTRB(1, 1, 1, 1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _zoom.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          MyIconButton(
            bottom: padbottom,
            left: pad + 186,
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _zoom += 5;
              if (_zoom > 40) _zoom = 40;
              ref.read(stateProvider).setCameraZoom(_zoom);
              redraw();
            },
          ),
        ]),
      ),
    );
  }

  /// Camera Widget
  Widget cameraWidget(BuildContext context) {
    if (kIsWeb || IS_TEST_SS) {
      return Center(
        child: Transform.scale(
          scale: 1.4,
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
    ref.read(envProvider).saveData(env.camera_pos.name, pos);
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
    log('onStop');
    try {
      String s = 'Stop';
      if (_state.streamingTimeString != "") s += " " + _state.streamingTimeString;
      if (_batteryLevel > 0 && _batteryLevelStart - _batteryLevel > 0) {
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
    if (_state.state == MyState.streaming && _state.streamTime != null) {
      Duration dur = DateTime.now().difference(_state.streamTime!);
      if (env.autostop_sec.val > 0 && dur.inSeconds > env.autostop_sec.val) {
        MyLog.info("Autostop by settings");
        onStop();
        return;
      }
    }

    // check battery (every 1min)
    if (_state.state == MyState.streaming && DateTime.now().second == 0) {
      this._batteryLevel = await _battery.batteryLevel;
      if (this._batteryLevel < 10) {
        await MyLog.warn("Low battery");
        onStop();
        return;
      }
    }
  }

  Widget getInfo() {
    String str = env.getUrl();
    if (str.length == 0) str = "URL is empty";
    str += "\r\n${env.getCameraWidth()}x${env.camera_height.val}";
    str += env.video_kbps.val < 1000
        ? " ${env.video_kbps.val}kbps"
        : " ${env.video_kbps.val / 1000}mbps";
    str += " ${env.video_fps.val}fps";
    if (ref.read(stateProvider).wifiIPv4 != "") str += "\r\nIP ${ref.read(stateProvider).wifiIPv4}";
    if (ref.read(stateProvider).wifiIPv6 != "") str += "\r\nIP ${ref.read(stateProvider).wifiIPv6}";
    return Text(str,
        textAlign: TextAlign.left, style: TextStyle(fontSize: 13, color: Colors.white));
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
    if (IS_TEST_SS) return;
    if (_timer == null) {
      Future.delayed(Duration(seconds: 1), () {
        _timer = Timer.periodic(Duration(seconds: 1), onTimer);
      });
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
    String str = IS_TEST_SS ? "12:03" : ref.watch(stateWidgetProvider);
    Future.delayed(Duration.zero, () => init(context, ref));
    return Text(str,
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white));
  }

  /// every second
  void onTimer(Timer timer) async {
    try {
      String str = 'Stop';
      if (_state.state == MyState.connecting) {
        str = 'Connecting';
        if (_state.retry > 0) {
          str = 'Retrying ${_state.retry}x';
        }
        if (_state.connectTime != null) {
          Duration dur = DateTime.now().difference(_state.connectTime!);
          if (dur.inSeconds >= 0) str += ' ${dur.inSeconds}s';
        }
      } else if (_state.state == MyState.streaming) {
        str = _state.streamingTimeString;
      } else if (_state.state == MyState.uninitialized) {
        str = "Uninitialized";
      }
      if (_oldStr != str) {
        _oldStr = str;
        ref.read(stateWidgetProvider.state).state = str;
      }
    } catch (e) {
      log('onTimer err=${e.toString()}');
    }
  }
}
