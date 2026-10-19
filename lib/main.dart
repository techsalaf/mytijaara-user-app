import 'dart:async';
import 'dart:ui';
import 'package:app_links/app_links.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/dashboard/widgets/home_status_bar_tint.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/keyboard_dismiss_route_observer.dart';
import 'package:sixam_mart/helper/language_loader.dart';
import 'package:sixam_mart/helper/link_converter_helper.dart';
import 'package:sixam_mart/helper/notification_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/dark_theme.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/messages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/cookies_view.dart';
import 'helper/get_di.dart' as di;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_web_plugins/url_strategy.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }
  /*///Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };


  ///Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };*/

  // GEMINI-MYTJ: Render an actionable startup state before any asynchronous
  // Firebase, dependency-injection, or notification setup can block the first frame.
  final _StartupController startupController = _StartupController();
  runApp(_StartupApp(controller: startupController));
  unawaited(_bootstrap(startupController));
  // GEMINI-MYTJ: End startup handoff.
}

// GEMINI-MYTJ: Keep the existing application bootstrap behind an observable,
// time-bounded boundary so release failures are visible and retryable.
Future<void> _bootstrap(_StartupController controller) async {
  controller.begin();
  try {
    final _BootstrapData data = await _initializeApp().timeout(
      const Duration(seconds: 30),
    );
    controller.complete(data);
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Startup failed: $error\n$stackTrace');
    }
    controller.fail(error);
  }
}

Future<_BootstrapData> _initializeApp() async {
  if (GetPlatform.isWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB0xtfJMflFm_2pXdxo5sMPncPQgyE9AAM",
        authDomain: "mytijaara-21638.firebaseapp.com",
        projectId: "mytijaara-21638",
        storageBucket: "mytijaara-21638.firebasestorage.app",
        messagingSenderId: "1017926959065",
        appId: "1:1017926959065:web:fee8e7af199a1d677e23c8",
        measurementId: "G-6XF74RVXXW",
      ),
    );
    // GEMINI-MYTJ: Android uses the generated google-services.json rather than
    // the web Firebase app credentials that previously blocked release startup.
  } else {
    await Firebase.initializeApp();
    // GEMINI-MYTJ: End native Firebase configuration fix.
  }

  final Map<String, Map<String, String>> languages = await di.init();

  NotificationBodyModel? body;
  try {
    if (GetPlatform.isMobile) {
      final RemoteMessage? remoteMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (remoteMessage != null) {
        body = NotificationHelper.convertNotification(remoteMessage.data);
      }
      await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Notification setup failed: $error\n$stackTrace');
    }
  }

  if (ResponsiveHelper.isWeb()) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "1509100437592925",
      cookie: true,
      xfbml: true,
      version: "v26.0",
    );
  }

  return _BootstrapData(languages: languages, body: body);
}

class _BootstrapData {
  final Map<String, Map<String, String>> languages;
  final NotificationBodyModel? body;
  const _BootstrapData({required this.languages, required this.body});
}

class _StartupController extends ChangeNotifier {
  bool isLoading = true;
  Object? error;
  _BootstrapData? data;

  void begin() {
    isLoading = true;
    error = null;
    notifyListeners();
  }

  void complete(_BootstrapData value) {
    data = value;
    isLoading = false;
    notifyListeners();
  }

  void fail(Object value) {
    error = value;
    isLoading = false;
    notifyListeners();
  }
}

class _StartupApp extends StatefulWidget {
  final _StartupController controller;
  const _StartupApp({required this.controller});

  @override
  State<_StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<_StartupApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStartupChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStartupChanged);
    super.dispose();
  }

  void _onStartupChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final _BootstrapData? data = widget.controller.data;
    if (data != null) {
      return MyApp(languages: data.languages, body: data.body);
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16A34A)),
        fontFamily: 'DMSans',
      ),
      home: _StartupScreen(controller: widget.controller),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  final _StartupController controller;
  const _StartupScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    final Object? error = controller.error;
    final bool isLoading = controller.isLoading;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // GEMINI-MYTJ: Match the Flutter bootstrap screen to the branded
              // splash so the native-to-Flutter handoff does not flash.
              Image.asset(Images.logo, width: 200),
              // GEMINI-MYTJ: End branded startup handoff.
              const SizedBox(height: 24),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 44,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'MyTijaara',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF166534),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isLoading
                    ? const Text(
                        'Preparing your shopping experience...',
                        key: ValueKey('loading'),
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        'We could not finish starting the app.',
                        key: const ValueKey('error'),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const SizedBox(
                  width: 190,
                  child: LinearProgressIndicator(minHeight: 5),
                )
              else ...[
                Text(
                  'Please check your connection and try again.${error == null ? '' : '\n\n${_startupErrorMessage(error)}'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFD1D5DB), height: 1.4),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => _bootstrap(controller),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _startupErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Startup timed out after 30 seconds.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}
// GEMINI-MYTJ: End startup diagnostics and preloader.

class MyApp extends StatefulWidget {
  final Map<String, Map<String, String>>? languages;
  final NotificationBodyModel? body;
  const MyApp({super.key, required this.languages, required this.body});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  String? deeplinkRoute;
  String? _initialRoute;

  @override
  void initState() {
    super.initState();

    if (!GetPlatform.isWeb) {
      _initAppLinks();
    }

    _route();

    _initialRoute = GetPlatform.isWeb
        ? RouteHelper.getInitialRoute()
        : RouteHelper.getSplashRoute(widget.body, deeplinkRoute);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => LanguageLoader.loadRemaining(),
    );
  }

  void _initAppLinks() async {
    _appLinks = AppLinks();

    // Listen for any subsequent incoming links
    _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          if (kDebugMode) {
            print(
              '=======Received URI: $uri and previous deeplinkRoute: ${Get.find<SplashController>().deeplinkRoute}',
            );
          }
          LinkConverter.convertDeepLink(uri);
        }
      },
      onError: (err) {
        if (kDebugMode) {
          print('catch Error in initAppLinksStream: $err');
        }
      },
    );
  }

  void _route() async {
    if (GetPlatform.isWeb) {
      Get.find<SplashController>().initSharedData();
      if (AddressHelper.getUserAddressFromSharedPref() != null &&
          AddressHelper.getUserAddressFromSharedPref()!.zoneIds == null) {
        Get.find<AuthController>().clearSharedAddress();
      }

      if (!AuthHelper.isLoggedIn() && !AuthHelper.isGuestLoggedIn()) {
        await Get.find<AuthController>().guestLogin();
      }

      if ((AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) &&
          Get.find<SplashController>().cacheModule != null) {
        Get.find<CartController>().getAllCarts();
      }

      Get.find<SplashController>().getConfigData(
        loadLandingData:
            (GetPlatform.isWeb &&
            AddressHelper.getUserAddressFromSharedPref() == null),
        fromMainFunction: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetBuilder<LocalizationController>(
          builder: (localizeController) {
            return GetBuilder<SplashController>(
              builder: (splashController) {
                return (GetPlatform.isWeb &&
                        splashController.configModel == null)
                    ? const SizedBox()
                    : GetMaterialApp(
                        title: AppConstants.appName,
                        debugShowCheckedModeBanner: false,
                        navigatorKey: Get.key,
                        scrollBehavior: const MaterialScrollBehavior().copyWith(
                          dragDevices: {
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.touch,
                          },
                        ),
                        theme: themeController.darkTheme ? dark() : light(),
                        locale: localizeController.locale,
                        translations: Messages(languages: widget.languages),
                        fallbackLocale: Locale(
                          AppConstants.languages[0].languageCode!,
                          AppConstants.languages[0].countryCode,
                        ),
                        initialRoute: _initialRoute,
                        getPages: RouteHelper.routes,
                        navigatorObservers: [KeyboardDismissRouteObserver()],
                        routingCallback: (routing) {
                          HomeStatusBarTint.modalOpen.value =
                              routing != null &&
                              ((routing.isBottomSheet ?? false) ||
                                  (routing.isDialog ?? false));
                          if (routing == null ||
                              (routing.isBottomSheet ?? false) ||
                              (routing.isDialog ?? false))
                            return;
                          if (Get.isRegistered<ProController>()) {
                            Get.find<ProController>().maybeShowRenewOnRoute(
                              routing.current,
                            );
                          }
                        },
                        defaultTransition: GetPlatform.isWeb
                            ? Transition.fadeIn
                            : Transition.topLevel,
                        transitionDuration: const Duration(milliseconds: 700),
                        builder: (BuildContext context, widget) {
                          return MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(textScaler: const TextScaler.linear(1)),
                            child: Material(
                              child: SafeArea(
                                top: false,
                                bottom: GetPlatform.isAndroid,
                                child: Stack(
                                  children: [
                                    widget!,

                                    GetBuilder<SplashController>(
                                      builder: (splashController) {
                                        if (!splashController
                                                .savedCookiesData &&
                                            !splashController
                                                .getAcceptCookiesStatus(
                                                  splashController
                                                              .configModel !=
                                                          null
                                                      ? splashController
                                                            .configModel!
                                                            .cookiesText!
                                                      : '',
                                                )) {
                                          return ResponsiveHelper.isWeb()
                                              ? const Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: CookiesView(),
                                                )
                                              : const SizedBox();
                                        } else {
                                          return const SizedBox();
                                        }
                                      },
                                    ),

                                    // Keeps the home dashboard status-bar tint stable above modal
                                    // barriers (bottom sheets / dialogs). Inert unless the home tab
                                    // is the visible, uncovered page.
                                    const HomeStatusBarTintOverlay(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
              },
            );
          },
        );
      },
    );
  }
}
