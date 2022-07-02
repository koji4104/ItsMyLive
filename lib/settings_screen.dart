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
    vals:[250,500,1000,2000,4000],
    keys:['250 kbps','500 kbps','1000 kbps','2000 kbps','4000 kbps'],
    name:'video_kbps',
  );

  EnvData camera_height = EnvData(
    val:480,
    vals:[240,360,480,720,1080],
    keys:['320X240','640x360','853x480','1280x720','1920x1080'],
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
  String url1 = 'rtmp://xxx/1';
  String key1 = '';
  String url2 = 'rtmp://xxx/2';
  String key2 = '';
  String url3 = 'rtmp://xxx/3';
  String key3 = '';
  String url4 = 'rtmp://xxx/4';
  String key4 = '';

  String getUrl({int? num}){
    String r = url1;
    int i = url_num.val;
    if(num!=null) i = num;
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
    int i = url_num.val;
    if(num!=null) i = num;
    switch(i){
      case 1: r = key1; break;
      case 2: r = key2; break;
      case 3: r = key3; break;
      case 4: r = key4; break;
    }
    return r;
  }

  Future load() async {
    if(kIsWeb) return;
    print('-- load()');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _loadSub(prefs, url_num);
      _loadSub(prefs, video_fps);
      _loadSub(prefs, video_kbps);
      _loadSub(prefs, autostop_sec);
      _loadSub(prefs, camera_height);
      _loadSub(prefs, camera_pos);

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
    if(kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(data.name, data.val);
  }

  Future saveUrl(String url, int num) async {
    if(kIsWeb) return;
    if(num<1 && 4<num) return;
    String name = 'url' + num.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(name, url);
  }

  Future saveKey(String key, int num) async {
    if(kIsWeb) return;
    if(num<1 && 4<num) return;
    String name = 'key' + num.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(name, key);
  }
}

//----------------------------------------------------------
final settingsScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class SettingsScreen extends ConsumerWidget {
  SettingsScreen(){}
  Environment env = new Environment();
  bool bInit = false;

  Future init() async {
    if(bInit) return;
      bInit = true;
    try {
      await env.load();
      _ref!.read(settingsScreenProvider).notifyListeners();
    } on Exception catch (e) {
      print('-- SettingsScreen init e=' + e.toString());
    }
    return true;
  }

  BuildContext? _context;
  WidgetRef? _ref;
  MyEdge _edge = MyEdge(provider:settingsScreenProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _context = context;
    _ref = ref;
    Future.delayed(Duration.zero, () => init());
    ref.watch(settingsScreenProvider);

    _edge.getEdge(context,ref);
    print('-- build');
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(true);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n("settings_title")),
          backgroundColor:Color(0xFF000000),
          actions: <Widget>[],
        ),
        body: Container(
          margin: _edge.settingsEdge,
          child: Stack(children: <Widget>[
            getList(context),
          ])
        )
      )
    );
  }

  Widget getList(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(8,8,8,8),
      child: Column(children: [
        MyValue(data: env.url_num, isUrl:true),
        MyValue(data: env.camera_height),
        MyValue(data: env.video_kbps),
        MyValue(data: env.video_fps),
        MyValue(data: env.autostop_sec),
        MyText(Localized.of(context).text("precautions")),
        MyListTile(
          title:Text('Logs'),
          onTap:(){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LogScreen(),
              )
            );
          }
        ),
      ])
    );
  }

  Widget MyText(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical:10, horizontal:20),
        child: Text(label, style:TextStyle(fontSize:12, color:Colors.white)),
      )
    );
  }

  Widget MyListTile({required Widget title, required Function() onTap}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal:14, vertical:3),
      child: ListTile(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        title: title,
        trailing: Icon(Icons.arrow_forward_ios),
        tileColor: Color(0xFF333333),
        hoverColor: Color(0xFF444444),
        onTap: onTap
      ),
    );
  }

  Widget MyValue({required EnvData data, bool? isUrl}) {
    TextStyle ts = TextStyle(fontSize:16, color:Colors.white);
    return MyListTile(
      title:Row(children:[
        Text(l10n(data.name), style:ts),
        Expanded(child: SizedBox(width:1)),
        isUrl!=null
        ? Text(env.getUrl(), style:ts)
        : Text(data.key, style:ts),
      ]),
      onTap:() {
        Navigator.of(_context!).push(
          MaterialPageRoute<int>(
            builder: (BuildContext context) {
              return RadioListScreen(data: data, isUrl:isUrl);
          })).then((ret) {
            if (ret==1) {
              env.load();
              _ref!.read(settingsScreenProvider).notifyListeners();
            }
          }
        );
      }
    );
  }

  String l10n(String text){
    return Localized.of(_context!).text(text);
  }
}

//----------------------------------------------------------
final radioSelectedProvider = StateProvider<int>((ref) {
  return 0;
});
final radioListScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class RadioListScreen extends ConsumerWidget {
  int selValue = 0;
  int selValueOld = 0;
  int selIndex = 0;
  late EnvData data;
  WidgetRef? ref;
  BuildContext? context;
  MyEdge _edge = MyEdge(provider:radioListScreenProvider);
  bool isUrl = false;
  Environment env = Environment();

  RadioListScreen({EnvData? data, bool? isUrl}){
    if(data!=null){
      this.data = data;
      selValue = data.val;
      selValueOld = selValue;
      for(int i=0; i<data.vals.length; i++) {
        if(data.vals[i] == data.val)
          selIndex = i;
      }
    }
    if(isUrl!=null) this.isUrl = isUrl;
    env.load();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(radioSelectedProvider);
    ref.watch(radioListScreenProvider);
    this.context = context;
    this.ref = ref;
    _edge.getEdge(context,ref);

    return WillPopScope(
      onWillPop:() async {
        int r = 0;
        if(selValueOld!=selValue) {
          data.set(selValue);
          env.save(data);
          r = 1;
        }
        Navigator.of(context).pop(r);
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n(data.name)), backgroundColor:Color(0xFF000000),),
        body: Container(
          margin: _edge.settingsEdge,
          child:getListView()
        ),
      )
    );
  }

  Widget getListView() {
    List<Widget> list = [];
    for(int i=0; i<data.vals.length; i++){
      list.add(
        Container(
          margin: EdgeInsets.symmetric(horizontal:14, vertical:0),
          child: RadioListTile(
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          tileColor: Color(0xFF333333),
          activeColor: Colors.blueAccent,
          title: isUrl ? Text(env.getUrl(num:i+1)) : Text(l10n(data.keys[i])),
          value: data.vals[i],
          groupValue: selValue,
          onChanged: (value) => _onRadioSelected(data.vals[i], i),
      )));
    }
    if(isUrl){
      Widget btn = TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        child: Text('EDIT ' + selValue.toString(), style:TextStyle(fontSize:16, color:Colors.white)),
        onPressed:() {
          Navigator.of(context!).push(
            MaterialPageRoute<int>(
              builder: (BuildContext context) {
                return UrlScreen(num: selIndex + 1, env: env);
              })).then((ret) {
                if(ret==1) {
                  env.load().then((_){
                    ref!.read(radioListScreenProvider).notifyListeners();
                  });
                }
              }
            );
          }
      );
      Widget w = Container(
        margin: EdgeInsets.only(top:8),
        child: btn);
      list.add(w);
    }

    list.add(MyText(data.name+'_desc'));
    return Column(children:list);
  }

  _onRadioSelected(value, index) {
    if(ref!=null){
      selValue = value;
      selIndex = index;
      ref!.read(radioSelectedProvider.state).state = selValue;
    };
  }

  String l10n(String text) {
    if(this.context!=null)
      return Localized.of(this.context!).text(text);
    else
      return text;
  }

  Widget MyText(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal:10, vertical:6),
      child: Align(
      alignment: Alignment.centerLeft,
      child: Text(l10n(label), style:TextStyle(fontSize:13, color:Colors.white)),
    ));
  }
}

//----------------------------------------------------------
final urlScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class UrlScreen extends ConsumerWidget {
  Environment env = Environment();
  int num = 1;
  UrlScreen({int? num, Environment? env}){
    if(num!=null) this.num = num;
    if(env!=null) this.env = env;
    _url = this.env.getUrl(num:this.num);
    _key = this.env.getKey(num:this.num);
    _urlOld = _url;
    _keyOld = _key;
  }
  MyEdge _edge = MyEdge(provider:urlScreenProvider);
  String _url = '';
  String _key = '';
  String _urlOld = '';
  String _keyOld = '';
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _edge.getEdge(context,ref);

    return WillPopScope(
      onWillPop:() async {
        int r = 0;
        if(_url!=_urlOld) {
          env.saveUrl(_url, num);
          r = 1;
        }
        if(_key!=_keyOld) {
          env.saveKey(_key, num);
          r = 1;
        }
        print('-- onWillPop() ${_url} ${_key}');
        Navigator.of(context).pop(r);
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('URL ${num}'), backgroundColor:Color(0xFF000000),),
        body: Container(
          margin: _edge.settingsEdge,
          padding: EdgeInsets.fromLTRB(20,4,4,20),
          child:Column(children:[
            MyText('URL'),
            TextField(
              style: TextStyle(color:Colors.white),
              onChanged:(s){_url = s;},
              controller: TextEditingController(text: _url),
            ),
            MyText('KEY'),
            TextField(
              style: TextStyle(color:Colors.white),
              onChanged:(s){_key = s;},
              controller: TextEditingController(text: _key),
            ),
          ])
        ),
      )
    );
  }

  Widget MyText(String label) {
    return Container(
      padding: EdgeInsets.fromLTRB(0,12,0,0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style:TextStyle(fontSize:13, color:Colors.grey)),
      )
    );
  }
}