import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/repository.dart';
import 'l10n/strings.dart';
import 'router.dart';
import 'state/auth.dart';
import 'theme.dart';

void main() {
  runApp(const ChabadApp());
}

class ChabadApp extends StatelessWidget {
  const ChabadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider(create: (_) => AppRepository()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: Consumer<LocaleController>(
        builder: (context, locale, _) {
          return MaterialApp.router(
            title: 'בית חב״ד ליובאוויטש',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            routerConfig: appRouter,
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
