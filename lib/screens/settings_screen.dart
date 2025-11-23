import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dart:developer';
import 'log_screen.dart';
import '/controllers/environment.dart';
import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/constants.dart';

/// Settings
class SettingsScreen extends BaseScreen {
  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n("settings_title")),
        backgroundColor: Color(0xFF000000),
        actions: <Widget>[],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8),
        child: Container(
          margin: EdgeInsets.fromLTRB(8, 16, 8, 0),
          child: getList(),
        ),
      ),
    );
  }

  Widget getList() {
    log('settings_screen.getList() camera_height.val=${env.camera_height.val}');
    List<Widget> list = [];

    list.add(
      MyListTile(
        title1: MyText('URL'),
        title2: Expanded(
            child: Text(env.getUrl(),
                maxLines: 3,
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white, fontSize: 13.0))),
        onPressed: () {
          NavigatorPush(SelectUrlScreen());
        },
        multiline: true,
      ),
    );

    list.add(SizedBox(height: 10));
    list.add(MySettingsTile(data: env.camera_height));
    list.add(MySettingsTile(data: env.video_kbps));
    list.add(MySettingsTile(data: env.video_fps));
    list.add(MySettingsTile(data: env.autostop_sec));

    list.add(SizedBox(height: 10));
    list.add(
      MyListTile(
        title1: MyText('Logs'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LogScreen(),
            ),
          );
        },
      ),
    );

    list.add(SizedBox(height: 10));
    list.add(
      MyListTile(
        title1: MyText('Licenses'),
        onPressed: () async {
          final info = await PackageInfo.fromPlatform();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return LicensePage(
                applicationName: l10n('app_name'),
                applicationVersion: info.version,
                applicationIcon: Container(
                  padding: EdgeInsets.all(8),
                  child: Image(
                      image: AssetImage('lib/assets/appicon.png'),
                      width: 64,
                      height: 64),
                ),
              );
            }),
          );
        },
      ),
    );
    return Column(children: list);
  }
}

//----------------------------------------------------------
/// Select URL
//----------------------------------------------------------
ChangeNotifierProvider selectUrlProvider =
ChangeNotifierProvider((ref) => ChangeNotifier());

class SelectUrlScreen extends BaseScreen {
  int selVal = 1;

  @override
  Future init() async {
    selVal = myEnv.url_num.val;
    redraw();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    log('SelectUrlScreen build');
    myEnv = ref.watch(envProvider).env;
    ref.watch(selectUrlProvider);
    selVal = myEnv.url_num.val;

    super.build(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text('URL'), backgroundColor: Color(0xFF000000)),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: getList(),
        ),
      ),
    );
  }

  Widget getList() {
    return Column(children: [
      MyRadioListTile(
        title: myEnv.url1,
        value: 1,
        onChanged: () => _onRadioSelected(1),
        onPressed: () async {
          await NavigatorPush(EditUrlScreen(1));
        },
      ),
      SizedBox(height: 6),
      MyRadioListTile(
        title: myEnv.url2,
        value: 2,
        onChanged: () => _onRadioSelected(2),
        onPressed: () async {
          await NavigatorPush(EditUrlScreen(2));
        },
      ),
      SizedBox(height: 6),
      MyRadioListTile(
        title: myEnv.url3,
        value: 3,
        onChanged: () => _onRadioSelected(3),
        onPressed: () async {
          await NavigatorPush(EditUrlScreen(3));
        },
      ),
      SizedBox(height: 6),
      MyRadioListTile(
        title: myEnv.url4,
        value: 4,
        onChanged: () => _onRadioSelected(4),
        onPressed: () async {
          await NavigatorPush(EditUrlScreen(4));
        },
      ),
    ]);
  }

  // fot URL
  Widget MyRadioListTile(
      {required String title,
        required int value,
        required void Function()? onChanged,
        required void Function()? onPressed}) {
    Icon radioBtn = Icon(Icons.radio_button_unchecked_rounded,
        color: Color(0xFF808080), size: 16.0);
    if (selVal == value) {
      radioBtn = Icon(Icons.radio_button_on_rounded,
          color: Color(0xFFFFFFFF), size: 16.0);
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1, horizontal: 8),
      decoration: BoxDecoration(
        color: myDarkTheme.cardColor,
        borderRadius: DEF_BORDER_RADIUS,
      ),
      child: TextButton(
          child: Row(children: [
            radioBtn,
            SizedBox(width: 8),
            Expanded(
                child:
                Text(title, maxLines: 2, style: TextStyle(fontSize: 13.0))),
            IconButton(
              icon: Icon(Icons.edit, size: 16.0, color: Colors.white),
              onPressed: onPressed,
            )
          ]),
          onPressed: onChanged),
    );
  }

  _onRadioSelected(value) async {
    log('onRadioSelected ${value}');
    selVal = value;
    ref.read(envProvider).saveVal(myEnv.url_num, selVal);
  }

  @override
  redraw() {
    if (ref.read(selectUrlProvider) != null)
      ref.read(selectUrlProvider)!.notifyListeners();
  }
}

//----------------------------------------------------------
/// EditUrl
//----------------------------------------------------------
ChangeNotifierProvider editUrlProvider =
ChangeNotifierProvider((ref) => ChangeNotifier());

class EditUrlScreen extends BaseScreen {
  int num = 1;
  String _url = '';
  String _key = '';
  String _urlOld = '';
  String _keyOld = '';
  TextEditingController _urlController = TextEditingController(text: "");
  TextEditingController _keyController = TextEditingController(text: "");

  // num=1-4
  EditUrlScreen(int num) {
    this.num = num;
  }

  @override
  Future init() async {
    _url = _urlOld = this.env.getUrl(num: this.num);
    _key = _keyOld = this.env.getKey(num: this.num);
    _urlController = TextEditingController(text: _url);
    _keyController = TextEditingController(text: _key);
    redraw();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    ref.watch(editUrlProvider);
    return Scaffold(
      appBar:
      AppBar(title: Text('URL ${num}'), backgroundColor: Color(0xFF000000)),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: getList(),
        ),
      ),
    );
  }

  Widget getList() {
    bool isChanged =
        (_urlOld != _urlController.text) || (_keyOld != _keyController.text);
    double buttonWidth = 140.0;
    double subButtonWidth = 90.0;
    return Column(children: [
      MyLabel('URL'),
      MyTextField(controller: _urlController, keyboardType: TextInputType.text),
      SizedBox(height: 10),
      MyLabel('KEY'),
      MyTextField(controller: _keyController, keyboardType: TextInputType.text),
      SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        MyTextButton(
          width: buttonWidth,
          title: l10n('Cancel'),
          disabled: isChanged ? null : true,
          onPressed: isChanged
              ? () async {
            _urlController.text = _urlOld;
            _keyController.text = _keyOld;
            redraw();
          }
              : null,
        ),
        SizedBox(width: 16),
        MyTextButton(
          width: buttonWidth,
          title: l10n('Save'),
          commit: isChanged ? true : null,
          disabled: isChanged ? null : true,
          onPressed: isChanged
              ? () async {
            _url = _urlOld = _urlController.text;
            _key = _keyOld = _keyController.text;
            ref.read(envProvider).saveUrl(num, _url);
            ref.read(envProvider).saveKey(num, _key);
            redraw();
          }
              : null,
        ),
      ]),
      SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        MyTextButton(
          width: subButtonWidth,
          title: l10n('rtmp://'),
          onPressed: () async {
            _urlController.text = 'rtmp://';
            redraw();
          },
        ),
        SizedBox(width: 16),
        MyTextButton(
          width: subButtonWidth,
          title: l10n(':1935'),
          onPressed: () async {
            _urlController.text += ':1935';
            redraw();
          },
        ),
        SizedBox(width: 16),
        MyTextButton(
          width: subButtonWidth,
          title: l10n('youtube'),
          onPressed: () async {
            _urlController.text = 'rtmp://a.rtmp.youtube.com/live2';
            redraw();
          },
        ),
      ]),
      SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        MyTextButton(
          width: subButtonWidth,
          title: l10n('srt://'),
          onPressed: () async {
            _urlController.text = 'srt://';
            redraw();
          },
        ),
        SizedBox(width: 16),
        MyTextButton(
          width: subButtonWidth,
          title: l10n(':5000'),
          onPressed: () async {
            _urlController.text += ':5000';
            redraw();
          },
        ),
      ]),
      SizedBox(height: 10),
      MyLabel('rtmp://xxx/live/test\nURL rtmp://xxx/live\nKEY test\n\nsrt://xxxx:5000?passphrase=xxx\nsrt://xxxx:5000?streamid=xxx'),
    ]);
  }

  Widget MyTextField(
      {required TextEditingController controller,
        TextInputType? keyboardType}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: TextField(
        style: TextStyle(color: Colors.white, fontSize: 14),
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) {
          redraw();
        },
      ),
    );
  }

  @override
  redraw() {
    if (ref.read(editUrlProvider) != null)
      ref.read(editUrlProvider)!.notifyListeners();
  }
}
