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

import 'package:flutter/foundation.dart' show kIsWeb;
import '/constants.dart';
import '/screens/log_screen.dart';
import '/controllers/environment.dart';
import 'dart:async';

final stateProvider = ChangeNotifierProvider((ref) => StateNotifier(ref));

class StateNotifier extends ChangeNotifier {
  StateData state = StateData();
  Timer? _timer;
  //RtmpConnection? _connection;
  //RtmpStream? _stream;
  Environment env = new Environment();

  StateNotifier(ref) {
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
    //try {
    //  if (_connection != null) _connection!.connect(env.getUrl());
    //  toConnecting();
    //} catch (e) {
    //  MyLog.err('${e.toString()}');
    //}
  }

  void stop() {
    try {
      //if (_connection != null) _connection!.close();
      toStop();
    } catch (e) {
      MyLog.err('${e.toString()}');
    }
  }

  void reconnect() {
    try {
      //if (_connection != null) {
      //  _connection!.connect(env.getUrl());
      toRetrying();
      MyLog.warn("Retry (${state.retry})");
      //}
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

  Future<void> initHaishinKit(Environment env) async {
    if (kIsWeb || IS_TEST) return;
    this.env = env;
    await Permission.camera.request();
    await Permission.microphone.request();

    // Set up AVAudioSession for iOS.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
    ));

    //if (_connection == null) {
    //  print('-- initPlatformState() _connection create');
    //  _connection = await RtmpConnection.create();
    //}
    /*

    if (_connection != null) {
      StreamSubscription _streamSubscription = _connection!.eventChannel.receiveBroadcastStream().listen((event) {
        String code = event["data"]["code"];
        String desc = event["data"]["description"];
        String s = (desc.length > 0) ? '${code} (${desc})' : '${code}';
        MyLog.debug(s);

        switch (event["data"]["code"]) {
          case 'NetConnection.Connect.Success':
            if (_stream != null) _stream!.publish(env.getKey());
            break;
          case 'NetConnection.Connect.Closed':
            if (state.publishStartedTime != null) {
              reconnect();
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
            if (_stream != null) _stream!.publish(env.getKey());
            break;
          case 'NetStream.Publish.Start':
            toRunning();
            break;
        }
      });

      if (_stream == null) {
        print('-- initPlatformState() _stream');
        _stream = await RtmpStream.create(_connection!);
      }
      if (_stream != null) {
        _stream!.audioSettings = AudioSettings(bitrate: 128 * 1000);
        _stream!.videoSettings = VideoSettings(
          width: (env.camera_height.val * 16 / 9).toInt(),
          height: env.camera_height.val,
          bitrate: env.video_kbps.val * 1024,
        );
        _stream!.attachAudio(AudioSource());
        _stream!
            .attachVideo(VideoSource(position: env.camera_pos.val == 0 ? CameraPosition.back : CameraPosition.front));
        this.notifyListeners();
      }
    }
    */
  }

  /// pos 0=back 1=front
  switchCamera(int pos) {
    //if (_stream != null) {
    //  _stream!.attachVideo(VideoSource(position: pos == 0 ? CameraPosition.back : CameraPosition.front));
    //}
  }

  changeVideoSettings(Environment env) {
/*
    if (_stream != null) {
      _stream!.videoSettings = VideoSettings(
        width: (env.camera_height.val * 16 / 9).toInt(),
        height: env.camera_height.val,
        bitrate: env.video_kbps.val * 1024,
      );
    }
*/
  }

  /*
  Widget getCameraWidget() {
    if (kIsWeb || _stream == null) {
      return Positioned(left: 0, top: 0, right: 0, bottom: 0, child: Container(color: Color(0xFF444444)));
    } else {
      return Center(child: NetStreamDrawableTexture(_stream));
    }
  }
  */

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
