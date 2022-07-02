import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camera_screen.dart';
import 'localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(ProviderScope(child: MyApp()));
  });
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: []);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'title',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        backgroundColor: Colors.black,
        pageTransitionsTheme: MyPageTransitionsTheme(),
      ),
      home: CameraScreen(),
      localizationsDelegates: [
        const SampleLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en',''),
        const Locale('ja',''),
      ],
    );
  }
}

// Swipe to cancel
// From left to right
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
