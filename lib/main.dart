import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/sales/sales_screen.dart';
import 'features/product/product_screen.dart';
import 'features/discount/discount_screen.dart';
import 'features/discount/discount_fee_menu_screen.dart';
import 'features/fee/fee_screen.dart';
import 'features/report/report_screen.dart';
import 'features/stock/stock_screen.dart';
import 'features/settings/setting_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DepotKayuApp());
}

class DepotKayuApp extends StatelessWidget {
  const DepotKayuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kembang Jaya POS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.sales: (context) => const SalesScreen(),
        AppRoutes.management: (context) => const ProductScreen(),
        AppRoutes.product: (context) => const ProductScreen(),
        AppRoutes.discountMenu: (context) => const DiscountFeeMenuScreen(),
        AppRoutes.discount: (context) => const DiscountScreen(),
        AppRoutes.fee: (context) => const FeeScreen(),
        AppRoutes.report: (context) => const ReportScreen(),
        AppRoutes.stock: (context) => const StockScreen(),
        AppRoutes.setting: (context) => const SettingScreen(),
      },
    );
  }
}