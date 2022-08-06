import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'localizations.dart';
import 'common.dart';
import 'environment.dart';

class BaseSettingsScreen extends ConsumerWidget {
  late BuildContext _context;
  late WidgetRef _ref;
  final _baseProvider = ChangeNotifierProvider((ref) => ChangeNotifier());
  late MyEdge edge = MyEdge(provider:_baseProvider);

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
    edge.getEdge(context,ref);
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
      padding: EdgeInsets.symmetric(vertical:8, horizontal:100),
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
