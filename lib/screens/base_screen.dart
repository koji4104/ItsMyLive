import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/localizations.dart';
import '/common.dart';
import '/controllers/environment.dart';
import '/constants.dart';
import 'widgets.dart';

/// BaseScreen
class BaseScreen extends ConsumerWidget {
  late BuildContext context;
  late WidgetRef ref;
  ChangeNotifierProvider baseProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
  late MyEdge edge = MyEdge(provider: baseProvider);
  Environment env = new Environment();
  bool bInit = false;

  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context, ref);
    return Container();
  }

  @override
  void subBuild(BuildContext context, WidgetRef ref) {
    ref.watch(baseProvider);
    this.env = ref.watch(environmentProvider).env;
    this.context = context;
    this.ref = ref;
    edge.getEdge(context, ref);
    if (bInit == false) {
      bInit = true;
      Future.delayed(Duration.zero, () => init());
    }
  }

  Future<int?> NavigatorPush(var screen) async {
    int? ret = await Navigator.of(context).push(MaterialPageRoute<int>(
      builder: (context) => screen,
    ));
    return ret;
  }

  String l10n(String text) {
    return Localized.of(this.context).text(text);
  }

  void showSnackBar(String msg) {
    final snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  redraw() {
    if (ref.read(baseProvider) != null) ref.read(baseProvider)!.notifyListeners();
  }
}

/// BaseSettings
class BaseSettingsScreen extends BaseScreen {
  BaseSettingsScreen? rightScreen;

  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context, ref);
    return Container();
  }

  @override
  void subBuild(BuildContext context, WidgetRef ref) {
    super.subBuild(context, ref);
  }

  @override
  Widget getList() {
    return Container();
  }

  Widget MyValue({required EnvData data}) {
    TextStyle ts = TextStyle(fontSize: 16, color: Colors.white);
    return MyListTile(
        title: Text(l10n(data.name), style: ts),
        title2: Text(l10n(data.key), style: ts),
        onPressed: () {
          if (is2screen()) {
            this.rightScreen = RadioListScreen(data: data);
            this.rightScreen!.subBuild(context, ref);
            redraw();
          } else {
            NavigatorPush(RadioListScreen(data: data));
          }
        });
  }

  bool is2screen() {
    return edge.width > 600;
  }

  EdgeInsetsGeometry leftMargin() {
    return EdgeInsets.only(left: 10, right: (edge.width / 2));
  }

  EdgeInsetsGeometry rightMargin() {
    return EdgeInsets.only(left: (edge.width / 2), right: 10);
  }
}

/// RadioListScreen
class RadioListScreen extends BaseSettingsScreen {
  int selVal = 0;
  late EnvData data;

  RadioListScreen({required EnvData data}) {
    this.data = data;
    selVal = data.val;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    subBuild(context, ref);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n(data.name)),
        backgroundColor: Color(0xFF000000),
      ),
      body: Container(margin: edge.settingsEdge, child: getList()),
    );
  }

  @override
  Widget getList() {
    List<Widget> list = [];
    for (int i = 0; i < data.vals.length; i++) {
      list.add(MyRadioListTile(
        title: l10n(data.keys[i]),
        value: data.vals[i],
        groupValue: selVal,
        onChanged: () => _onRadioSelected(data.vals[i]),
      ));
    }
    list.add(MyLabel(l10n(data.name + '_desc')));
    return Column(children: list);
  }

  Widget MyRadioListTile(
      {required String title, required int value, required int groupValue, required void Function()? onChanged}) {
    TextStyle ts = TextStyle(fontSize: 16, color: groupValue == value ? selectedTextColor : textColor);
    return Container(
        child: MyListTile(
      title: Text(title, style: ts),
      radio: groupValue == value,
      onPressed: onChanged,
    ));
  }

  void _onRadioSelected(value) {
    selVal = value;
    ref.read(environmentProvider).saveData(data, selVal);
  }
}
