import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';
import '/models/camera_model.dart';
/*
import 'package:haishin_kit/audio_settings.dart';
import 'package:haishin_kit/audio_source.dart';
import 'package:haishin_kit/net_stream_drawable_texture.dart';
import 'package:haishin_kit/rtmp_connection.dart';
import 'package:haishin_kit/rtmp_stream.dart';
import 'package:haishin_kit/video_settings.dart';
import 'package:haishin_kit/video_source.dart';
*/
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:apivideo_live_stream/apivideo_live_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import '/constants.dart';
import '/screens/log_screen.dart';
import '/controllers/environment.dart';
import 'dart:async';

final streampack = ChangeNotifierProvider((ref) => StreampackNotifier(ref));

class StreampackNotifier extends ChangeNotifier {
  StateData state = StateData();
  Timer? _timer;
  //RtmpConnection? _connection;
  //RtmpStream? _stream;
  Environment env = new Environment();

  ApiVideoLiveStreamController? _controller;
  bool _isStreaming = false;

  StreampackNotifier(ref) {
    _timer = Timer.periodic(Duration(seconds: 1), onTimer);
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
  }

  void start(Environment env) {
    this.env = env;
    if (kIsWeb) {
      toConnecting();
      return;
    }
    try {
      if (_controller != null) {
        _controller!.startStreaming(streamKey: env.getKey(), url: env.getUrl());
      }
      toConnecting();
    } catch (e) {
      MyLog.err('${e.toString()}');
    }
  }

  void stop() {
    try {
      if (_controller != null) _controller!.stopStreaming();
      toStop();
    } catch (e) {
      MyLog.err('${e.toString()}');
    }
  }

  void reconnect() {
    try {
      if (_controller != null) {
        _controller!.startStreaming(streamKey: env.getKey(), url: env.getUrl());
        toRetrying();
        MyLog.warn("Retry (${state.retry})");
      }
    } catch (e) {
      MyLog.err('${e.toString()}');
    }
  }

  toStop() {
    state.state = 0;
    state.retry = 0;
    state.publishStartedTime = null;
    state.connectStartedTime = null;
    this.notifyListeners();
  }

  toRunning() {
    state.state = 1;
    state.retry = 0;
    state.publishStartedTime = DateTime.now();
    state.connectStartedTime = null;
    this.notifyListeners();
  }

  toConnecting() {
    state.state = 2;
    state.retry = 0;
    state.publishStartedTime = null;
    state.connectStartedTime = DateTime.now();
    this.notifyListeners();
  }

  toRetrying() {
    state.state = 2;
    state.retry += 1;
    state.connectStartedTime = DateTime.now();
    this.notifyListeners();
  }

  switchSaver() {
    state.isSaver = !state.isSaver;
    this.notifyListeners();
  }

  void setIsStreaming(bool isStreaming) {
    _isStreaming = isStreaming;
  }

  Future<void> initController(Environment env) async {
    if (kIsWeb || IS_TEST) return;
    this.env = env;
    await Permission.camera.request();
    await Permission.microphone.request();

    //Params config = Params();
    final VideoConfig video = VideoConfig.withDefaultBitrate();
    video.bitrate = 2000 * 1000; // kb
    final AudioConfig audio = AudioConfig();

    _controller = ApiVideoLiveStreamController(
      initialAudioConfig: audio,
      initialVideoConfig: video,
      initialCameraPosition: CameraPosition.back,
      onConnectionSuccess: () {
        print('---- Connection succeeded');
      },
      onConnectionFailed: (error) {
        print('---- Connection failed: $error');
        //_showDialog(context, 'Connection failed', '$error');
        setIsStreaming(false);
      },
      onDisconnection: () {
        print('---- Disconnected');
        //showInSnackBar('Disconnected');
        setIsStreaming(false);
      },
      onError: (error) {
        print('---- onError $error');
      },
    );

    if (_controller != null) {
      _controller!.initialize().catchError((e) {
        print('---- initialize catchError ${e.toString()}');
      });
    } else {
      print('---- _controller == null');
    }
  }

  /// pos 0=back 1=front
  switchCamera(int pos) {
    if (_controller != null) {
      _controller!.switchCamera();
    }
  }

  changeVideoSettings(Environment env) {
    if (_controller != null) {
      //width: (env.camera_height.val * 16 / 9).toInt(),
      //height: env.camera_height.val,
      //bitrate: env.video_kbps.val * 1024,
    }
  }

  Widget getCameraWidget() {
    if (kIsWeb || _controller == null) {
      return Positioned(left: 0, top: 0, right: 0, bottom: 0, child: Container(color: Color(0xFF444488)));
    } else {
      return Center(child: ApiVideoCameraPreview(controller: _controller!));
    }
  }

  void onTimer(Timer timer) async {
    // Reconnect after publish
    if (state.connectStartedTime != null && state.publishStartedTime != null && state.retry >= 1) {
      Duration dur = DateTime.now().difference(state.connectStartedTime!);
      if (dur.inSeconds >= (15 + state.retry)) {
        reconnect();
      }
    }

    // Timeout on first connection
    if (state.connectStartedTime != null && state.publishStartedTime == null && state.state == 2 && state.retry == 0) {
      Duration dur = DateTime.now().difference(state.connectStartedTime!);
      if (dur.inSeconds >= 30) {
        MyLog.info('Connection timed out');
        stop();
      }
    }
  }
}

class Params {
  final VideoConfig video = VideoConfig.withDefaultBitrate();
  final AudioConfig audio = AudioConfig();

  String rtmpUrl = "rtmp://broadcast.api.video/s/";
  String streamKey = "";

  String getResolutionToString() {
    return "1920x1080";
  }

  String getChannelToString() {
    return 'stereo';
  }

  String getBitrateToString() {
    return "1000 Kbps";
  }

  String getSampleRateToString() {
    return "44.1 kHz";
  }
}
