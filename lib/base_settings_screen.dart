import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'localizations.dart';
import 'common.dart';
import 'environment.dart';

class BaseSettingsScreen extends ConsumerWidget {
  late BuildContext context;
  late WidgetRef ref;
  final _baseProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
  late MyEdge edge = MyEdge(provider:_baseProvider);

  bool bInit = false;
  Environment env = new Environment();

  // Text Style
  Color btnOn = Colors.white;
  Color btnNg = Colors.grey;
  Color btnNl = Colors.white;

  Color btnTextColor = Color(0xFFFFFFFF);
  Color btnTileColor = Color(0xFF404040);
  Color btnOkTextColor = Color(0xFFFFFFFF);
  Color btnOkTileColor = Color(0xFF808080);

  Color textColor = Color(0xFFa0a0a0);
  Color tileColor = Color(0xFF404040);
  Color selectedTextColor = Color(0xFFFFFFFF);
  Color selectedTileColor = Color(0xFF404040);
  Color activeColor = Color(0xFFFFFFFF); // radio button
  Color hoverColor = Color(0xFF505050);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }

  @override
  Future init() async {
  }
  Future baseinit() async {
    if(bInit) return;
    bInit = true;
    init();
  }

  void baseBuild(BuildContext context, WidgetRef ref) {
    this.context = context;
    this.ref = ref;
    edge.getEdge(context,ref);
    ref.watch(_baseProvider);
    this.env = ref.watch(environmentProvider).env;
    Future.delayed(Duration.zero, () => baseinit());
  }

  Widget MyLabel(String label, {int? size, Color? color}) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal:12, vertical:4),
          child: Text(label, style:TextStyle(fontSize:14, color:Colors.white)),
        )
    );
  }

  Widget MyListTile({required Widget title, Widget? title2, Function()? onTap}) {
    Widget e = Expanded(child: SizedBox(width:1));
    Widget w = SizedBox(width:8);
    Icon icon = Icon(Icons.arrow_forward_ios, color:Colors.white, size:14.0);
    Widget btn;
    if(title2!=null && onTap!=null){
      btn = Row(children:[title, e, title2, w, icon]);
    } else if(onTap!=null) {
      btn = Row(children:[e, title, e, w, icon]);
    } else {
      btn = Row(children:[e, title, e]);
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical:2),
      child: Container(
        padding: EdgeInsets.symmetric(vertical:1, horizontal:8),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(3),
        ),
        child: TextButton(
          child: btn,
          onPressed: onTap
        ),
    ));
  }

  Widget MyText(String text, {double? size}) {
    TextStyle ts;
    double fsize = size!=null ? size : 16.0;
    if(text=='ON')
      ts = TextStyle(color:btnOn, fontSize:fsize, fontWeight:FontWeight.bold);
    else if(text=='OFF')
      ts = TextStyle(color:btnNg, fontSize:fsize);
    else
      ts = TextStyle(color:btnNl, fontSize:fsize);
    return Text(l10n(text), style:ts);
  }

  Widget MyTile({required Widget title, Widget? title2}) {
    Widget expand = Expanded(child: SizedBox(width:1));
    return Container(
      padding: EdgeInsets.symmetric(vertical:2, horizontal:8),
      height:40,
      child: ListTile(
        dense:true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
        title: title2!=null ?
          Row(children:[title, expand, title2]) :
          Row(children:[expand, title, expand]),
        tileColor: Color(0xFF000000),
      ),
    );
  }

  Widget MyButton({required String title, required Function() onTap, bool? ok}) {
    return Container(
      width: 200, height: 50,
      padding: EdgeInsets.symmetric(vertical:6, horizontal:10),
      child: TextButton(
          style: TextButton.styleFrom(
              backgroundColor: ok==null ? btnTileColor : btnOkTileColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40)))
          ),
          child: Text(title, style:TextStyle(color: ok==null ? btnTextColor : btnOkTextColor, fontSize: 16.0), textAlign: TextAlign.center),
          onPressed: onTap
      ),
    );
  }

  Widget MyRadioListTile(
      { required String title,
        required int value,
        required int groupValue,
        required void Function(int?)? onChanged}) {
    return Container(
        margin: EdgeInsets.symmetric(vertical:0, horizontal:8),
        child: RadioListTile(
          tileColor: tileColor,
          activeColor: activeColor,
          selectedTileColor: selectedTileColor,
          selected: groupValue==value,
          title: Text(l10n(title), style:TextStyle(color: groupValue==value ? selectedTextColor: textColor)),
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
        )
    );
  }

  Widget MyRadioListTile2(
      { required String title,
        required int value,
        required int groupValue,
        required void Function(int?)? onChanged}) {
    return Container(
        margin: EdgeInsets.symmetric(vertical:2, horizontal:8),
        child: RadioListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
          tileColor: tileColor,
          activeColor: activeColor,
          selectedTileColor: selectedTileColor,
          selected: groupValue==value,
          title: Text(l10n(title), style:TextStyle(color: groupValue==value ? selectedTextColor: textColor)),
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
        )
    );
  }

  Future<int?> NavigatorPush(var screen) async {
    int? ret = await Navigator.of(context).push(
        MaterialPageRoute<int>(
            builder: (context) {
              return screen;
            }
        )
    );
    return ret;
  }

  String l10n(String text) {
    return Localized.of(this.context).text(text);
  }

  redraw(){
    ref.read(_baseProvider).notifyListeners();
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
    Widget w1 = Container(
        decoration:BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child:Column(children:list)
    );
    Widget w2 = MyLabel(l10n(data.name+'_desc'));
    return Column(children:[w1,w2]);
  }

  Widget getList2() {
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