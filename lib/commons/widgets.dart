import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:io';

import '/constants.dart';
import '/controllers/environment.dart';

Environment myEnv = Environment();

const double DEF_RADIUS = 3;
BorderRadiusGeometry DEF_BORDER_RADIUS = BorderRadius.circular(3);

const double DEF_APPBAR_HEIGHT = 40.0;
const ICON_BUTTON_SIZE = 24.0;

ThemeData myTheme = myDarkTheme;
double myTextScale = 1.0;

Color COL_DARK_TEXT = Color(0xffFFFFFF);
Color COL_DARK_CARD = Color(0xff303030);
Color COL_DARK_BACK = Color(0xff000000);

Color COL_LIGHT_TEXT = Color(0xff000000);
Color COL_LIGHT_CARD = Color(0xffFFFFFF);
Color COL_LIGHT_BACK = Color(0xFFf8f8ff);

TextStyle TEXTSTYLE_DARK_SMALL = ThemeData.dark()
    .textTheme
    .bodySmall!
    .copyWith(fontSize: 12.0, color: COL_DARK_TEXT);
TextStyle TEXTSTYLE_DARK_MEDIUM = ThemeData.dark()
    .textTheme
    .bodyMedium!
    .copyWith(fontSize: 14.0, color: COL_DARK_TEXT);
TextStyle TEXTSTYLE_DARK_LARGE = ThemeData.dark()
    .textTheme
    .bodyLarge!
    .copyWith(fontSize: 16.0, color: COL_DARK_TEXT);

TextStyle TEXTSTYLE_LIGHT_SMALL = ThemeData.light()
    .textTheme
    .bodySmall!
    .copyWith(fontSize: 12.0, color: COL_LIGHT_TEXT);
TextStyle TEXTSTYLE_LIGHT_MEDIUM = ThemeData.light()
    .textTheme
    .bodyMedium!
    .copyWith(fontSize: 14.0, color: COL_LIGHT_TEXT);
TextStyle TEXTSTYLE_LIGHT_LARGE = ThemeData.light()
    .textTheme
    .bodyLarge!
    .copyWith(fontSize: 16.0, color: COL_LIGHT_TEXT);

ThemeData myDarkTheme = ThemeData.dark().copyWith(
  pageTransitionsTheme: MyPageTransitionsTheme(),
  scaffoldBackgroundColor: COL_DARK_BACK,
  canvasColor: COL_DARK_CARD,
  cardColor: COL_DARK_CARD,
  disabledColor: Color(0xFF909090),
  primaryColor: Color(0xFF444444),
  primaryColorDark: Color(0xFF333333),
  dividerColor: Color(0xFF808080),
  highlightColor: Color(0xFF3366CC),
  iconTheme: IconThemeData(color: COL_DARK_TEXT),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(Color(0xFF333333)),
    checkColor: WidgetStateProperty.all(Color(0xFFFFFFFF)),
    overlayColor: WidgetStateProperty.all(Color(0xFF555555)),
  ),
  textTheme: TextTheme(
    bodySmall: TEXTSTYLE_DARK_SMALL,
    bodyMedium: TEXTSTYLE_DARK_MEDIUM,
    bodyLarge: TEXTSTYLE_DARK_LARGE,
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Color(0xFF808080),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      textStyle: TEXTSTYLE_DARK_MEDIUM,
      foregroundColor: COL_DARK_TEXT,
      backgroundColor: COL_DARK_CARD,
      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
      shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: COL_DARK_TEXT,
      iconSize: ICON_BUTTON_SIZE,
      padding: EdgeInsets.all(0),
      minimumSize: Size(0, 0),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Color(0xFF222222),
    actionTextColor: COL_DARK_TEXT,
    contentTextStyle: ThemeData.dark().textTheme.bodyMedium!.copyWith(),
  ),
  appBarTheme: AppBarTheme(
    iconTheme: IconThemeData(size: ICON_BUTTON_SIZE),
    backgroundColor: COL_DARK_BACK,
    titleTextStyle: ThemeData.dark().textTheme.bodyMedium!.copyWith(),
    toolbarHeight: DEF_APPBAR_HEIGHT,
  ),
);

ThemeData myLightTheme = ThemeData.light().copyWith(
  pageTransitionsTheme: MyPageTransitionsTheme(),
  scaffoldBackgroundColor: COL_LIGHT_BACK,
  canvasColor: COL_LIGHT_CARD,
  cardColor: COL_LIGHT_CARD,
  disabledColor: Color(0xFF808080),
  primaryColor: Color(0xFFffffff),
  dividerColor: Color(0xFFA0A0A0),
  highlightColor: Color(0xFFAADDFF),
  iconTheme: IconThemeData(color: COL_LIGHT_TEXT),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(Color(0xFF333333)),
    checkColor: WidgetStateProperty.all(Color(0xFFFFFFFF)),
    overlayColor: WidgetStateProperty.all(Color(0xFF555555)),
  ),
  textTheme: TextTheme(
    bodySmall: TEXTSTYLE_LIGHT_SMALL,
    bodyMedium: TEXTSTYLE_LIGHT_MEDIUM,
    bodyLarge: TEXTSTYLE_LIGHT_LARGE,
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Color(0xFF808080),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      textStyle: TEXTSTYLE_LIGHT_MEDIUM,
      foregroundColor: COL_LIGHT_TEXT,
      backgroundColor: COL_LIGHT_CARD,
      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
      shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: COL_LIGHT_TEXT,
      iconSize: ICON_BUTTON_SIZE,
      padding: EdgeInsets.all(0),
      minimumSize: Size(0, 0),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Color(0xFFeeeeee),
    actionTextColor: COL_LIGHT_TEXT,
    contentTextStyle: ThemeData.dark()
        .textTheme
        .bodyMedium!
        .copyWith(fontSize: 14.0, color: COL_LIGHT_TEXT),
  ),
  appBarTheme: AppBarTheme(
    iconTheme: IconThemeData(size: ICON_BUTTON_SIZE),
    backgroundColor: COL_LIGHT_BACK,
    titleTextStyle: ThemeData.light().textTheme.bodyMedium!.copyWith(),
    toolbarHeight: DEF_APPBAR_HEIGHT,
  ),
);

// Swipe to cancel. From left to right.
class MyPageTransitionsTheme extends PageTransitionsTheme {
  const MyPageTransitionsTheme();

  static const PageTransitionsBuilder builder =
  CupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return builder.buildTransitions<T>(
        route, context, animation, secondaryAnimation, child);
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

Widget MyText(
    String text, {
      int? maxLength,
      int? maxLines,
    }) {
  double scale = myTextScale;
  if (maxLength == null) maxLength = 40;
  if (maxLines == null) maxLines = 2;
  if (text.length > maxLength) {
    text = text.substring(0, maxLength) + '...';
  }
  return Text(
    text,
    overflow: TextOverflow.ellipsis,
    maxLines: maxLines,
    textScaler: TextScaler.linear(scale),
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
  bool? commit,
  bool? disabled,
}) {
  double fsize = myTheme.textTheme.bodyMedium!.fontSize!;
  Color? fgcol = myTheme.textTheme.bodyMedium!.color!;
  Color bgcol = myTheme.canvasColor;
  Color bdcol = myTheme.dividerColor;

  if (commit != null) {
    fgcol = Color(0xFFFFFFFF);
    bgcol = Colors.blueAccent;
    bdcol = Colors.blueAccent;
  } else if (disabled != null) {
    fgcol = Color(0xFFA0A0A0);
    bgcol = Colors.black;
    bdcol = myTheme.dividerColor;
  }
  double scale = myTextScale;

  return Container(
    width: width != null ? width : 300,
    child: TextButton(
      style: TextButton.styleFrom(
        backgroundColor: bgcol,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(DEF_RADIUS))),
        side: BorderSide(color: bdcol),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        child: Row(children: [
          Expanded(child: SizedBox(width: 1)),
          Text(title,
              style: TextStyle(color: fgcol, fontSize: fsize),
              textScaler: TextScaler.linear(scale),
              textAlign: TextAlign.center),
          Expanded(child: SizedBox(width: 1)),
        ]),
      ),
      onPressed: onPressed,
    ),
  );
}

/// MyListTile
/// - title1
/// - title2
/// - onPressed
/// - multiline: null or true
Widget MyListTile({
  required Widget title1,
  Widget? title2,
  Function()? onPressed,
  bool? multiline,
}) {
  Widget e = Expanded(child: SizedBox(width: 8));
  if (multiline != null) e = SizedBox(width: 8);
  Widget w = SizedBox(width: 10);
  Icon icon = Icon(Icons.arrow_forward_ios,
      size: 14.0, color: myTheme.textTheme.bodyMedium!.color);

  Widget txt;
  if (title2 != null && onPressed != null) {
    txt = Row(children: [title1, e, title2, w, icon]);
  } else if (onPressed != null) {
    txt = Row(children: [e, title1, e, w, icon]);
  } else {
    txt = Row(children: [e, title1, e]);
  }
  return Container(
    height: 42,
    padding: EdgeInsets.symmetric(vertical: 1, horizontal: 1),
    child: TextButton(child: txt, onPressed: onPressed),
  );
}

Widget MyIconButton(
    {required Icon icon,
      required void Function()? onPressed,
      double? left,
      double? top,
      double? right,
      double? bottom}) {
  double iconSize = 32.0;
  return Positioned(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    child: Container(
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: myTheme.cardColor,
          width: 8.0,
        ),
      ),
      child: IconButton(
        icon: icon,
        iconSize: iconSize,
        onPressed: onPressed,
      ),
    ),
  );
}
