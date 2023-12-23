import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MyUI {
  static final double mobileWidth = 700.0;
  static final double desktopWidth = 1100.0;

  static bool isMobile(BuildContext context) {
    return getWidth(context) < mobileWidth;
  }

  static bool isTablet(BuildContext context) {
    return getWidth(context) < desktopWidth && getWidth(context) >= mobileWidth;
  }

  static bool isDesktop(BuildContext context) {
    return getWidth(context) >= desktopWidth;
  }

  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
}

class MyEdge {
  /// Home bar (android)
  EdgeInsetsGeometry homebarEdge = EdgeInsets.all(0.0);

  /// Left margin on the settings screen (unused)
  EdgeInsetsGeometry settingsEdge = EdgeInsets.all(0.0);

  MyEdge({ProviderBase? provider}) {
    if (provider != null) this._provider = provider;
  }

  static double homebarWidth = 50.0; // homebar width
  static double margin = 10.0; // basic margin

  ProviderBase? _provider;
  double width = 100;
  double height = 100;

  /// Edge
  /// Called in build() of each screen
  void getEdge(BuildContext context, WidgetRef ref) async {
    if (this.width == MediaQuery.of(context).size.width) return;
    this.width = MediaQuery.of(context).size.width;
    this.height = MediaQuery.of(context).size.height;
    print('-- getEdge() width=${this.width.toInt()} height=${this.height.toInt()}');

    if (!kIsWeb && Platform.isAndroid) {
      print('-- isAndroid');
      NativeDeviceOrientation ori = await NativeDeviceOrientationCommunicator().orientation();
      switch (ori) {
        case NativeDeviceOrientation.landscapeRight:
          homebarEdge = EdgeInsets.only(left: homebarWidth);
          print('-- droid landscapeRight');
          break;
        case NativeDeviceOrientation.landscapeLeft:
          homebarEdge = EdgeInsets.only(right: homebarWidth);
          break;
        case NativeDeviceOrientation.portraitDown:
        case NativeDeviceOrientation.portraitUp:
          homebarEdge = EdgeInsets.only(bottom: homebarWidth);
          break;
        default:
          break;
      }
    }

    EdgeInsetsGeometry leftrightEdge = EdgeInsets.all(0.0);
    if (this.width > 800) {
      leftrightEdge = EdgeInsets.only(left: 20.0, right: 20.0);
    }
    this.settingsEdge = EdgeInsets.all(margin);
    this.settingsEdge = this.settingsEdge.add(leftrightEdge);
    this.settingsEdge = this.settingsEdge.add(homebarEdge);
    if (_provider != null && ref.read(_provider!) != null) ref.read(_provider!).notifyListeners();
  }
}
