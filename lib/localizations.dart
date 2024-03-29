import 'package:flutter/material.dart';

class SampleLocalizationsDelegate extends LocalizationsDelegate<Localized> {
  const SampleLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'ja'].contains(locale.languageCode);
  @override
  Future<Localized> load(Locale locale) async => Localized(locale);
  @override
  bool shouldReload(SampleLocalizationsDelegate old) => false;
}

class Localized {
  Localized(this.locale);
  final Locale locale;

  static Localized of(BuildContext context) {
    return Localizations.of(context, Localized)!;
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings_title': 'Settings',
      'url_num': 'URL',
      'url_num_desc': 'Select URL.',
      'video_kbps': 'Bitrate',
      'video_kbps_desc': 'Select video bitrate',
      'video_fps': 'FPS',
      'video_fps_desc': 'Select FPS (frames per second)',
      'autostop_sec': 'Automatic stop',
      'autostop_sec_desc':
          'It will stop automatically. It will stop even if the battery is 10% or less.',
      'camera_height': 'camera size',
      'camera_height_desc': 'If it is not compatible, a different size will be used.',
      'key_desc': 'KEY is required by RTMP.',
    },
    'ja': {
      'settings_title': '設定',
      'url_num': 'URL',
      'url_num_desc': 'URLを選んでください。',
      'video_kbps': 'ビットレート',
      'video_kbps_desc': '切断が多いときはビットレートとカメラサイズを下げてください。',
      'video_fps': 'FPS',
      'video_fps_desc': 'フレームレートを選んでください。',
      'autostop_sec': '自動停止',
      'autostop_sec_desc': '自動的に停止します。バッテリー残量10%以下でも停止します。',
      'camera_height': 'カメラサイズ',
      'camera_height_desc': '非対応の場合は別のサイズになります。',
      'key_desc': 'KEY は RTMP で必要です。',
    },
  };

  String text(String text) {
    String? s;
    try {
      if (locale.languageCode == "ja")
        s = _localizedValues["ja"]?[text];
      else
        s = _localizedValues["en"]?[text];
    } on Exception catch (e) {}
    return s != null ? s : text;
  }
}
