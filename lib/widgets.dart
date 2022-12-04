import 'package:flutter/material.dart';
import 'constants.dart';

Widget MyLabel(String label, {int? size, Color? color}) {
  return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(label, style: TextStyle(fontSize: 14, color: Colors.white)),
      )
  );
}

Widget MyText(String text, {double? size}) {
  TextStyle ts;
  double fsize = size != null ? size : 16.0;
  if (text == 'ON')
    ts = TextStyle(color: btnOn, fontSize: fsize, fontWeight: FontWeight.bold);
  else if (text == 'OFF')
    ts = TextStyle(color: btnNg, fontSize: fsize);
  else
    ts = TextStyle(color: btnNl, fontSize: fsize);
  return Text(text, style: ts);
}

Widget MyIconButton({required Icon icon, required void Function()? onPressed,
  double? left, double? top, double? right, double? bottom, double? iconSize}) {
  Color fgcol = Colors.white;
  Color bgcol = Colors.black54;
  if (iconSize == null)
    iconSize = 38.0;
  return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: CircleAvatar(
          backgroundColor: bgcol,
          radius: iconSize * 0.75,
          child: IconButton(
            icon: icon,
            color: fgcol,
            iconSize: iconSize,
            onPressed: onPressed,
          )
      )
  );
}

/// MyTextButton
/// - title
/// - onPressed
/// - width: default 300
Widget MyTextButton({
  required String title,
  required void Function()? onPressed,
  double? width,
  bool? cancelStyle,
  bool? deleteStyle}) {
  Color fgcol = Color(0xFF303030);
  Color bgcol = Color(0xFFFFFFFF);
  double fsize = 16.0;
  if (cancelStyle!=null) {
    fgcol = Color(0xFFFFFFFF);
    bgcol = Color(0xFF606060);
  } else if (deleteStyle!=null) {
    fgcol = Colors.redAccent;
  }
  return Container(
    width: width != null ? width : 300,
    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    child: TextButton(
      style: TextButton.styleFrom(
          backgroundColor: bgcol,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)))
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        child: Text(title, style: TextStyle(color: fgcol, fontSize: fsize), textAlign: TextAlign.center),
      ),
      onPressed: onPressed,
    ),
  );
}

/// MyListTile
/// - title
/// - title2
/// - onPressed
/// - multiline: null or true
/// - radio: null or true or false
Widget MyListTile({
  required Widget title,
  Widget? title2,
  Function()? onPressed,
  bool? multiline,
  bool? radio,
  bool? textonly}) {
  Widget e = Expanded(child: SizedBox(width: 8));
  if (multiline != null)
    e = SizedBox(width: 8);
  Widget w = SizedBox(width: 8);
  Icon icon = Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14.0);

  Widget btn;
  if (textonly != null) {
    btn = title;
  } else if (radio != null) {
    Icon icon = Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFF808080), size: 16.0);
    if (radio == true) {
      icon = Icon(Icons.radio_button_on_rounded, color: selectedTextColor, size: 16.0);
    }
    //btn = Row(children: [icon, w, title]);
    btn = Row(children: [title, e, icon]);
  } else if (title2 != null && onPressed != null) {
    btn = Row(children: [title, e, title2, w, icon]);
  } else if (onPressed != null) {
    btn = Row(children: [e, title, e, w, icon]);
  } else {
    btn = Row(children: [e, title, e]);
  }
  return Container(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 8),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(3),
        ),
        child: TextButton(
            child: btn,
            onPressed: onPressed
        ),
      )
  );
}


