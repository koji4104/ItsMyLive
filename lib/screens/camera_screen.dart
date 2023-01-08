import 'package:flutter/material.dart';
import 'settings_screen.dart';

import 'package:native_device_orientation/native_device_orientation.dart';
import 'dart:math';

import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/controllers/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'log_screen.dart';
import '/common.dart';
import '/controllers/environment.dart';
import '/constants.dart';
import 'widgets.dart';
import 'base_screen.dart';

import 'package:audio_session/audio_session.dart';
import 'package:haishin_kit/audio_settings.dart';
import 'package:haishin_kit/audio_source.dart';
import 'package:haishin_kit/net_stream_drawable_texture.dart';
import 'package:haishin_kit/rtmp_connection.dart';
import 'package:haishin_kit/rtmp_stream.dart';
import 'package:haishin_kit/video_settings.dart';
import 'package:haishin_kit/video_source.dart';
import 'package:permission_handler/permission_handler.dart';

bool disableCamera = kIsWeb; // true=test

class CameraScreen extends BaseScreen {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  StateData _state = StateData();
  String _state2String = '';

  Timer? _timer;
  final Battery _battery = Battery();
  int _batteryLevel = -1;
  int _batteryLevelStart = -1;

  RunningStateScreen _RunningState = RunningStateScreen();

  RtmpConnection? _connection;
  RtmpStream? _stream;

  @override
  Future init() async {
    _timer = Timer.periodic(Duration(seconds:1), _onTimer);
    initPlatformState();
  }

  @override
  void dispose() {
    //if(_controller!=null) _controller!.dispose();
    if(_timer!=null) _timer!.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: print('-- inactive'); break;
      case AppLifecycleState.paused: print('-- paused'); break;
      case AppLifecycleState.resumed: print('-- resumed'); break;
      case AppLifecycleState.detached: print('-- detached'); break;
    }
    if(state!=null) {
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
    this._state = ref
        .watch(stateProvider)
        .state;
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
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.black)),
                    onPressed: () {},
                  )
              ),

            if(_isSaver == false)
              _cameraWidget(context),

            // Start
            //if (_isSaver==false)
            MyIconButton(
              top: 0.0,
              bottom: 0.0,
              right: 40,
              icon: Icon(Icons.lens_rounded,
                  color: _state.state == 2 ? Colors.blueAccent : _state.state ==
                      1 ? Colors.redAccent : Colors.white),
              onPressed: () {
                _state.state == 0 ? onStart() : onStop();
              },
            ),

            // Camera Switch
            if(_isSaver == false)
              MyIconButton(
                bottom: 40.0, right: 40.0,
                icon: Icon(Icons.autorenew, color: Colors.white),
                onPressed: () => _onCameraSwitch(ref),
              ),

            // Settings
            if(_isSaver == false)
              MyIconButton(
                  top: 50.0, left: 40.0,
                  icon: Icon(Icons.settings, color: Colors.white),
                  onPressed: () async {
                    int old_video_kbps = env.video_kbps.val;
                    int old_camera_height = env.camera_height.val;
                    int old_video_fps = env.video_fps.val;

                    await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(),
                        )
                    );

                    if (old_video_kbps != env.video_kbps.val
                        || old_camera_height != env.camera_height.val
                        || old_video_fps != env.video_fps.val) {
                      print('-- change env');
                      initPlatformState();
                    }
                  }
              ),

            // State
            //if(_isSaver==false)
            Positioned(
                top: 60, left: edge.width / 2 - 80, right: edge.width / 2 - 80,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: _RunningState,
                )
            ),

            // State2
            //if(_isSaver==false)
            Positioned(
                bottom: 50,
                left: edge.width / 2 - 80,
                right: edge.width / 2 - 80,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(_state2String,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white)
                  ),
                )
            ),

            // Black Screen
            MyIconButton(
                bottom: 40.0, left: 40.0,
                icon: Icon(Icons.dark_mode, color: Colors.white),
                onPressed: () {
                  ref.read(stateProvider).switchSaver();
                }
            ),
          ]
          ),
        ));
  }

  Future<void> initPlatformState() async {
    if (disableCamera || IS_TEST) return;
    await Permission.camera.request();
    await Permission.microphone.request();

    // Set up AVAudioSession for iOS.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
      AVAudioSessionCategoryOptions.allowBluetooth,
    ));

    if (_connection == null) {
      print('-- initPlatformState() _connection create');
      _connection = await RtmpConnection.create();
    }
    if (_connection != null) {
      StreamSubscription _streamSubscription = _connection!.eventChannel.receiveBroadcastStream().listen((event) {
        String code = event["data"]["code"];
        String desc = event["data"]["description"];

        String s = (desc.length>0) ? '${code} (${desc})' :'${code}';
        MyLog.debug(s);

        if(code!='NetConnection.Connect.Success' && code!='NetStream.Publish.Start') {
          _state2String = desc;
          redraw();
        }
        switch (event["data"]["code"]) {
          case 'NetConnection.Connect.Success':
            _stream?.publish(env.getKey()).then((_) {
              ref.read(stateProvider).running();
              _state2String = '';
              redraw();
            });
            break;
          case 'NetConnection.Connect.Closed':
            if (_state.publishStartedTime != null) {
              ref.read(stateProvider).retry();
              _connection!.connect(env.getUrl());
              MyLog.warn("Retry (${_state.retry})");
            }
            break;
          case 'NetConnection.Connect.Failed':
          case 'NetConnection.Call.BadVersion':
          case 'NetConnection.Call.Failed':
          case 'NetConnection.Call.Prohibited':
          case 'NetConnection.Connect.AppShutdown':
          case 'NetConnection.Connect.IdleTimeOut':
          case 'NetConnection.Connect.InvalidApp':
          case 'NetConnection.Connect.NetworkChange':
          case 'NetConnection.Connect.Rejected':
            break;
          case 'NetStream.Publish.BadName':
            //if (_state.publishStartedTime != null) {
              ref.read(stateProvider).retry();
              MyLog.warn("Retry (${_state.retry})");
              _stream?.publish(env.getKey()).then((_) {
                ref.read(stateProvider).running();
                _state2String = '';
                redraw();
              });
            //}
            break;
          case 'NetStream.Publish.Start':
            break;
        }
      });

      if(_stream == null) {
        print('-- initPlatformState() _stream');
        _stream = await RtmpStream.create(_connection!);
      }
      if (_stream != null) {
        _stream!.audioSettings = AudioSettings(muted: false, bitrate: 128 * 1000);
        _stream!.videoSettings = VideoSettings(
          width: (env.camera_height.val * 16 / 9).toInt(),
          height: env.camera_height.val,
          bitrate: env.video_kbps.val * 1024,
        );
        _stream!.attachAudio(AudioSource());
        _stream!.attachVideo(
            VideoSource(position: env.camera_pos.val == 0 ? CameraPosition.back : CameraPosition.front));

        //_stream!.eventChannel.receiveBroadcastStream().listen((event) {
        //  MyLog.info('stream listen event[data]');
        //  MyLog.info('${event["data"]}');
        //});

        redraw();
      }
    }
  }

  /// cameraWidget
  Widget _cameraWidget(BuildContext context) {
    if(IS_TEST){
      print('-- _cameraWidget() IS_TEST');
      double sw = edge.width;
      double sh = edge.height;
      double dw = sw>sh ? sw : sh;
      double dh = sw>sh ? sh : sw;
      double _aspect = sw/sh;

      // 16:10 (Up-down black) or 17:9 (Left-right black)
      // e.g. double _scale = dw/dh < 16.0/9.0 ? dh/dw * 16.0/9.0 : dw/dh * 9.0/16.0;
      double _scale = dw/dh < 16.0/9.0 ? dh/dw * 16.0/9.0 : dw/dh * 9.0/16.0;

      return Center(
        child: Transform.scale(
          scale: _scale,
          child: AspectRatio(
            aspectRatio: _aspect,
            child: kIsWeb ?
            Image.network('/lib/assets/sample.png', fit:BoxFit.cover) :
            Image(image: AssetImage('lib/assets/sample.png')),
          ),
        ),
      );
    } // TEST

    // -- screen=392x825 camera=853x480 aspect=0.56 scale=1.18
    // -- screen=392x825 camera=853x480 aspect=0.56 scale=1.18
    Size _screenSize = MediaQuery.of(context).size;
    Size _cameraSize = Size((env.camera_height.val * 16 / 9), env.camera_height.val.toDouble());
    double sw = _screenSize.width;
    double sh = _screenSize.height;
    double dw = sw>sh ? sw : sh;
    double dh = sw>sh ? sh : sw;
    double _aspect = sw>sh ? 16.0/9.0 : 9.0/16.0;

    // 16:10 (Up-down black) or 17:9 (Left-right black)
    // e.g. double _scale = dw/dh < 16.0/9.0 ? dh/dw * 16.0/9.0 : dw/dh * 9.0/16.0;
    double _scale = dw/dh < _cameraSize.width/_cameraSize.height ? dh/dw * _cameraSize.width/_cameraSize.height : dw/dh * _cameraSize.height/_cameraSize.width;

    print('-- screen=${sw.toInt()}x${sh.toInt()}'
        ' camera=${_cameraSize.width.toInt()}x${_cameraSize.height.toInt()}'
        ' aspect=${_aspect.toStringAsFixed(2)}'
        ' scale=${_scale.toStringAsFixed(2)}');

    if(disableCamera || _stream == null) {
      print('-- if(disableCamera || _stream == null)');
      return Positioned(
          left:0, top:0, right:0, bottom:0,
          child: Container(color: Color(0xFF444444)));
    }

    return Center(
      child: Transform.scale(
        scale: _scale,
        //child: OrientationCamera(
          child: AspectRatio(
            aspectRatio: _aspect,
            child: NetStreamDrawableTexture(_stream),
          ),
        //),
      ),
    );
  }

  /// Switch
  Future<void> _onCameraSwitch(WidgetRef ref) async {
    if(_stream!=null) {
      int pos = env.camera_pos.val==0 ? 1 : 0;
      ref.read(environmentProvider).saveData(env.camera_pos,pos);
      _stream!.attachVideo(VideoSource(position:pos==0 ? CameraPosition.back : CameraPosition.front));
    }
  }

  /// onStart
  Future<bool> onStart() async {
    if (kIsWeb) {
      _batteryLevelStart = await _battery.batteryLevel;
      ref.read(stateProvider).connecting();
    }

    if (env.getUrl() == '') {
      showSnackBar('Error: url is empty');
      return false;
    }

    if (_connection == null || _stream == null) {
      showSnackBar('Error: camera is null');
      return false;
    }

    //_ref.read(retryProvider.state).state = 0;

    try {
      _connection!.connect(env.getUrl());
      _batteryLevelStart = await _battery.batteryLevel;
      ref.read(stateProvider).connecting();
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
      if(_state.publishStartedTime!=null) {
        Duration dur = DateTime.now().difference(_state.publishStartedTime!);
        if(dur.inMinutes>0)
          s += ' ${dur.inMinutes}min';
      }
      if(_batteryLevelStart-_batteryLevel>0) {
        s += ' batt ${_batteryLevelStart}->${_batteryLevel}%';
      }
      MyLog.info(s);
      ref.read(stateProvider).stop();

      if(_connection!=null && _stream!=null)
        _connection!.close();

    } on Exception catch (e) {
      MyLog.err('${e.toString()}');
    }
  }

  /// Timer
  void _onTimer(Timer timer) async {
    if(kIsWeb) return;

    // Retry after publish
    if(_state.connectStartedTime!=null && _state.publishStartedTime!=null && _state.retry>=1) {
      Duration dur = DateTime.now().difference(_state.connectStartedTime!);
      if(dur.inSeconds>=10){
        ref.read(stateProvider).retry();
        _connection!.connect(env.getUrl());
        MyLog.warn("Retry (${_state.retry})");
      }
    }

    // first connect timeout
    if(_state.connectStartedTime!=null && _state.publishStartedTime==null && _state.state==2 && _state.retry==0){
      Duration dur = DateTime.now().difference(_state.connectStartedTime!);
      if(dur.inSeconds>=30){
        onStop();
      }
    }

    // Autostop
    if(_state.state==1 && _state.publishStartedTime!=null) {
      Duration dur = DateTime.now().difference(_state.publishStartedTime!);
      if (env.autostop_sec.val > 0 && dur.inSeconds>env.autostop_sec.val) {
        MyLog.info("Autostop by settings");
        onStop();
        return;
      }
    }

    // check battery (every 1min)
    if(_state.state==1 && DateTime.now().second == 0) {
      this._batteryLevel = await _battery.batteryLevel;
      if (this._batteryLevel < 10) {
        await MyLog.warn("Low battery");
        onStop();
        return;
      }
    }
  } // _onTimer

  void showSnackBar(String msg) {
    if(context!=null) {
      final snackBar = SnackBar(content: Text(msg));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}

final runningStateProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class RunningStateScreen extends ConsumerWidget {
  Timer? _timer;
  late WidgetRef _ref;
  StateData _state = StateData();
  String _stateString = '';
  bool _bInit = false;
  RunningStateScreen(){}

  void init(BuildContext context, WidgetRef ref) {
    if(_bInit == false){
      _bInit = true;
      _timer = Timer.periodic(Duration(seconds:1), _onTimer);
    }
  }

  @override
  void dispose() {
    if(_timer!=null) _timer!.cancel();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    this._ref = ref;
    this._state = ref.watch(stateProvider).state;
    _ref.watch(runningStateProvider);
    Future.delayed(Duration.zero, () => init(context,ref));

    return Text(_stateString,
        textAlign:TextAlign.center,
        style: TextStyle(fontSize:14, color: Colors.white)
    );
  }

  void _onTimer(Timer timer) async {
    String str = 'Stop';
    if (_state.state == 2) {
      if (_state.retry > 0)
        str = 'Retry (${_state.retry})';
      else
        str = 'Connecting';
      Duration dur = DateTime.now().difference(_state.connectStartedTime!);
      if (dur.inSeconds > 0)
        str += ' ${dur.inSeconds}s';
    } else if (_state.state == 1) {
      Duration dur = DateTime.now().difference(_state.publishStartedTime!);
      str = dur2str(dur);
    }
    if (_stateString != str) {
      _stateString = str;
      _ref.read(runningStateProvider).notifyListeners();
    }
  }

  /// 01:00:00
  String dur2str(Duration dur) {
    String s = "";
    if (dur.inHours > 0)
      s += dur.inHours.toString() + ':';
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
        }
    );
  }
}
