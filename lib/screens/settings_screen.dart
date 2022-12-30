import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'log_screen.dart';
import '/controllers/environment.dart';
import 'base_screen.dart';
import 'widgets.dart';
import '/constants.dart';

/// Settings
class SettingsScreen extends BaseSettingsScreen {
  @override
  Future init() async {
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context, ref);
    return Scaffold(
        appBar: AppBar(
          title: Text(l10n("settings_title")),
          backgroundColor: Color(0xFF000000),
          actions: <Widget>[],
        ),
        body:
        (is2screen())
            ? SingleChildScrollView(
            padding: EdgeInsets.all(8),
            child: Stack(children: [
              Container(
                margin: leftMargin(),
                child: getList(),
              ),
              Container(
                margin: rightMargin(),
                child: rightScreen != null ? rightScreen!.getList() : null,
              )
            ]))
            : SingleChildScrollView(
            padding: EdgeInsets.all(8),
            child: Container(
              margin: edge.settingsEdge,
              child: getList(),
            )
        )
    );
  }

  Widget getList() {
    print('-- getList() camera_height.val=${env.camera_height.val}');
    return Column(children: [
      MyListTile(
        title: MyText('URL'),
        title2:
        Expanded(child: Text(env.getUrl(), maxLines: 3,
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.white, fontSize: 13.0))),
        onPressed: () {
          NavigatorPush(SelectUrlScreen());
        },
        multiline: true,
      ),
      MyValue(data: env.camera_height),
      MyValue(data: env.video_kbps),
      //MyValue(data: env.video_fps),
      MyValue(data: env.autostop_sec),
      MyLabel(''),
      MyListTile(
          title: MyText('Logs'),
          onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LogScreen(),
                )
            );
          }
      ),
    ]);
  }
}

/// Select URL
class SelectUrlScreen extends BaseSettingsScreen {
  int selVal = 1;

  @override
  Future init() async {
    selVal = env.url_num.val;
    redraw();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text('URL'), backgroundColor: Color(0xFF000000)),
      body: Container(
        margin: edge.settingsEdge,
        child: getList(),
      ),
    );
  }

  Widget getList() {
    return Column(children: [
      MyRadioListTileUrl(
          title: env.url1,
          value: 1,
          groupValue: selVal,
          onChanged: () => _onRadioSelected(1),
          onPressed: () async {
            await NavigatorPush(EditUrlScreen(1));
          }
      ),
      MyRadioListTileUrl(
          title: env.url2,
          value: 2,
          groupValue: selVal,
          onChanged: () => _onRadioSelected(2),
          onPressed: () async {
            await NavigatorPush(EditUrlScreen(2));
          }
      ),
      MyRadioListTileUrl(
          title: env.url3,
          value: 3,
          groupValue: selVal,
          onChanged: () => _onRadioSelected(3),
          onPressed: () async {
            await NavigatorPush(EditUrlScreen(3));
          }
      ),
      MyRadioListTileUrl(
          title: env.url4,
          value: 4,
          groupValue: selVal,
          onChanged: () => _onRadioSelected(4),
          onPressed: () async {
            await NavigatorPush(EditUrlScreen(4));
          }
      ),
    ]);
  }

  // fot URL
  Widget MyRadioListTileUrl(
      { required String title,
        required int value,
        required int groupValue,
        required void Function()? onChanged,
        required void Function()? onPressed}) {
    Icon icon = Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFF808080), size: 16.0);
    if (groupValue == value) {
      icon = Icon(Icons.radio_button_on_rounded, color: selectedTextColor, size: 16.0);
    }
    Widget w = SizedBox(width: 8);
    return Container(
        child: MyListTile(
          radio: groupValue == value,
          title: Row(children: [
            icon, w,
            Expanded(child:
            Text(l10n(title), maxLines: 2,
                style: TextStyle(color: groupValue == value ? selectedTextColor : textColor, fontSize: 13.0))
            ),
            IconButton(onPressed: onPressed, icon: Icon(Icons.edit, size: 16.0, color: Colors.white))
          ]),
          onPressed: onChanged,
          textonly: true,
        )
    );
  }

  _onRadioSelected(value) {
    print('-- _onRadioSelected ${value}');
    selVal = value;
    ref.read(environmentProvider).saveData(env.url_num,selVal);
  }
}

/// EditUrl
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
    subBuild(context, ref);
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
      MyTextField(controller: _urlController, keyboardType: TextInputType.url),
      MyLabel(''),
      MyLabel('KEY'),
      MyTextField(controller: _keyController),
      MyLabel(''),
      MyTextButton(
          width: 200,
          title: l10n('Save'),
          onPressed: () async {
            _url = _urlOld = _urlController.text;
            _key = _keyOld = _keyController.text;
            ref.read(environmentProvider).saveUrl(num, _url);
            ref.read(environmentProvider).saveKey(num, _key);
          }
      ),
      MyTextButton(
          width: 200,
          title: l10n('Undo'),
          onPressed: () async {
            _urlController.text = _urlOld;
            _keyController.text = _keyOld;
            redraw();
          }
      ),
      MyTextButton(
          width: 200,
          title: l10n('rtmp://'),
          onPressed: () async {
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