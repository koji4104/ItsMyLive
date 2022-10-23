import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'log_screen.dart';
import 'environment.dart';
import 'base_settings_screen.dart';

//----------------------------------------------------------
class SettingsScreen extends BaseSettingsScreen {
  @override
  Future init() async {
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return Scaffold(
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
    );
  }

  Widget getList(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(8,8,8,8),
      child: Column(children: [
        MyListTile(
          title: env.getUrl()=='' ? Text('URL') : Text(''),
          title2:Text(env.getUrl()),
          onTap:(){
            NavigatorPush(SelectUrlScreen());
          }
        ),
        MyValue(data: env.camera_height),
        MyValue(data: env.video_kbps),
        //MyValue(data: env.video_fps),
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
  late EnvData data;

  RadioListScreen({required EnvData data}){
    this.data = data;
    selVal = data.val;
  }

  @override
  Future init() async {
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text(l10n(data.name)), backgroundColor:Color(0xFF000000),),
      body: Container(
        margin: edge.settingsEdge,
        child:getList()
      ),
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
    ref.read(environmentProvider).saveData(data,selVal);
  }
}

//----------------------------------------------------------
class SelectUrlScreen extends BaseSettingsScreen {
  int selVal = 0;

  @override
  Future init() async {
    selVal = env.url_num.val;
    redraw();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text('URL'), backgroundColor:Color(0xFF000000)),
      body: Container(
        margin: edge.settingsEdge,
        child:getList(),
      ),
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
          await NavigatorPush(EditUrlScreen(selVal));
        }
      ),
    ]);
  }

  _onRadioSelected(value) {
    selVal = value;
    ref.read(environmentProvider).saveData(env.url_num,selVal);
  }
}

//----------------------------------------------------------
class EditUrlScreen extends BaseSettingsScreen {
  int num = 1;
  String _url = '';
  String _key = '';
  String _urlOld = '';
  String _keyOld = '';
  late TextEditingController _urlController;
  late TextEditingController _keyController;

  // num=1-4
  EditUrlScreen(int num){
    this.num = num;
  }

  @override
  Future init() async {
    _url = _urlOld = this.env.getUrl(num:this.num);
    _key = _keyOld = this.env.getKey(num:this.num);
    _urlController = TextEditingController(text:_url);
    _keyController = TextEditingController(text:_key);
    redraw();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    baseBuild(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text('URL ${num}'), backgroundColor:Color(0xFF000000)),
      body: Container(
        margin: edge.settingsEdge,
        child:getList(),
      ),
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
          title: 'Save',
          ok: true,
          onTap:() async {
            _url = _urlOld = _urlController.text;
            _key = _keyOld = _keyController.text;
            ref.read(environmentProvider).saveUrl(num,_url);
            ref.read(environmentProvider).saveKey(num,_key);
          }
      ),
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