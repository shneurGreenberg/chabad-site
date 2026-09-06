import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';

import 'data/repository.dart';
import 'l10n/strings.dart';
import 'router.dart';
import 'services/cloud_sync.dart';
import 'state/auth.dart';
import 'theme.dart';

final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  // Hash URLs so GitHub Pages can open /#/cemetery without a server 404.
  setUrlStrategy(HashUrlStrategy());
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
  late final LocaleController _locale = LocaleController();
  String? _prevLang;

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
    _locale.addListener(_onLocaleChanged);
    _prevLang = _locale.lang;
  }

  void _onLocaleChanged() {
    if (_prevLang != _locale.lang) {
      _prevLang = _locale.lang;
      _repo.onLocaleChanged(_locale.lang);
    }
  }

  @override
  void dispose() {
    _locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _locale),
        ChangeNotifierProvider.value(value: _repo),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: Consumer2<LocaleController, AppRepository>(
        builder: (context, locale, repo, _) {
          AppColors.bind(repo.palette);
          
          // Show loading screen until data is fully loaded from localStorage + Firebase
          if (!repo.isDataReady) {
            return MaterialApp(
              title: 'בית חב״ד בית מנחם — נובוסיבירסק',
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(repo.palette),
              locale: locale.locale,
              supportedLocales: const [Locale('he'), Locale('en'), Locale('ru')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Directionality(
                textDirection: locale.direction,
                child: Scaffold(
                  body: Container(
                    decoration: BoxDecoration(gradient: AppColors.heroGradient),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.accent),
                          const SizedBox(height: 24),
                          Text(
                            locale.lang == 'he'
                                ? 'טוען...'
                                : locale.lang == 'ru'
                                    ? 'Загрузка...'
                                    : 'Loading...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          
          return MaterialApp.router(
            title: 'בית חב״ד בית מנחם — נובוסיבירסק',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(repo.palette),
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
