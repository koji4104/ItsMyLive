import 'package:flutter/material.dart';

BorderRadiusGeometry DEF_BORDER_RADIUS = BorderRadius.circular(0);

// ON OFF button
Color btnOn = Colors.white;
Color btnNg = Colors.grey;
Color btnNl = Colors.white;

ThemeData myTheme = myDarkTheme;

/// e.g.
/// - myTheme.backgroundColor
/// - myTheme.cardColor
/// - myTheme.textTheme.bodyMedium (size 14)
/// - myTheme.textTheme.titleMedium (size 16)
ThemeData myDarkTheme = ThemeData.dark().copyWith(
  pageTransitionsTheme: MyPageTransitionsTheme(),
  backgroundColor: Color(0xFF000000),
  scaffoldBackgroundColor: Color(0xFF000000),
  canvasColor: Color(0xFF444444),
  cardColor: Color(0xFF444444),
  primaryColor: Color(0xFF444444),
  primaryColorDark: Color(0xFF444444),
  dividerColor: Color(0xFF555555),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Color(0xFFffffff))),
  ),
);
ThemeData myLightTheme = ThemeData.light().copyWith(
  pageTransitionsTheme: MyPageTransitionsTheme(),
  backgroundColor: Color(0xFF444444),
  scaffoldBackgroundColor: Color(0xFF444444),
  canvasColor: Color(0xFFFFFFFF),
  cardColor: Color(0xFFffffff),
  primaryColor: Color(0xFFfffaf0),
  dividerColor: Color(0xFFaaaaaa),
  selectedRowColor: Color(0xFFbbbbbb),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Color(0xFFffffff))),
  ),
);

// Swipe to cancel. From left to right.
class MyPageTransitionsTheme extends PageTransitionsTheme {
  const MyPageTransitionsTheme();
  static const PageTransitionsBuilder builder = CupertinoPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return builder.buildTransitions<T>(route, context, animation, secondaryAnimation, child);
  }
}

Widget MyLabel(String label, {int? size, Color? color}) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(label, style: TextStyle(fontSize: 14, color: Colors.white)),
    ),
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
  return Text(text, style: ts, overflow: TextOverflow.ellipsis);
}

Widget MyIconButton(
    {required Icon icon,
    required void Function()? onPressed,
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? iconSize,
    Key? key}) {
  if (iconSize == null) iconSize = 32.0;
  return Positioned(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    key: key,
    child: Container(
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: icon,
        iconSize: iconSize,
        onPressed: onPressed,
      ),
    ),
  );
}

/// MyTextButton
/// - title
/// - onPressed
/// - width: default 300
Widget MyTextButton(
    {required String title, required void Function()? onPressed, double? width, bool? cancelStyle, bool? deleteStyle}) {
  Color fgcol = Color(0xFF303030);
  Color bgcol = Color(0xFFFFFFFF);
  double fsize = 14.0;
  if (cancelStyle != null) {
    fgcol = Color(0xFFFFFFFF);
    bgcol = Color(0xFF707070);
  } else if (deleteStyle != null) {
    fgcol = Colors.redAccent;
  }
  return Container(
    width: width != null ? width : 300,
    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    child: TextButton(
      style: TextButton.styleFrom(
        backgroundColor: bgcol,
        shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
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
/// - radio: null or true
/// - textonly: null or true
Widget MyListTile(
    {required Widget title, Widget? title2, Function()? onPressed, bool? multiline, bool? radio, bool? textonly}) {
  Widget e = Expanded(child: SizedBox(width: 8));
  if (multiline != null) e = SizedBox(width: 8);
  Widget w = SizedBox(width: 8);
  Icon icon = Icon(Icons.arrow_forward_ios, size: 14.0);

  Widget btn;
  if (textonly != null) {
    btn = title;
  } else if (radio != null) {
    icon = Icon(Icons.radio_button_unchecked_rounded, color: myTheme.disabledColor, size: 16.0);
    if (radio == true) {
      icon = Icon(Icons.radio_button_on_rounded, size: 16.0);
    }
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
        color: myDarkTheme.cardColor,
        borderRadius: DEF_BORDER_RADIUS,
      ),
      child: TextButton(child: btn, onPressed: onPressed),
    ),
  );
}
