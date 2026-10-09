import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/repository.dart';
import 'l10n/strings.dart';
import 'router.dart';
import 'services/cloud_sync.dart';
import 'services/url_strategy.dart';
import 'state/auth.dart';
import 'theme.dart';
import 'tenant/tenant_runtime.dart';
import 'widgets/boot_splash.dart';

final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  // Hash URLs so GitHub Pages / Amvera can open /#/cemetery without a server 404.
  // MUST run before GoRouter is constructed (see createAppRouter in router.dart).
  useHashUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  TenantRuntime.bootstrap();
  // Construct router only after HashUrlStrategy so deep links (#/tourist, #/history) match.
  createAppRouter();
  unawaited(CloudSync.instance.warmPublic());
  // Logo doc only — do not wait for the rest of the media collection.
  unawaited(CloudSync.instance.warmEmblem());
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
    _locale.dispose();
    _repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _locale),
        ChangeNotifierProvider.value(value: _repo),
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthController();
            // Restore Firebase Auth session after hard refresh.
            unawaited(auth.restoreFromFirebase());
            return auth;
          },
        ),
      ],
      child: Consumer2<LocaleController, AppRepository>(
        builder: (context, locale, repo, _) {
          AppColors.bind(repo.palette);
          final appTitle = TenantRuntime.instance.config.seoTitle;

          // Show loading screen until data is fully loaded from localStorage + Firebase
          if (!repo.isDataReady) {
            return MaterialApp(
              title: appTitle,
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
                child: const Scaffold(
                  body: CommunityBootSplash(),
                ),
              ),
            );
          }
          
          return MaterialApp.router(
            title: appTitle,
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
