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
    vals:[500,1000,2000,4000],
    keys:['500 kbps','1000 kbps','2000 kbps','4000 kbps'],
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

      //url1 = prefs.getString('url1') ?? '';
      //key1 = prefs.getString('key1') ?? '';
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
class BaseSettingsScreen extends ConsumerWidget {
  late BuildContext _context;
  late WidgetRef _ref;
  ProviderBase? _provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _context = context;
    _ref = ref;
    return Container();
  }

  Widget MyLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal:12, vertical:4),
        child: Text(label, style:TextStyle(fontSize:13, color:Colors.white)),
      )
    );
  }

  Widget MyListTile({required Widget title, Widget? title2, required Function() onTap}) {
    Widget exp = Expanded(child: SizedBox(width:1));
    return Container(
      padding: EdgeInsets.symmetric(horizontal:8, vertical:2),
      child: ListTile(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        title: title2!=null ?
          Row(children:[title, exp, title2]) :
          Row(children:[exp, title, exp]),
        trailing: Icon(Icons.arrow_forward_ios),
        tileColor: Color(0xFF333333),
        hoverColor: Color(0xFF444444),
        onTap: onTap
      ),
    );
  }

  Widget MyTile({required Widget title, Widget? title2}) {
    Widget exp = Expanded(child: SizedBox(width:1));
    return Container(
      padding: EdgeInsets.symmetric(horizontal:8, vertical:2),
      child: ListTile(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        title: title2!=null ?
          Row(children:[title, exp, title2]) :
          Row(children:[exp, title, exp]),
        tileColor: Color(0xFF000000),
      ),
    );
  }

  Widget MyRadioListTile(
      { required String title,
        required int value,
        required int groupValue,
        required void Function(int?)? onChanged}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal:8, vertical:2),
      child: RadioListTile(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        tileColor: Color(0xFF333333),
        activeColor: Colors.blueAccent,
        title: Text(l10n(title)),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      )
    );
  }

  String l10n(String text) {
    return Localized.of(this._context).text(text);
  }

  redraw(){
    if(_provider!=null)
      _ref.read(_provider!).notifyListeners();
  }
}

//----------------------------------------------------------
final settingsScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class SettingsScreen extends BaseSettingsScreen {
  SettingsScreen(){}
  Environment env = new Environment();
  bool bInit = false;

  Future init() async {
    if(bInit) return;
      bInit = true;
    print('-- SettingsScreen.init()');
    try {
      await env.load();
      _provider = settingsScreenProvider;
      redraw();
    } on Exception catch (e) {
      print('-- SettingsScreen init e=' + e.toString());
    }
    return true;
  }

  MyEdge _edge = MyEdge(provider:settingsScreenProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _context = context;
    _ref = ref;
    Future.delayed(Duration.zero, () => init());
    ref.watch(settingsScreenProvider);
    _edge.getEdge(context,ref);

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
        MyLabel(''),
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

  Widget MyValue({required EnvData data, bool? isUrl}) {
    TextStyle ts = TextStyle(fontSize:16, color:Colors.white);
    return MyListTile(
      title:Text(l10n(data.name), style:ts),
      title2:Text(l10n(data.key), style:ts),
      onTap:() {
        Navigator.of(_context).push(
          MaterialPageRoute<int>(
            builder: (BuildContext context) {
              return RadioListScreen(data: data, isUrl:isUrl);
          })).then((ret) {
            if (ret==1) {
              env.load();
              _ref.read(settingsScreenProvider).notifyListeners();
            }
          }
        );
      }
    );
  }
}

//----------------------------------------------------------
final radioListScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class RadioListScreen extends BaseSettingsScreen {
  int selValue = 0;
  int selValueOld = 0;
  int selIndex = 0;
  late EnvData data;
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
    this._context = context;
    this._ref = ref;
    ref.watch(radioListScreenProvider);
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
        MyRadioListTile(
          title: data.keys[i],
          value: data.vals[i],
          groupValue: selValue,
          onChanged:(value) => _onRadioSelected(data.vals[i], i),
        )
      );
    }
    if(isUrl){
      Widget w = MyListTile(
        title:Text('EDIT ' + selValue.toString()),
        onTap:() {
          Navigator.of(_context).push(
            MaterialPageRoute<int>(
              builder: (BuildContext context) {
                return UrlScreen(num: selIndex + 1, env: env);
              })).then((ret) {
                if(ret==1) {
                  env.load().then((_){
                    _ref.read(radioListScreenProvider).notifyListeners();
                });
              }
            }
          );
        }
      );
      list.add(MyLabel(''));
      list.add(w);
    }
    list.add(MyLabel(l10n(data.name+'_desc')));
    return Column(children:list);
  }

  _onRadioSelected(value, index) {
    selValue = value;
    selIndex = index;
    _ref.watch(radioListScreenProvider).notifyListeners();
  }
}

//----------------------------------------------------------
final urlScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
class UrlScreen extends BaseSettingsScreen {
  Environment env = Environment();
  int num = 1;
  late TextEditingController _urlController;
  late TextEditingController _keyController;
  UrlScreen({int? num, Environment? env}){
    if(num!=null) this.num = num;
    if(env!=null) this.env = env;
    _url = this.env.getUrl(num:this.num);
    _key = this.env.getKey(num:this.num);
    _urlOld = _url;
    _keyOld = _key;
    _urlController = TextEditingController(text:_url);
    _keyController = TextEditingController(text:_key);
  }
  MyEdge _edge = MyEdge(provider:urlScreenProvider);
  String _url = '';
  String _key = '';
  String _urlOld = '';
  String _keyOld = '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    this._context = context;
    this._ref = ref;
    _edge.getEdge(context,ref);
    return WillPopScope(
      onWillPop:() async {
        int r = 0;
        _url = _urlController.text;
        _key = _keyController.text;
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
          child:Column(children:[
            MyLabel(''),
            MyLabel('URL'),
            Container(
              padding: EdgeInsets.symmetric(horizontal:8, vertical:2),
              child:TextField(
                style: TextStyle(color:Colors.white),
                //onChanged:(s){_url=s;},
                controller: _urlController,
                keyboardType: TextInputType.url,
              )
            ),
            MyLabel(''),
            MyLabel('KEY'),
            Container(
              padding: EdgeInsets.symmetric(horizontal:8, vertical:2),
              child:TextField(
                style: TextStyle(color:Colors.white),
                //onChanged:(s){_key=s;},
                controller: _keyController,
                //controller: TextEditingController(text:_key),
              )
            ),
          ])
        ),
      )
    );
  }
}