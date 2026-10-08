import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/screens/splash_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_notification_service.dart';
import 'package:yesdhobi_ridervendor/services/vendor_notification_service.dart';
import 'package:yesdhobi_ridervendor/services/api_client.dart';
import 'package:yesdhobi_ridervendor/services/vendor_order_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();
  await VendorOrderService.instance.init();
  await RiderNotificationService.instance.initialize();
  await VendorNotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: RiderNotificationService.instance.navigatorKey,
      title: 'Yes Dhobi Partner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
