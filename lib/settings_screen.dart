import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'log_screen.dart';
import 'environment.dart';
import 'base_settings_screen.dart';

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
          margin: edge.settingsEdge,
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
          margin: edge.settingsEdge,
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
          margin: edge.settingsEdge,
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
          margin: edge.settingsEdge,
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