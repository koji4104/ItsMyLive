import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/constants.dart';

class EnvData {
  int val;
  String key = '';
  List<int> vals = [];
  List<String> keys = [];
  String name = '';

  EnvData(
      {required int this.val,
      required List<int> this.vals,
      required List<String> this.keys,
      required String this.name}) {
    set(val);
  }

  void set(int? v) {
    if (v == null || vals.length == 0 || keys.length == 0) return;
    val = vals[vals.length - 1];
    key = keys[keys.length - 1];
    for (var i = 0; i < vals.length; i++) {
      if (v <= vals[i]) {
        val = vals[i];
        key = keys[i];
        break;
      }
    }
  }
}

/// Environment
class Environment {
  EnvData stream_mode = EnvData(
    val: 1,
    vals: [1, 2],
    keys: ['rtmp', 'srt'],
    name: 'stream_mode',
  );

  EnvData autostop_sec = EnvData(
    val: 0,
    vals: IS_TEST ? [0, 120, 3600] : [0, 3600, 7200, 14400, 21600],
    keys: IS_TEST
        ? ['Nonstop', '2 min', '1 hour']
        : ['Nonstop', '1 hour', '2 hour', '4 hour', '6 hour'],
    name: 'autostop_sec',
  );

  EnvData video_fps = EnvData(
    val: 30,
    vals: [24, 25, 30, 60],
    keys: ['24', '25', '30', '60'],
    name: 'video_fps',
  );

  EnvData video_kbps = EnvData(
    val: 1000,
    vals: [500, 1000, 2000, 4000, 8000],
    keys: ['500 kbps', '1 mbps', '2 mbps', '4 mbps', '8 mbps'],
    name: 'video_kbps',
  );

  EnvData camera_height = EnvData(
    val: 720,
    vals: [360, 480, 720, 1080, 1440, 2160],
    keys: ['640x360', '854x480', '1280x720', '1920x1080', '2560x1440', '3840x2160'],
    name: 'camera_height',
  );

  int getCameraWidth() {
    if (camera_height.val == 480)
      return 854;
    else
      return (camera_height.val * 16.0 / 9.0).toInt();
  }

  // 0=back, 1=Front(Face)
  EnvData camera_pos = EnvData(
    val: 0,
    vals: [0, 1],
    keys: ['back', 'front'],
    name: 'camera_pos',
  );

  /// Selected Url 1-4 (Not 0)
  EnvData url_num = EnvData(
    val: 1,
    vals: [1, 2, 3, 4],
    keys: ['1', '2', '3', '4'],
    name: 'url_num',
  );

  String url1 = '';
  String key1 = '';
  String url2 = '';
  String key2 = '';
  String url3 = '';
  String key3 = '';
  String url4 = '';
  String key4 = '';

  String getUrl({int? num}) {
    String r = url1;
    int i = (num == null) ? url_num.val : num;
    switch (i) {
      case 1:
        r = url1;
        break;
      case 2:
        r = url2;
        break;
      case 3:
        r = url3;
        break;
      case 4:
        r = url4;
        break;
    }
    return r;
  }

  String getKey({int? num}) {
    String r = key1;
    int i = (num == null) ? url_num.val : num;
    switch (i) {
      case 1:
        r = key1;
        break;
      case 2:
        r = key2;
        break;
      case 3:
        r = key3;
        break;
      case 4:
        r = key4;
        break;
    }
    return r;
  }

  void setUrl({required int num, required String url}) {
    switch (num) {
      case 1:
        url1 = url;
        break;
      case 2:
        url2 = url;
        break;
      case 3:
        url3 = url;
        break;
      case 4:
        url4 = url;
        break;
    }
  }

  void setKey({required int num, required String key}) {
    switch (num) {
      case 1:
        key1 = key;
        break;
      case 2:
        key2 = key;
        break;
      case 3:
        key3 = key;
        break;
      case 4:
        key4 = key;
        break;
    }
  }
}

final environmentProvider = ChangeNotifierProvider((ref) => environmentNotifier(ref));

class environmentNotifier extends ChangeNotifier {
  Environment env = Environment();

  environmentNotifier(ref) {
    load().then((_) {
      this.notifyListeners();
    });
  }

  Future load() async {
    print('-- Environment.load()');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _loadSub(prefs, env.url_num);
      _loadSub(prefs, env.video_fps);
      _loadSub(prefs, env.video_kbps);
      _loadSub(prefs, env.autostop_sec);
      _loadSub(prefs, env.camera_height);
      _loadSub(prefs, env.camera_pos);

      env.url1 = prefs.getString('url1') ?? '';
      env.key1 = prefs.getString('key1') ?? '';
      env.url2 = prefs.getString('url2') ?? '';
      env.key2 = prefs.getString('key2') ?? '';
      env.url3 = prefs.getString('url3') ?? '';
      env.key3 = prefs.getString('key3') ?? '';
      env.url4 = prefs.getString('url4') ?? '';
      env.key4 = prefs.getString('key4') ?? '';

      if (IS_TEST) {
        env.url_num.val = 1;
        env.url1 = "srt://10.221.58.62:5000";
        env.key1 = "";
        print('-- load() IS_TEST');
      } else {
        print('-- load() camera_height.val=${env.camera_height.val}');
      }
    } on Exception catch (e) {
      print('-- load() err=' + e.toString());
    }
  }

  _loadSub(SharedPreferences prefs, EnvData data) {
    data.set(prefs.getInt(data.name) ?? data.val);
  }

  Future saveData(String name, int newVal) async {
    EnvData data = getData(name);
    if (data.val == newVal) return;
    data.set(newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
    this.notifyListeners();
  }

  EnvData getData(String name) {
    EnvData ret = env.stream_mode;
    switch (name) {
      case 'video_fps':
        ret = env.video_fps;
        break;
      case 'video_kbps':
        ret = env.video_kbps;
        break;
      case 'autostop_sec':
        ret = env.autostop_sec;
        break;
      case 'camera_height':
        ret = env.camera_height;
        break;
      case 'camera_pos':
        ret = env.camera_pos;
        break;
      case 'url_num':
        ret = env.url_num;
        break;
      default:
        print('-- getData() no key name');
        break;
    }
    return ret;
  }

  Future saveUrl(int num, String url) async {
    if (num < 1 && 4 < num) return;
    if (env.getUrl(num: num) == url) return;
    env.setUrl(num: num, url: url);
    String name = 'url' + num.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(name, url);
    this.notifyListeners();
  }

  Future saveKey(int num, String key) async {
    if (num < 1 && 4 < num) return;
    if (env.getKey(num: num) == key) return;
    env.setKey(num: num, key: key);
    String name = 'key' + num.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(name, key);
    this.notifyListeners();
  }
}
