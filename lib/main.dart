import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/repository.dart';
import 'l10n/strings.dart';
import 'router.dart';
import 'services/cloud_sync.dart';
import 'state/auth.dart';
import 'theme.dart';

final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CloudSync.instance.init();
  runApp(const ChabadApp());
}

class ChabadApp extends StatefulWidget {
  const ChabadApp({super.key});

  @override
  State<ChabadApp> createState() => _ChabadAppState();
}

class _ChabadAppState extends State<ChabadApp> {
  late final AppRepository _repo = AppRepository();

  @override
  void initState() {
    super.initState();
    _repo.onPersistWarning = (message) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider.value(value: _repo),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: Consumer<LocaleController>(
        builder: (context, locale, _) {
          return MaterialApp.router(
            title: 'בית חב״ד ליובאוויטש',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            routerConfig: appRouter,
            scaffoldMessengerKey: appMessengerKey,
            locale: locale.locale,
            supportedLocales: const [Locale('he'), Locale('en'), Locale('ru')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              // Apply RTL/LTR based on the selected language.
              return Directionality(
                textDirection: locale.direction,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
