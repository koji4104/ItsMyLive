import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

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
    val:0,
    vals:IS_TEST?
         [0,120,3600,7200,10800,14400,21600]:
         [0,3600,7200,10800,14400,21600],
    keys:IS_TEST?
         ['Nonstop','2 min','1 hour','2 hour','3 hour','4 hour','6 hour']:
         ['Nonstop','1 hour','2 hour','3 hour','4 hour','6 hour'],
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
    keys:['500 kbps','1 mbps','2 mbps','4 mbps','8 mbps'],
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

  String url1 = '';
  String key1 = '';
  String url2 = '';
  String key2 = '';
  String url3 = '';
  String key3 = '';
  String url4 = '';
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
}

final environmentProvider = ChangeNotifierProvider((ref) => environmentNotifier(ref));
class environmentNotifier extends ChangeNotifier {
  Environment env = Environment();

  environmentNotifier(ref){
    load().then((_){
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
      _loadSub(prefs, env.publish_mode);

      env.url1 = prefs.getString('url1') ?? '';
      env.key1 = prefs.getString('key1') ?? '';
      env.url2 = prefs.getString('url2') ?? '';
      env.key2 = prefs.getString('key2') ?? '';
      env.url3 = prefs.getString('url3') ?? '';
      env.key3 = prefs.getString('key3') ?? '';
      env.url4 = prefs.getString('url4') ?? '';
      env.key4 = prefs.getString('key4') ?? '';
    } on Exception catch (e) {
      print('-- load() e=' + e.toString());
    }
  }
  _loadSub(SharedPreferences prefs, EnvData data) {
    data.val = prefs.getInt(data.name) ?? data.val;
  }

  Future saveData(EnvData data, int newVal) async {
    if(data.val == newVal)
      return;
    roundVal(data, newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
    this.notifyListeners();
  }

  void roundVal(EnvData data, int newVal){
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