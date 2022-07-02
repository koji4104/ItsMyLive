import 'dart:io';
//import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'settings_screen.dart';
import 'package:flutter/services.dart';
import 'package:wakelock/wakelock.dart';

import 'package:intl/intl.dart';
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'log_screen.dart';
import 'common.dart';

import 'types/params.dart';
import 'package:apivideo_live_stream/apivideo_live_stream.dart';

bool disableCamera = kIsWeb; // true=test
final bool _testMode = true;

final cameraScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());

class CameraScreen extends ConsumerWidget {
  //CameraController? _controller;
  LiveStreamController? _controller;

  //List<CameraDescription> _cameras = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isRunning = false;
  bool _isSaver = false;
  bool _isConnecting = false;

  DateTime? _startTime;
  //DateTime? _recordTime;

  Timer? _timer;
  Environment _env = Environment();
  Environment _envOld = Environment();

  final Battery _battery = Battery();
  int _batteryLevel = -1;
  int _batteryLevelStart = -1;

  bool bInit = false;
  WidgetRef? _ref;
  BuildContext? _context;
  AppLifecycleState? _state;

  MyEdge _edge = MyEdge(provider:cameraScreenProvider);

  Params config = Params();
  int textureId = 0;

  void init(BuildContext context, WidgetRef ref) {
    if(bInit == false){
      bInit = true;
      _timer = Timer.periodic(Duration(seconds:1), _onTimer);
      _initCameraSync();
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

    if(_isSaver) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays:[]);
      Wakelock.enable();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays:[]);
      Wakelock.disable();
    }

    _edge.getEdge(context,ref);

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      body: Container(
        margin: _edge.homebarEdge,
        child: Stack(children: <Widget>[

        // screen saver
        if (_isSaver)
          ScreenSaver(startTime:_startTime),

        if(_isSaver==false)
          _cameraWidget(context),

        // START
        if (_isSaver==false)
          MyButton(
            bottom: 40.0, left:0, right:0,
            icon: Icon(Icons.lens_rounded,
            color: _isConnecting ? Colors.blue : _isRunning ? Colors.red : Colors.white),
            onPressed:(){
              _isRunning ? onStop() : onStart();
            },
          ),

        // Camera Switch button
        if(_isSaver==false)
          MyButton(
            bottom: 40.0, right: 30.0,
            icon: Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed:() => _onCameraSwitch(ref),
          ),

        // Settings screen button
        if(_isSaver==false)
          MyButton(
            top: 40.0, left: 30.0,
            icon: Icon(Icons.settings, color:Colors.white),
            onPressed:() async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                )
              );
              _initCameraSync();
              //await _env.load();
              /*
              if(_preset != getPreset()){
                print('-- change camera ${_env.camera_height.val}');
                _preset = getPreset();
                _initCameraSync(ref);
              }
              */
            }
          ),
        ]
      ),
    ));
  }

  /// カメラウィジェット
  Widget _cameraWidget(BuildContext context) {
    if(disableCamera) {
      return Positioned(
        left:0, top:0, right:0, bottom:0,
        child: Container(color: Color(0xFF666688)));
    }
    if (_controller == null) {
      return Center(
        child: SizedBox(
          width:32, height:32,
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Center(
      child: CameraPreview(controller: _controller!),
    );
  }

  /// カメラ初期化
  Future<void> _initCameraSync() async {
    if(disableCamera) return;
    print('-- _initCameraSync');

    await _env.load();
    VideoConfig vconf = VideoConfig.withDefaultBitrate();
    vconf.resolution = getResolution();
    vconf.bitrate = _env.video_kbps.val * 1000;
    vconf.fps = _env.video_fps.val;

    AudioConfig aconf = AudioConfig();
    aconf.bitrate = 128*1000;
    aconf.channel = Channel.stereo;
    aconf.sampleRate = SampleRate.kHz_44_1;
    aconf.enableEchoCanceler = true;
    aconf.enableNoiseSuppressor = true;

    if(_controller==null) {
      _envOld = _env;
      _controller = initLiveStreamController();
      _controller!.create(
        initialVideoConfig:vconf,
        initialAudioConfig:aconf,
      ).then((_) {
        if(_ref!=null)
          _ref!.read(cameraScreenProvider).notifyListeners();
      });
    } else if(_envOld.camera_height != _env.camera_height
      || _envOld.video_fps != _env.video_fps
      || _envOld.video_kbps != _env.video_kbps
    ) {
      _envOld = _env;
      _controller!.setVideoConfig(vconf).then((_) {
        if(_ref!=null)
          _ref!.read(cameraScreenProvider).notifyListeners();
      });
    }
  }

  LiveStreamController initLiveStreamController() {
    return LiveStreamController(
      onConnectionSuccess:() {
        print('-- Connection succedded');
      },
      onConnectionFailed:(error) {
        MyLog.warn("Failed $error");
      },
      onDisconnection:() {
        MyLog.warn("Disconnected");
      }
    );
  }

  Resolution getResolution() {
    Resolution r = Resolution.RESOLUTION_360;
    int h = _env.camera_height.val;
    if(h>=1080) r = Resolution.RESOLUTION_1080;
    else if(h>=720) r = Resolution.RESOLUTION_720;
    else if(h>=480) r = Resolution.RESOLUTION_480;
    else if(h>=360) r = Resolution.RESOLUTION_360;
    else if(h>=240) r = Resolution.RESOLUTION_240;
    return r;
  }

  /// スイッチ
  Future<void> _onCameraSwitch(WidgetRef ref) async {
    if(_controller!=null)
      _controller!.switchCamera();
  }

  /// 開始
  Future<bool> onStart() async {
    if(kIsWeb) {
      _isRunning = true;
      _startTime = DateTime.now();
      _batteryLevelStart = await _battery.batteryLevel;
      if(_ref!=null) {
        //_ref!.read(isSaverProvider.state).state = true;
        _ref!.read(isRunningProvider.state).state = true;
        _ref!.read(isConnectingProvider.state).state = true;
      }
      showSnackBar('onStart');
    }

    if (_controller == null) {
      print('-- err _controller!.value.isInitialized==false');
      return false;
    }

    _isRunning = true;
    _startTime = DateTime.now();
    _batteryLevelStart = await _battery.batteryLevel;

    // 先にセーバー起動
    if(_ref!=null) {
      _ref!.read(isRunningProvider.state).state = true;
      _ref!.read(isConnectingProvider.state).state = true;
      //_ref!.read(isRunningProvider.state).state = true;
    }

    startStreaming();
    MyLog.info("Start");

    return true;
  }

  /// 停止
  Future<void> onStop() async {
    print('-- onStop');
    try {
      await MyLog.info("Stop " + recordingTimeString());

      if(_batteryLevelStart>0) {
        await MyLog.info("Battery ${_batteryLevelStart}->${_batteryLevel}%");
      }
      _isRunning = false;
      _startTime = null;

      if(_ref!=null){
        _ref!.read(isRunningProvider.state).state = false;
        _ref!.read(isConnectingProvider.state).state = false;
      }
      _controller!.stop();

    } on Exception catch (e) {
      print('-- onStop() Exception ' + e.toString());
    }
  }

  // 開始
  Future<void> startStreaming() async {
    if(kIsWeb) return;

    if (_controller == null) {
      showSnackBar('Error: create a camera controller first.');
      return;
    }
    try {
      await _controller!.startStreaming(
        url: _env.getUrl(), streamKey: _env.getKey());

    } catch (e) {
      await MyLog.err('${e.toString()}');
    }
  }

  // 停止
  Future<void> stopStreaming() async {
    if (_controller == null) {
      return;
    }
    try {
      _controller!.stopStreaming();
    } catch (e) {
      await MyLog.err('${e.toString()}');
    }
  }

  /// タイマー
  void _onTimer(Timer timer) async {
    if(this._batteryLevel<0)
      this._batteryLevel = await _battery.batteryLevel;

    // セーバーで停止ボタンを押したとき
    if(_isRunning==false && _startTime!=null) {
      onStop();
      return;
    }

    // Connecting -> Running
    if(_isRunning==true && _isConnecting==true && _controller!.isStreaming==true){
      _ref!.read(isConnectingProvider.state).state = false;
    }

    Duration dur = DateTime.now().difference(_startTime!);

    // 30秒後に成功してないときSTOP
    if(_isRunning==true && _controller!.isStreaming==false){
      if(dur.inSeconds > 30){
        onStop();
        return;
      }
    }
    
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
      ScaffoldMessenger.of(_context!).showSnackBar(snackBar);
    }
  }

  void logError(String code, String? message) {
    print('-- Error Code: $code\n-- Error Message: $message');
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

  Color getStartButtonColor(){
    Color col =  Colors.white;
    if(_controller!=null){
      if(_isRunning && _controller!.isStreaming)
        col = Colors.red;
    }
    return col;
  }

  Widget StartButton({required void Function()? onPressed}) {
    return Center(
      child: Container(
        width: 160, height: 160,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.black26,
            shape: const CircleBorder(
              side: BorderSide(
                color: Colors.white,
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
          ),
          child:Text('START', style:TextStyle(fontSize:16, color:Colors.white)),
          onPressed: onPressed,
        )
      )
    );
  }

  /// 録画時間の文字列
  String recordingTimeString() {
    String s = '';
    if(_startTime!=null) {
      Duration dur = DateTime.now().difference(_startTime!);
      s = dur2str(dur);
    }
    return s;
  }

  String dur2str(Duration dur) {
    String s = "";
    if(dur.inHours>0)
      s += dur.inHours.toString() + ':';
    s += dur.inMinutes.remainder(60).toString().padLeft(2,'0') + ':';
    s += dur.inSeconds.remainder(60).toString().padLeft(2,'0');
    return s;
  }
}

final screenSaverProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class ScreenSaver extends ConsumerWidget {
  Timer? _timer;
  DateTime? _waitTime;
  DateTime? _startTime;
  WidgetRef? _ref;
  Environment _env = Environment();
  bool _isRunning = true;
  bool bInit = false;

  ScreenSaver({DateTime? startTime}){
    this._startTime = startTime;
    this._waitTime = DateTime.now();
  }

  void init(WidgetRef ref) {
    if(bInit==false){
      bInit = true;
      _env.load();
      _timer = Timer.periodic(Duration(seconds:1), _onTimer);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    this._ref = ref;
    Future.delayed(Duration.zero, () => init(ref));
    ref.watch(screenSaverProvider);
    _isRunning = ref.read(isRunningProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(children: <Widget>[
        Positioned(
          top:0, bottom:0, left:0, right:0,
          child: TextButton(
            child: Text(''),
            style: ButtonStyle(backgroundColor:MaterialStateProperty.all<Color>(Colors.black)),
            onPressed:(){
              _waitTime = DateTime.now();
            },
          )
        ),

        // STOPボタン
        if(_waitTime!=null)
          Center(
            child: Container(
              width: 160, height: 160,
              child: StopButton(
                onPressed:(){
                  _waitTime = null;
                  ref.read(isSaverProvider.state).state = false;
                  ref.read(isRunningProvider.state).state = false;
                }
              )
            )
          ),

        // 録画中
        if(_waitTime!=null)
          Positioned(
            bottom:60, left:0, right:0,
            child: Text(
              runningString(),
              textAlign:TextAlign.center,
              style:TextStyle(color:COL_SS_TEXT),
          )),

        // 経過時間
        if(_waitTime!=null)
          Positioned(
            bottom:40, left:0, right:0,
            child: Text(
              elapsedTimeString(),
              textAlign:TextAlign.center,
              style:TextStyle(color:COL_SS_TEXT),
          )),
        ]
      )
    );
  }

  void _onTimer(Timer timer) async {
    try {
      if(_waitTime!=null) {
        if(DateTime.now().difference(_waitTime!).inSeconds > 5)
          _waitTime = null;
        if(_ref!=null)
          _ref!.read(screenSaverProvider).notifyListeners();
      }
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

  String runningString() {
    String s = '';
    if(_timer==null){
      s = '';
    } else if(_isRunning==false){
      s = 'Stoped';
    } else {
      s = 'Now Publishing';
    }
    return s;
  }

  String elapsedTimeString(){
    String s = '';
    if(_startTime!=null && _isRunning) {
      Duration dur = DateTime.now().difference(_startTime!);
      s = dur2str(dur);
    }
    return s;
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