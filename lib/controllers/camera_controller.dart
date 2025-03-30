import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';
import '/models/camera_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer';
import '/constants.dart';
import '/screens/log_screen.dart';
import '/controllers/environment.dart';
import 'dart:async';
import 'package:mylive_libraly/mylive_libraly.dart';
import 'package:network_info_plus/network_info_plus.dart';

final stateProvider = ChangeNotifierProvider((ref) => StateNotifier(ref));

class StateNotifier extends ChangeNotifier {
  StateData state = StateData();
  Timer? _timer;
  Environment env = new Environment();
  MyLiveController _controller = MyLiveController();
  bool _onConnected = false;

  String wifiIPv4 = "";
  String wifiIPv6 = "";

  StateNotifier(ref) {
    _timer = Timer.periodic(Duration(seconds: 1), onTimer);
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
  }

  Future<void> initController(Environment env) async {
    if (kIsWeb) return;
    this.env = env;
    state.state = MyState.uninitialized;

    try {
      wifiIPv4 = await NetworkInfo().getWifiIP() ?? "";
      print("-- IPv4=${wifiIPv4}");
    } catch (e) {}
    try {
      wifiIPv6 = await NetworkInfo().getWifiIPv6() ?? "";
      print("-- IPv6=${wifiIPv6}");
      if (wifiIPv6.contains("fe80:")) wifiIPv6 = "";
    } catch (e) {}

    try {
      await Permission.camera.request();
      await Permission.microphone.request();
    } catch (e) {
      print('-- initialize.Permission error');
    }

    var v = MyLiveVideoConfig(
      bitrate: env.video_kbps.val * 1000,
      fps: env.video_fps.val,
      width: env.getCameraWidth(),
      height: env.camera_height.val,
    );
    var a = MyLiveAudioConfig(
      bitrate: 128 * 1000,
      sampleRate: 44100,
    );
    try {
      _controller
          .initialize(
        videoConfig: v,
        audioConfig: a,
        cameraPos: 0,
        url: env.getUrl(),
        key: env.getKey(),
        onConnected: () {
          print('-- onConnected');
          _onConnected = true;
        },
        onDisconnected: (message) {
          print('-- onDisconnected: $message');
        },
        onFailed: (error) {
          print('-- onFailed: $error');
        },
        onError: (error) {
          print('-- onError: code=${error.code} message=${error.message}');
        },
      )
          .then((_) {
        state.state = MyState.stopped;
        this.notifyListeners();
      }).catchError((e) {
        log('initialize catchError ${e.toString()}');
        state.state = MyState.uninitialized;
        this.notifyListeners();
      });
    } catch (e) {
      log('initialize error ${e}');
    }
  }

  void start(Environment env) {
    this.env = env;
    _onConnected = false;
    if (kIsWeb) {
      toConnecting();
      return;
    }
    try {
      _controller.startStream();
      toConnecting();
    } catch (e) {
      MyLog.err('-- startStream ${e.toString()}');
    }
  }

  void stop() {
    try {
      _controller.stopStream();
      toStoped();
    } catch (e) {
      MyLog.err('${e.toString()}');
    }
  }

  toStoped() {
    state.state = MyState.stopped;
    state.retry = 0;
    state.streamTime = null;
    state.connectTime = null;
    this.notifyListeners();
  }

  toStreaming() {
    state.state = MyState.streaming;
    state.retry = 0;
    state.streamTime = DateTime.now();
    state.connectTime = null;
    this.notifyListeners();
  }

  toConnecting() {
    _onConnected = false;
    state.state = MyState.connecting;
    state.retry = 0;
    state.streamTime = null;
    state.connectTime = DateTime.now();
    this.notifyListeners();
  }

  toRetrying() {
    _onConnected = false;
    state.state = MyState.connecting;
    state.retry += 1;
    //state.publishTime = null;
    state.connectTime = DateTime.now();
    this.notifyListeners();
  }

  void switchDispInfo() {
    state.isDispInfo = !state.isDispInfo;
    this.notifyListeners();
  }

  /// pos 0=back 1=front
  void switchCamera(int pos) {
    _controller.setCameraPos(pos);
  }

  Widget getCameraWidget() {
    if (kIsWeb || _controller.isInitialized == false) {
      return Positioned(left: 0, top: 0, right: 0, bottom: 0, child: Container(color: Color(0xFF333333)));
    } else {
      return Center(child: MyLivePreview(controller: _controller));
    }
  }

  MyState _oldState = MyState.stopped;

  /// Timer
  void onTimer(Timer timer) async {
    if (_controller.isInitialized == false) return;

    // Connection timed out
    if (state.connectSec >= 30 && state.streamTime == null && state.state == MyState.connecting && state.retry == 0) {
      MyLog.info('Connection timed out');
      stop();
    }

    if (state.state != MyState.stopped) {
      bool isStreaming = await _controller.isStreaming();
      if (state.streamTime != null) {
        if (state.streamSec >= 15 && isStreaming == false) {
          if (state.retry > 20) {
            toStoped();
          } else if (state.retry == 0) {
            toRetrying();
          } else if (state.retry >= 1 && state.connectSec >= (5 + (state.retry * 2))) {
            if (state.retry == 1) MyLog.warn('Retried');
            _controller.startStream();
            toRetrying();
          }
        } else if (state.streamSec >= 5 && state.streamSec <= 10 && isStreaming == false) {
          //if (_controller.isSrt == false) MyLog.warn('Probably wrong RTMP KEY');
          //toStoped();
        }

        // Log
        if (_oldState != state.state) {
          print("-- State ${_oldState} -> ${state.state}");
          _oldState = state.state;
        }
      }

      // rtmp and connect=ok and wrong key
      if (state.connectSec > 5 && _onConnected == true && _controller.isSrt == false && isStreaming == false) {
        MyLog.warn('Probably wrong RTMP KEY');
        toStoped();
      }

      // リトライから復帰
      if (state.retry > 0 && isStreaming == true) {
        toStreaming();
      }

      if (state.connectTime != null && state.streamTime == null && isStreaming == true) {
        toStreaming();
      }

      if (state.streamTime == null && state.state != MyState.streaming && isStreaming == true) {
        toStreaming();
      }
    }
  }
}
