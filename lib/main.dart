import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'services/entitlement_service.dart';
import 'services/iap_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage and entitlements
  await StorageService.init();
  await EntitlementService.init();
  await IAPService.init();
  
  // Lock to portrait mode for better fidget experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: kBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const FormFreshFidgetApp());
}

class FormFreshFidgetApp extends StatelessWidget {
  const FormFreshFidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FormFresh Fidgets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: kBackground,
      ),
      home: const FidgetHomeScreen(),
    );
  }
}
