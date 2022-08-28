import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localizations.dart';
import 'log_screen.dart';
import 'common.dart';

class EnvData {
  int val;
  String key = '';
  List<int> vals = [];
  List<String> keys = [];
  String name = '';

  EnvData({
    required int this.val,
    required List<int> this.vals,
    required List<String> this.keys,
    required String this.name}){
    set(val);
  }

  // 選択肢と同じものがなければひとつ大きいいものになる
  set(int? newval) {
    if (newval==null)
      return;
    if (vals.length > 0) {
      val = vals[0];
      for (var i=0; i<vals.length; i++) {
        if (newval <= vals[i]) {
          val = vals[i];
          if(keys.length>=i)
            key = keys[i];
          break;
        }
      }
    }
  }
}

/// Environment
class Environment {
  /// mode 1=rtmp (1 only)
  EnvData publish_mode = EnvData(
    val:1,
    vals:[1,2],
    keys:['rtmp',''],
    name:'publish_mode',
  );

  EnvData autostop_sec = EnvData(
    val:3600,
    vals:[60,3600,7200,10800,14400,21600],
    keys:['60 sec','1','2','3','4','6'],
    name:'autostop_sec',
  );

  EnvData video_fps = EnvData(
    val:30,
    vals:[24, 25, 30],
    keys:['24','25','30'],
    name:'video_fps',
  );

  EnvData video_kbps = EnvData(
    val:1000,
    vals:[500,1000,2000,4000,8000],
    keys:['500 kbps','1000 kbps','2000 kbps','4000 kbps','8000 kbps'],
    name:'video_kbps',
  );

  EnvData camera_height = EnvData(
    val:720,
    vals:[360,480,720,1080,1440,2160],
    keys:['640x360','854x480','1280x720','1920x1080','2560x1440','3840x2160'],
    name:'camera_height',
  );

  // 0=back, 1=Front(Face)
  EnvData camera_pos = EnvData(
    val:0,
    vals:[0,1],
    keys:['back','front'],
    name:'camera_pos',
  );

  EnvData url_num = EnvData(
    val:1,
    vals:[1,2,3,4],
    keys:['1','2','3','4'],
    name:'url_num',
  );

  String url1 = 'rtmp://';
  String key1 = '';
  String url2 = 'rtmp://';
  String key2 = '';
  String url3 = 'rtmp://';
  String key3 = '';
  String url4 = 'rtmp://';
  String key4 = '';

  String getUrl({int? num}){
    String r = url1;
    int i = (num==null) ? url_num.val : num;
    switch(i){
      case 1: r = url1; break;
      case 2: r = url2; break;
      case 3: r = url3; break;
      case 4: r = url4; break;
    }
    return r;
  }

  String getKey({int? num}){
    String r = key1;
    int i = (num==null) ? url_num.val : num;
    switch(i){
      case 1: r = key1; break;
      case 2: r = key2; break;
      case 3: r = key3; break;
      case 4: r = key4; break;
    }
    return r;
  }

  void setUrl({required int num, required String url}){
    switch(num){
      case 1: url1 = url; break;
      case 2: url2 = url; break;
      case 3: url3 = url; break;
      case 4: url4 = url; break;
    }
  }

  void setKey({required int num, required String key}){
    switch(num){
      case 1: key1 = key; break;
      case 2: key2 = key; break;
      case 3: key3 = key; break;
      case 4: key4 = key; break;
    }
  }

  Future load() async {
    //if(kIsWeb) return;
    print('-- Environment.load()');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _loadSub(prefs, url_num);
      _loadSub(prefs, video_fps);
      _loadSub(prefs, video_kbps);
      _loadSub(prefs, autostop_sec);
      _loadSub(prefs, camera_height);
      _loadSub(prefs, camera_pos);
      _loadSub(prefs, publish_mode);

      url1 = prefs.getString('url1') ?? '';
      key1 = prefs.getString('key1') ?? '';
      url2 = prefs.getString('url2') ?? '';
      key2 = prefs.getString('key2') ?? '';
      url3 = prefs.getString('url3') ?? '';
      key3 = prefs.getString('key3') ?? '';
      url4 = prefs.getString('url4') ?? '';
      key4 = prefs.getString('key4') ?? '';
    } on Exception catch (e) {
      print('-- load() e=' + e.toString());
    }
  }
  _loadSub(SharedPreferences prefs, EnvData data) {
    data.set(prefs.getInt(data.name) ?? data.val);
  }

  Future save(EnvData data) async {
    //if(kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
  }

  Future saveUrl(String url, int num) async {
    //if(kIsWeb) return;
    if(num<1 && 4<num) return;
    String name = 'url' + num.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(name, url);
  }

  Future saveKey(String key, int num) async {
    //if(kIsWeb) return;
    if(num<1 && 4<num) return;
    String name = 'key' + num.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(name, key);
  }
}

final environmentProvider = ChangeNotifierProvider((ref) => environmentNotifier(ref));
class environmentNotifier extends ChangeNotifier {
  Environment env = Environment();

  environmentNotifier(ref){
    env.load().then((_){
      this.notifyListeners();
    });
  }

  Future saveData(EnvData data, int newVal) async {
    if(data.val == newVal)
      return;
    roundVal(data, newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
    this.notifyListeners();
  }

  roundVal(EnvData data, int newVal){
    for (var i=0; i<data.vals.length; i++){
      if (newVal <= data.vals[i]){
        getData(data).val = data.vals[i];
        getData(data).key = data.keys[i];
        return;
      }
    }
    getData(data).val = data.vals[0];
    getData(data).key = data.keys[0];
  }

  EnvData getData(EnvData data){
    EnvData ret = env.publish_mode;
    switch(data.name){
      case 'url_num': ret = env.url_num; break;
      case 'video_fps': ret = env.video_fps; break;
      case 'video_kbps': ret = env.video_kbps; break;
      case 'autostop_sec': ret = env.autostop_sec; break;
      case 'camera_height': ret = env.camera_height; break;
      case 'camera_pos': ret = env.camera_pos; break;
      case 'publish_mode': ret = env.publish_mode; break;
    }
    return ret;
  }

  Future saveUrl(int num, String url) async {
    if(num<1 && 4<num) return;
    if(env.getUrl(num:num)==url) return;
    env.setUrl(num:num, url:url);
    String name = 'url' + num.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(name, url);
    this.notifyListeners();
  }

  Future saveKey(int num, String key) async {
    if(num<1 && 4<num) return;
    if(env.getKey(num:num)==key) return;
    env.setKey(num:num, key:key);
    String name = 'key' + num.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(name, key);
    this.notifyListeners();
  }
}