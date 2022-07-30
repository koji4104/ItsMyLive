import 'dart:io';
import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'package:flutter/services.dart';

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

final cameraScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class CameraScreen extends ConsumerWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isRunning = false;
  bool _isSaver = false;
  bool _isConnecting = false;
  DateTime? _startTime;

  Timer? _timer;
  Environment _env = Environment();
  Environment _envOld = Environment();

  final Battery _battery = Battery();
  int _batteryLevel = -1;
  int _batteryLevelStart = -1;

  bool _bInit = false;
  late WidgetRef _ref;
  late BuildContext _context;
  AppLifecycleState? _state;
  MyEdge _edge = MyEdge(provider:cameraScreenProvider);

  String strRunningMin = '';

  RtmpConnection? _connection;
  RtmpStream? _stream;

  void init(BuildContext context, WidgetRef ref) {
    if(_bInit == false){
      print('-- CameraScreen.init()');
      _bInit = true;
      _timer = Timer.periodic(Duration(seconds:1), _onTimer);
      _env.load();
      _envOld = _env;
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
    //setState(() { _state = state; });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    this._ref = ref;
    this._context = context;
    Future.delayed(Duration.zero, () => init(context,ref));
    ref.watch(cameraScreenProvider);

    this._isSaver = ref.watch(isSaverProvider);
    this._isRunning = ref.watch(isRunningProvider);
    this._isConnecting = ref.watch(isConnectingProvider);
    _edge.getEdge(context,ref);

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

        // START
        //if (_isSaver==false)
          MyButton(
            bottom: 40.0, left:0, right:0,
            icon: Icon(Icons.lens_rounded,
            color: _isConnecting ? Colors.blueAccent : _isRunning ? Colors.redAccent : Colors.white),
            onPressed:(){
              _isRunning ? onStop() : onStart();
            },
          ),

        // Switch
        if(_isSaver==false)
          MyButton(
            bottom: 40.0, right: 30.0,
            icon: Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed:() => _onCameraSwitch(ref),
          ),

        // Settings
        if(_isSaver==false)
          MyButton(
            top: 50.0, left: 30.0,
            icon: Icon(Icons.settings, color:Colors.white),
            onPressed:() async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                )
              );
              await _env.load();
              if(_envOld.video_kbps.val != _env.video_kbps.val
              || _envOld.camera_height.val != _env.camera_height.val
              || _envOld.video_fps.val != _env.video_fps.val
              || _envOld.getUrl() != _env.getUrl()
              || _envOld.getKey() != _env.getKey() ){
                _envOld = _env;
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
              child: Text(_isConnecting ? 'Connecting' : _isRunning ? strRunningMin : 'Stop',
                textAlign:TextAlign.center,
                style: TextStyle(fontSize:16,
                    color: _isConnecting ? Colors.blueAccent : _isRunning ? Colors.redAccent : Colors.white)
              )
            )
          ),

          // saver
          MyButton(
              bottom: 40.0, left: 30.0,
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
        switch (event["data"]["code"]) {
          case 'NetConnection.Connect.Success':
            _stream?.publish(_env.getKey()).then((_){
              _startTime = DateTime.now();
              _ref.read(isConnectingProvider.state).state = false;
            });
            break;
        }
      });

      _stream = await RtmpStream.create(_connection!);
      if(_stream!=null) {
        _stream!.audioSettings = AudioSettings(muted: false, bitrate: 128 * 1000);
        _stream!.videoSettings = VideoSettings(
          width: (_env.camera_height.val*16/9).toInt(),
          height: _env.camera_height.val,
          bitrate: _env.video_kbps.val * 1024,
        );
        _stream!.attachAudio(AudioSource());
        _stream!.attachVideo(VideoSource(position:_env.camera_pos.val==0 ? CameraPosition.back : CameraPosition.front));
        _ref.read(cameraScreenProvider).notifyListeners();
      }
    }
  }

  /// cameraWidget
  Widget _cameraWidget(BuildContext context) {
    if(disableCamera || _stream == null) {
      return Positioned(
        left:0, top:0, right:0, bottom:0,
        child: Container(color: Color(0xFF888888)));
    }

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
      _env.camera_pos.set(pos);
      _env.save(_env.camera_pos);
      _stream!.attachVideo(VideoSource(position:pos==0 ? CameraPosition.back : CameraPosition.front));
    }
  }

  /// onStart
  Future<bool> onStart() async {
    if(kIsWeb) {
      _startTime = DateTime.now();
      _batteryLevelStart = await _battery.batteryLevel;
      _ref.read(isRunningProvider.state).state = true;
      _ref.read(isConnectingProvider.state).state = true;
      showSnackBar('onStart');
    }

    if (_env.getUrl() == '') {
      showSnackBar('Error: url is empty');
      return false;
    }

    if(_connection==null || _stream==null) {
      showSnackBar('Error: camera is null');
      return false;
    }

    try {
      _connection!.connect(_env.getUrl());

      MyLog.info("Start " + _env.getUrl());
      //_startTime = DateTime.now();
      _batteryLevelStart = await _battery.batteryLevel;
      _ref.read(isRunningProvider.state).state = true;
      _ref.read(isConnectingProvider.state).state = true;
    } catch (e) {
      await MyLog.err('${e.toString()}');
    }
    return true;
  }

  /// onStop
  Future<void> onStop() async {
    print('-- onStop');
    try {
      String log = 'Stop';
      if(_startTime!=null) {
        Duration dur = DateTime.now().difference(_startTime!);
        log += ' ' + dur.inMinutes.toString() + 'min';
      }
      await MyLog.info(log);

      if(_batteryLevelStart>0 && _batteryLevelStart - _batteryLevel<0) {
        await MyLog.info("Battery ${_batteryLevelStart}->${_batteryLevel}%");
      }

      _startTime = null;
      _ref.read(isRunningProvider.state).state = false;
      _ref.read(isConnectingProvider.state).state = false;

      if(_connection==null || _stream==null)
        return;

      _connection!.close();

    } on Exception catch (e) {
      MyLog.err('${e.toString()}');
    }
  }

  /// タイマー
  void _onTimer(Timer timer) async {
    if(kIsWeb) return;
    if(this._batteryLevel<0)
      this._batteryLevel = await _battery.batteryLevel;

    if(_startTime == null) {
      return;
    }

    String min = getRunningMin();
    if(strRunningMin != min){
      strRunningMin = min;
      _ref.read(cameraScreenProvider).notifyListeners();
    }

    Duration dur = DateTime.now().difference(_startTime!);

    // 30秒後に成功してないときSTOP
    //if(_isRunning==true && _isConnecting==true) {
    //  if(dur.inSeconds > 30){
    //    onStop();
    //    return;
    //  }
    //}
    
    // 自動停止
    if(_isRunning==true && _startTime!=null) {
      if (_env.autostop_sec.val > 0 && dur.inSeconds>_env.autostop_sec.val) {
        await MyLog.info("Autostop");
        onStop();
        return;
      }
    }

    // バッテリーチェック（1分毎）
    if(_isRunning==true && DateTime.now().second == 0) {
      this._batteryLevel = await _battery.batteryLevel;
      if (this._batteryLevel < 10) {
        await MyLog.warn("Low battery");
        onStop();
        return;
      }
    }

    if(_isRunning==true && _state!=null) {
      if (_state == AppLifecycleState.inactive ||
          _state == AppLifecycleState.detached) {
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

  String getRunningMin() {
    String s = '';
    if (_startTime != null) {
      Duration dur = DateTime.now().difference(_startTime!);
      if(dur.inSeconds<60)
        s = dur.inSeconds.toString() + ' sec';
      else
        s = dur.inMinutes.toString() + ' min';
    }
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

final screenSaverProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class ScreenSaver extends ConsumerWidget {
  Timer? _timer;
  WidgetRef? _ref;
  Environment _env = Environment();

  ScreenSaver(){
  }

  void init(WidgetRef ref) {
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    this._ref = ref;
    Future.delayed(Duration.zero, () => init(ref));
    ref.watch(screenSaverProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(children: <Widget>[
        Positioned(
          top:0, bottom:0, left:0, right:0,
          child: TextButton(
            child: Text(''),
            style: ButtonStyle(backgroundColor:MaterialStateProperty.all<Color>(Colors.black)),
            onPressed:(){
            },
          )
        ),

        // STOPボタン
        Center(
          child: Container(
            width: 160, height: 160,
            child: StopButton(
              onPressed:(){
                ref.read(isSaverProvider.state).state = false;
                ref.read(isRunningProvider.state).state = false;
              }
            )
          ),),
        ]
      )
    );
  }

  void _onTimer(Timer timer) async {
    try {
    } on Exception catch (e) {
      print('-- ScreenSaver _onTimer() Exception '+e.toString());
    }
  }

  Widget StopButton({required void Function()? onPressed}) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.black26,
        shape: const CircleBorder(
          side: BorderSide(
            color: COL_SS_TEXT,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: Text('STOP', style:TextStyle(fontSize:16, color:COL_SS_TEXT)),
      onPressed: onPressed,
    );
  }
}