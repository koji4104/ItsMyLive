import 'package:flutter/material.dart';
import 'settings_screen.dart';

import 'package:native_device_orientation/native_device_orientation.dart';
import 'dart:math';

import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'log_screen.dart';
import 'common.dart';
import 'environment.dart';

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
bool testMode = false;

final cameraScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class CameraScreen extends ConsumerWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isSaver = false;
  StatusData _status = StatusData();
  String _state2String = '';

  Timer? _timer;
  Environment _env = Environment();

  final Battery _battery = Battery();
  int _batteryLevel = -1;
  int _batteryLevelStart = -1;

  bool _bInit = false;
  late WidgetRef _ref;
  late BuildContext _context;
  AppLifecycleState? _appstate;
  MyEdge _edge = MyEdge(provider:cameraScreenProvider);
  RunningStateScreen _RunningState = RunningStateScreen();

  RtmpConnection? _connection;
  RtmpStream? _stream;

  void init(BuildContext context, WidgetRef ref) {
    if(_bInit == false){
      print('-- CameraScreen.init()');
      _bInit = true;
      _timer = Timer.periodic(Duration(seconds:1), _onTimer);
      initPlatformState();
    }
  }

  @override
  void dispose() {
    //if(_controller!=null) _controller!.dispose();
    if(_timer!=null) _timer!.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //setState(() { _appstate = state; });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future.delayed(Duration.zero, () => init(context,ref));
    ref.watch(cameraScreenProvider);
    this._ref = ref;
    this._context = context;
    this._env = ref.watch(environmentProvider).env;
    this._isSaver = ref.watch(isSaverProvider);
    this._status = ref.watch(statusProvider).statsu;
    this._edge.getEdge(context,ref);

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      body: Container(
        margin: _edge.homebarEdge,
        child: Stack(children: <Widget>[

        // screen saver
        if (_isSaver)
          Positioned(
              top:0, bottom:0, left:0, right:0,
              child: TextButton(
                child: Text(''),
                style: ButtonStyle(backgroundColor:MaterialStateProperty.all<Color>(Colors.black)),
                onPressed:(){
                },
              )
          ),

        if(_isSaver==false)
          _cameraWidget(context),

        // Start
        //if (_isSaver==false)
          MyButton(
            top:0.0, bottom: 0.0, right:30,
            icon: Icon(Icons.lens_rounded,
            color: _status.state==2 ? Colors.blueAccent : _status.state==1 ? Colors.redAccent : Colors.white),
            onPressed:(){
              _status.state==0 ? onStart() : onStop();
            },
          ),

        // Switch
        if(_isSaver==false)
          MyButton(
            bottom: 30.0, right: 30.0,
            icon: Icon(Icons.autorenew, color: Colors.white),
            onPressed:() => _onCameraSwitch(ref),
          ),

        // Settings
        if(_isSaver==false)
          MyButton(
            top: 50.0, left: 30.0,
            icon: Icon(Icons.settings, color:Colors.white),
            onPressed:() async {
              int video_kbps = _env.video_kbps.val;
              int camera_height = _env.camera_height.val;
              int video_fps = _env.video_fps.val;

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                )
              );

              if(video_kbps != _env.video_kbps.val
              || camera_height != _env.camera_height.val
              || video_fps != _env.video_fps.val){
                print('-- change env');
                initPlatformState();
              }
            }
          ),

        // State
        //if(_isSaver==false)
          Positioned(
            top:60, left:_edge.width/2-80, right:_edge.width/2-80,
            child:Container(
              padding: EdgeInsets.fromLTRB(10,8,10,8),
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
              bottom:40, left:_edge.width/2-80, right:_edge.width/2-80,
              child:Container(
                padding: EdgeInsets.fromLTRB(10,8,10,8),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_state2String,
                    textAlign:TextAlign.center,
                    style: TextStyle(fontSize:16, color: Colors.white)
                ),
              )
          ),

          // saver
          MyButton(
              bottom: 30.0, left: 30.0,
              icon: Icon(Icons.dark_mode, color:Colors.white),
              onPressed:() {
                _ref.read(isSaverProvider.state).state = !_isSaver;
              }
          ),
        ]
      ),
    ));
  }

  Future<void> initPlatformState() async {
    if(disableCamera) return;
    await Permission.camera.request();
    await Permission.microphone.request();

    // Set up AVAudioSession for iOS.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
      AVAudioSessionCategoryOptions.allowBluetooth,
    ));

    if(_stream != null)
      await _stream!.close();
    if(_connection != null)
      _connection!.close();

    _connection = await RtmpConnection.create();
    if(_connection!=null) {
      _connection!.eventChannel.receiveBroadcastStream().listen((event) {

        String code = event["data"]["code"];
        code = code.replaceAll('NetConnection.', '');
        MyLog.info(code);
        _state2String = code;
        _ref.read(cameraScreenProvider).notifyListeners();

        switch (event["data"]["code"]) {
          case 'NetConnection.Connect.Success':
            _stream?.publish(_env.getKey()).then((_){
              _ref.read(statusProvider).running();
            });
            break;
          case 'NetConnection.Connect.Closed':
            if(_status.startTime != null){
              _ref.read(statusProvider).retry();
            }
            break;
          case 'NetConnection.Connect.Failed':
          case 'NetConnection.Call.BadVersion': break;
          case 'NetConnection.Call.Failed': break;
          case 'NetConnection.Call.Prohibited': break;
          case 'NetConnection.Connect.AppShutdown': break;
          case 'NetConnection.Connect.IdleTimeOut': break;
          case 'NetConnection.Connect.InvalidApp': break;
          case 'NetConnection.Connect.NetworkChange': break;
          case 'NetConnection.Connect.Rejected': break;
        }
      });

      _stream = await RtmpStream.create(_connection!);
      if(_stream!=null) {
        _stream!.audioSettings = AudioSettings(muted:false, bitrate:128 * 1000);
        _stream!.videoSettings = VideoSettings(
          width: (_env.camera_height.val*16/9).toInt(),
          height: _env.camera_height.val,
          bitrate: _env.video_kbps.val * 1024,
        );
        _stream!.attachAudio(AudioSource());
        _stream!.attachVideo(VideoSource(position:_env.camera_pos.val==0 ? CameraPosition.back : CameraPosition.front));
        _stream!.eventChannel.receiveBroadcastStream().listen((event) {
          MyLog.info(event["data"]["code"]);
        });
        _ref.read(cameraScreenProvider).notifyListeners();
      }
    }
  }

  /// cameraWidget
  Widget _cameraWidget(BuildContext context) {
    Size _screenSize = MediaQuery.of(context).size;
    Size _cameraSize = Size(1920,1080);
    double sw = _screenSize.width;
    double sh = _screenSize.height;
    double dw = sw>sh ? sw : sh;
    double dh = sw>sh ? sh : sw;
    double _aspect = sw>sh ? 16.0/9.0 : 9.0/16.0;

    // 16:10 (Up-down black) or 17:9 (Left-right black)
    //double _scale = dw/dh < 16.0/9.0 ? dh/dw * 16.0/9.0 : dw/dh * 9.0/16.0;
    double _scale = dw/dh < _cameraSize.width/_cameraSize.height ? dh/dw * _cameraSize.width/_cameraSize.height : dw/dh * _cameraSize.height/_cameraSize.width;

    print('-- screen=${sw.toInt()}x${sh.toInt()}'
        ' camera=${_cameraSize.width.toInt()}x${_cameraSize.height.toInt()}'
        ' aspect=${_aspect.toStringAsFixed(2)}'
        ' scale=${_scale.toStringAsFixed(2)}');

    if(testMode){
      return Center(
        child: Transform.scale(
          scale: _scale,
          child: AspectRatio(
              aspectRatio: _aspect,
              child: Image.network('/lib/assets/test.png', fit:BoxFit.cover)
          ),
        ),
      );
    }

    if(disableCamera || _stream == null) {
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
      int pos = _env.camera_pos.val==0 ? 1 : 0;
      ref.read(environmentProvider).saveData(_env.camera_pos,pos);
      _stream!.attachVideo(VideoSource(position:pos==0 ? CameraPosition.back : CameraPosition.front));
    }
  }

  /// onStart
  Future<bool> onStart() async {
    if(kIsWeb) {
      _batteryLevelStart = await _battery.batteryLevel;
      _ref.read(statusProvider).connecting();
    }

    if (_env.getUrl() == '') {
      showSnackBar('Error: url is empty');
      return false;
    }

    if(_connection==null || _stream==null) {
      showSnackBar('Error: camera is null');
      return false;
    }

    //_ref.read(retryProvider.state).state = 0;

    try {
      _connection!.connect(_env.getUrl());
      _batteryLevelStart = await _battery.batteryLevel;
      _ref.read(statusProvider).connecting();
      MyLog.info("Start " + _env.getUrl());
    } catch (e) {
      MyLog.err('${e.toString()}');
    }
    return true;
  }

  /// onStop
  Future<void> onStop() async {
    print('-- onStop');
    try {
      if(_status.startTime!=null) {
        String log = 'Stop';
        Duration dur = DateTime.now().difference(_status.startTime!);
        if(dur.inMinutes>0)
          log += ' ' + dur.inMinutes.toString() + 'min';
        await MyLog.info(log);
      }

      this._batteryLevel = await _battery.batteryLevel;
      if(_batteryLevelStart>0 && _batteryLevel>0 && (_batteryLevelStart-_batteryLevel)>0) {
        await MyLog.info("Battery ${_batteryLevelStart}->${_batteryLevel}%");
      }
      _ref.read(statusProvider).stop();

      if(_connection!=null && _stream!=null)
        _connection!.close();

    } on Exception catch (e) {
      MyLog.err('${e.toString()}');
    }
  }

  /// Timer
  void _onTimer(Timer timer) async {
    if(kIsWeb) return;

    //1024000 com.haishinkit.eventchannel/258456858 com.haishinkit.eventchannel/115712075
    //print('-- ${_stream!.videoSettings.bitrate} ${_connection!.eventChannel.name} ${_stream!.eventChannel.name}');

    // connect closed after publish
    if(_status.connectTime!=null && _status.startTime!=null && _status.retry>=1) {
      Duration dur = DateTime.now().difference(_status.connectTime!);
      if(dur.inSeconds>=10){
        _connection!.connect(_env.getUrl());
        _ref.read(statusProvider).retry();
        MyLog.info("Connection retry ${_status.retry}");
      }
    }

    // first connect timeout
    if(_status.connectTime!=null && _status.startTime==null && _status.state==2 && _status.retry==0){
      Duration dur = DateTime.now().difference(_status.connectTime!);
      if(dur.inSeconds>=30){
        onStop();
      }
    }

    // Autostop
    if(_status.state==1 && _status.startTime!=null) {
      Duration dur = DateTime.now().difference(_status.startTime!);
      if (_env.autostop_sec.val > 0 && dur.inSeconds>_env.autostop_sec.val) {
        MyLog.info("Autostop");
        onStop();
        return;
      }
    }

    // check battery (every 1min)
    if(_status.state==1 && DateTime.now().second == 0) {
      this._batteryLevel = await _battery.batteryLevel;
      if (this._batteryLevel < 10) {
        await MyLog.warn("Low battery");
        onStop();
        return;
      }
    }

    if(_status.state==1 && _appstate!=null) {
      if (_appstate == AppLifecycleState.inactive ||
          _appstate == AppLifecycleState.detached) {
        await MyLog.warn("App is stop or background");
        onStop();
        return;
      }
    }
  } // _onTimer

  void showSnackBar(String msg) {
    if(_context!=null) {
      final snackBar = SnackBar(content: Text(msg));
      ScaffoldMessenger.of(_context).showSnackBar(snackBar);
    }
  }

  @override
  bool get wantKeepAlive => true;

  Widget MyButton({required Icon icon, required void Function()? onPressed,
    double? left, double? top, double? right, double? bottom}) {
    return Positioned(
      left:left, top:top, right:right, bottom:bottom,
      child: CircleAvatar(
        backgroundColor: Colors.black54,
        radius: 28.0,
        child: IconButton(
          icon: icon,
          iconSize: 38.0,
          onPressed: onPressed,
        )
      )
    );
  }
}

final runningStateProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class RunningStateScreen extends ConsumerWidget {
  Timer? _timer;
  late WidgetRef _ref;
  StatusData _status = StatusData();
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
    this._status = ref.watch(statusProvider).statsu;
    _ref.watch(runningStateProvider);
    Future.delayed(Duration.zero, () => init(context,ref));

    return Text(_stateString,
        textAlign:TextAlign.center,
        style: TextStyle(fontSize:14, color: Colors.white)
    );
  }

  void _onTimer(Timer timer) async {
    String str = 'Stop';
    if(_status.state==2){
      if(_status.retry>0)
        str = 'Retry${_status.retry}';
      else
        str = 'Connecting';
      Duration dur = DateTime.now().difference(_status.connectTime!);
      if(dur.inSeconds>0)
        str += ' ${dur.inSeconds}s';
    } else if(_status.state==1){
      Duration dur = DateTime.now().difference(_status.startTime!);
      str = dur2str(dur);
    }
    if(_stateString!=str){
      _stateString = str;
      _ref.read(runningStateProvider).notifyListeners();
    }
  }

  /// 01:00:00
  String dur2str(Duration dur) {
    String s = "";
    if(dur.inHours>0)
      s += dur.inHours.toString() + ':';
    s += dur.inMinutes.remainder(60).toString().padLeft(2,'0') + ':';
    s += dur.inSeconds.remainder(60).toString().padLeft(2,'0');
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
          switch(NativeDeviceOrientationReader.orientation(context)) {
            case NativeDeviceOrientation.landscapeRight: angle=pi*1/2; break;
            case NativeDeviceOrientation.landscapeLeft: angle=pi*3/2; break;
            case NativeDeviceOrientation.portraitDown: angle=pi*2/2; break;
            default: break;
          }
          return Transform.rotate(angle: angle, child: child);
        }
    );
  }
}
