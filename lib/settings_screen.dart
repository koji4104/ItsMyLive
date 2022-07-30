import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'localizations.dart';
import 'log_screen.dart';
import 'common.dart';
import 'environment.dart';

//----------------------------------------------------------
class BaseSettingsScreen extends ConsumerWidget {
  late BuildContext _context;
  late WidgetRef _ref;
  final _baseProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
  late MyEdge _edge = MyEdge(provider:_baseProvider);

  bool bInit = false;
  Environment env = new Environment();

  TextStyle tsOn = TextStyle(color:Colors.lightGreenAccent);
  TextStyle tsNg = TextStyle(color:Colors.grey);

  Color btnTextColor = Colors.white;
  Color btnTileColor = Color(0xFF404040);
  Color btnHoverColor = Color(0xFF505050);

  Color tileColor = Color(0xFF404040);
  Color hoverColor = Color(0xFF505050);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }

  @override
  Future init() async {
    if(bInit) return;
    env.load().then((_){
      redraw();
    });
    bInit = true;
  }

  void baseBuild(BuildContext context, WidgetRef ref) {
    _context = context;
    _ref = ref;
    _edge.getEdge(context,ref);
    ref.watch(_baseProvider);
    Future.delayed(Duration.zero, () => init());
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
      padding: EdgeInsets.symmetric(vertical:2, horizontal:8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
        title: title2!=null ?
          Row(children:[title, exp, title2]) :
          Row(children:[exp, title, exp]),
        trailing: Icon(Icons.arrow_forward_ios),
        tileColor: tileColor,
        hoverColor: hoverColor,
        onTap: onTap
      ),
    );
  }

  Widget MyTile({required Widget title, Widget? title2}) {
    Widget exp = Expanded(child: SizedBox(width:1));
    return Container(
      padding: EdgeInsets.symmetric(vertical:2, horizontal:8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
        title: title2!=null ?
          Row(children:[title, exp, title2]) :
          Row(children:[exp, title, exp]),
        tileColor: Color(0xFF000000),
      ),
    );
  }

  Widget MyButton({required String title, required Function() onTap}) {
    Widget exp = Expanded(child: SizedBox(width:1));
    return Container(
      padding: EdgeInsets.symmetric(vertical:2, horizontal:100),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
        title: Row(children:[
          exp,
          Text(title,style:TextStyle(color:btnTextColor)),
          exp
        ]),
        tileColor: btnTileColor,
        hoverColor: btnHoverColor,
        onTap: onTap
      ),
    );
  }

  Widget MyRadioListTile(
      { required String title,
        required int value,
        required int groupValue,
        required void Function(int?)? onChanged}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical:2, horizontal:8),
      child: RadioListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
        tileColor: tileColor,
        activeColor: Colors.white,
        title: Text(l10n(title)),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      )
    );
  }

  Future<int> NavigatorPush(var screen) async {
    int? ret = await Navigator.of(_context).push(
      MaterialPageRoute<int>(
        builder: (context) {
          return screen;
        }
      )
    );
    ret = ret ?? 0;
    if (ret==1) {
      env.load().then((_) {
        redraw();
      });
    }
    return ret;
  }

  String l10n(String text) {
    return Localized.of(this._context).text(text);
  }

  redraw(){
    _ref.read(_baseProvider).notifyListeners();
  }
}

//----------------------------------------------------------
class SettingsScreen extends BaseSettingsScreen {
  @override
  Future init() async {
    if(bInit) return;
    super.init();
    bInit = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
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
        MyListTile(
          title:Text(''),
          title2:Text(env.getUrl()),
          onTap:(){
            NavigatorPush(SelectUrlScreen());
          }
        ),
        MyValue(data: env.camera_height),
        MyValue(data: env.video_kbps),
        MyValue(data: env.video_fps),
        MyValue(data: env.autostop_sec),
        MyLabel(''),
        MyListTile(
          title:Text('Logs'),
          onTap:(){
            NavigatorPush(LogScreen());
          }
        ),
      ])
    );
  }

  Widget MyValue({required EnvData data}) {
    TextStyle ts = TextStyle(fontSize:16, color:Colors.white);
    return MyListTile(
      title:Text(l10n(data.name), style:ts),
      title2:Text(l10n(data.key), style:ts),
      onTap:() {
        NavigatorPush(RadioListScreen(data:data));
      }
    );
  }
}

//----------------------------------------------------------
class RadioListScreen extends BaseSettingsScreen {
  int selVal = 0;
  int selOld = 0;
  late EnvData data;

  RadioListScreen({required EnvData data}){
    this.data = data;
    selVal = data.val;
    selOld = selVal;
  }

  @override
  Future init() async {
    if(bInit) return;
    super.init();
    bInit = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return WillPopScope(
      onWillPop:() async {
        int r = 0;
        if(selOld!=selVal) {
          data.set(selVal);
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
          child:getList()
        ),
      )
    );
  }

  Widget getList() {
    List<Widget> list = [];
    for(int i=0; i<data.vals.length; i++){
      list.add(
        MyRadioListTile(
          title: data.keys[i],
          value: data.vals[i],
          groupValue: selVal,
          onChanged:(value) => _onRadioSelected(data.vals[i]),
        )
      );
    }
    list.add(MyLabel(l10n(data.name+'_desc')));
    return Column(children:list);
  }

  _onRadioSelected(value) {
    selVal = value;
    redraw();
  }
}

//----------------------------------------------------------
class SelectUrlScreen extends BaseSettingsScreen {
  int selVal = 0;
  int selOld = 0;
  late EnvData data;

  @override
  Future init() async {
    if(bInit) return;
    await env.load();
    selVal = env.url_num.val;
    selOld = selVal;
    redraw();
    bInit = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return WillPopScope(
      onWillPop:() async {
        int r = 0;
        if(selOld!=selVal) {
          env.url_num.set(selVal);
          env.save(env.url_num);
          r = 1;
        }
        Navigator.of(context).pop(r);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('URL'), backgroundColor:Color(0xFF000000),),
        body: Container(
          margin: _edge.settingsEdge,
          child:getList(),
        ),
      )
    );
  }

  Widget getList() {
    return Column(children:[
      MyRadioListTile(
        title: env.url1,
        value: env.url_num.vals[0],
        groupValue: selVal,
        onChanged: (value) => _onRadioSelected(env.url_num.vals[0]),
      ),
      MyRadioListTile(
        title: env.url2,
        value: env.url_num.vals[1],
        groupValue: selVal,
        onChanged: (value) => _onRadioSelected(env.url_num.vals[1]),
      ),
      MyRadioListTile(
        title: env.url3,
        value: env.url_num.vals[2],
        groupValue: selVal,
        onChanged: (value) => _onRadioSelected(env.url_num.vals[2]),
      ),
      MyRadioListTile(
        title: env.url4,
        value: env.url_num.vals[3],
        groupValue: selVal,
        onChanged: (value) => _onRadioSelected(env.url_num.vals[3]),
      ),
      MyLabel(''),
      MyButton(
        title: 'EDIT URL' + selVal.toString(),
        onTap:() async {
          int ret = await NavigatorPush(EditUrlScreen(num: selVal, env: env));
          if(ret==1)
            selOld = 0;
        }
      ),
    ]);
  }

  _onRadioSelected(value) {
    selVal = value;
    redraw();
  }
}

//----------------------------------------------------------
class EditUrlScreen extends BaseSettingsScreen {
  int num = 1;
  late TextEditingController _urlController;
  late TextEditingController _keyController;

  // num=1-4
  EditUrlScreen({int? num, Environment? env}){
    if(num!=null) this.num = num;
    if(env!=null) this.env = env;
    _url = this.env.getUrl(num:this.num);
    _key = this.env.getKey(num:this.num);
    _urlOld = _url;
    _keyOld = _key;
    _urlController = TextEditingController(text:_url);
    _keyController = TextEditingController(text:_key);
  }

  String _url = '';
  String _key = '';
  String _urlOld = '';
  String _keyOld = '';

  @override
  Future init() async {
    if(bInit) return;
    super.init();
    bInit = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
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
          child:getList(),
        ),
      )
    );
  }

  Widget getList() {
    return Column(children: [
      MyLabel(''),
      MyLabel('URL'),
      MyTextField(controller:_urlController, keyboardType:TextInputType.url),
      MyLabel(''),
      MyLabel('KEY'),
      MyTextField(controller:_keyController),
      MyLabel(''),
      MyButton(
          title: 'Undo',
          onTap:() async {
            _urlController.text = _urlOld;
            _keyController.text = _keyOld;
            redraw();
          }
      ),
      MyButton(
          title: 'rtmp://',
          onTap:() async {
            _urlController.text = 'rtmp://';
            redraw();
          }
      ),
    ]);
  }

  Widget MyTextField({ required TextEditingController controller, TextInputType? keyboardType}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal:8, vertical:2),
      child:TextField(
        style: TextStyle(color:Colors.white),
        controller: controller,
        keyboardType: keyboardType,
      )
    );
  }
}