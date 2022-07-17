import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

const Color COL_SS_TEXT = Color(0xFFbbbbbb);

class MyUI {
  static final double mobileWidth = 700.0;
  static final double desktopWidth = 1100.0;

  static bool isMobile(BuildContext context) {
    return getWidth(context) < mobileWidth;
  }

  static bool isTablet(BuildContext context) {
    return getWidth(context) < desktopWidth &&
        getWidth(context) >= mobileWidth;
  }

  static bool isDesktop(BuildContext context) {
    return getWidth(context) >= desktopWidth;
  }

  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
}

class MyEdge {
  /// ホームバーの幅（アンドロイド）
  EdgeInsetsGeometry homebarEdge = EdgeInsets.all(0.0);

  /// 設定画面で左側の余白
  EdgeInsetsGeometry settingsEdge = EdgeInsets.all(0.0);

  MyEdge({ProviderBase? provider}) {
    if(provider!=null) this._provider = provider;
  }

  static double homebarWidth = 50.0; // ホームバーの幅
  static double margin = 10.0; // 基本マージン
  static double leftMargin = 200.0; // タブレット時の左マージン

  ProviderBase? _provider;
  double width = 0;

  /// Edgeを取得
  /// 各スクリーンのbuild()内で呼び出す
  void getEdge(BuildContext context, WidgetRef ref) async {
    if (width == MediaQuery.of(context).size.width)
      return;
    width = MediaQuery.of(context).size.width;
    print('-- getEdge() width=${width.toInt()}');

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

    EdgeInsetsGeometry leftEdge = EdgeInsets.all(0.0);
    if (MediaQuery.of(context).size.width > 700) {
      leftEdge = EdgeInsets.only(left: leftMargin);
    }
    this.settingsEdge = EdgeInsets.all(margin);
    this.settingsEdge = this.settingsEdge.add(leftEdge);
    this.settingsEdge = this.settingsEdge.add(homebarEdge);
    if(_provider!=null)
      ref.read(_provider!).notifyListeners();
  }
}
