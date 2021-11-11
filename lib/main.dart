import 'dart:async';

import 'package:datadog_flutter/datadog_flutter.dart';
import 'package:datadog_flutter/datadog_observer.dart';
import 'package:datadog_flutter/datadog_rum.dart';
import 'package:datadog_flutter/datadog_tracing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_template/services/core/app_state_service.dart';
import 'package:flutter_template/services/core/localize.dart';
import 'package:flutter_template/services/user_prefs.dart';
import 'package:flutter_template/state/app_state_constants.dart';
import 'package:flutter_template/state/app_variables.dart';
import 'package:stacked_services/stacked_services.dart';

import 'app/app.router.dart';
import 'app/locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatadogFlutter.initialize(
      environment: 'development',
      clientToken: 'pub7cdaf950812e5fb5f6d0ccc9276a7b5d',
      androidRumApplicationId: '7f592869-4679-4b39-ae8a-42f99ba50661',
      iosRumApplicationId: 'd75c1e64-1617-4971-bd28-51e1059fb428',
      trackingConsent: TrackingConsent.granted,
      serviceName: 'test_app');

  await DatadogTracing.initialize();

  // Capture Flutter errors automatically:
  FlutterError.onError = DatadogRum.instance.addFlutterError;

  setUpLocator();

  // Catch the errors without crashing the app
  runZonedGuarded(() {
    runApp(ErrorHandlingApp());
  }, (error, stackTrace) {
    DatadogRum.instance.addError(error, stackTrace);
  });
  runApp(ErrorHandlingApp());
}

class ErrorHandlingApp extends StatelessWidget {
  const ErrorHandlingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Init AppStateService
    AppStateService appStateService = locator<AppStateService>();
    RouteObserver<PageRoute> routeObserver =
        appStateService.getAppVars().vars[APP_VARS_KEYS.ROUTE_OBSERVER];

    String preferredLanguage = locator<UserPrefs>().preferredLanguage;
    return MaterialApp(
      title: 'Flutter Template',
      theme: ThemeData(),
      onGenerateRoute: StackedRouter().onGenerateRoute,
      initialRoute: Routes.userView,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [routeObserver, DatadogObserver()],
      supportedLocales: supportedLangsNames.values,
      localizationsDelegates: [
        LocalizeDelegate(supportedLangsNames.values.toList()),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> supportedLocales) {
        appStateService.setAppVar(APP_VARS_KEYS.DEVICE_LOCALE, locale);

        locale = (supportedLangsNames[preferredLanguage] != null
            ? supportedLangsNames[preferredLanguage]
            : locale);
        if (locale != null) {
          for (Locale supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              appStateService.setAppVar(
                  APP_VARS_KEYS.PREFERRED_LOCALE, supportedLocale);

              return supportedLocale;
            }
          }
        }
        appStateService.setAppVar(
            APP_VARS_KEYS.PREFERRED_LOCALE, DEFAULT_LOCALE);

        return DEFAULT_LOCALE;
      },
    );
  }
}
