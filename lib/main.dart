import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/product_provider.dart';
import 'data/providers/customer_provider.dart';
import 'data/providers/supplier_provider.dart';
import 'data/providers/settings_provider.dart';
import 'data/providers/transaction_provider.dart';
import 'data/providers/cart_provider.dart';
import 'data/providers/restock_cart_provider.dart';
import 'data/providers/discount_provider.dart';
import 'data/providers/fee_provider.dart';
import 'data/providers/mutation_provider.dart';
import 'data/providers/audit_provider.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_indicator.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/sync_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/sales/sales_screen.dart';
import 'features/sales/cart_screen.dart';
import 'features/sales/payment_screen.dart';
import 'features/sales/confirmation_screen.dart';
import 'features/sales/hold_order_screen.dart';
import 'features/sales/piutang_screen.dart';
import 'features/sales/debt_receivable_menu_screen.dart';
import 'features/sales/hutang_screen.dart';
import 'features/stock/stok_opname_screen.dart';
import 'features/product/product_screen.dart';
import 'features/discount/discount_screen.dart';
import 'features/discount/discount_fee_menu_screen.dart';
import 'features/fee/fee_screen.dart';
import 'features/report/report_screen.dart';
import 'features/report/report_detail_screen.dart';
import 'features/report/stock_opname_detail_screen.dart';
import 'features/report/installment_detail_screen.dart';
import 'features/report/struk_screen.dart';
import 'features/stock/add_stock_screen.dart';
import 'features/stock/restock_cart_screen.dart';
import 'features/stock/restock_payment_screen.dart';
import 'features/stock/restock_confirmation_screen.dart';
import 'features/stock/mutation_screen.dart';
import 'features/settings/setting_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('id', null);

  // Clear up old temporary struk files that might bloat the app size
  try {
    final directory = await getTemporaryDirectory();
    final files = directory.listSync();
    for (var file in files) {
      if (file is File && file.path.contains('struk_') && file.path.endsWith('.png')) {
        await file.delete();
      }
    }
  } catch (e) {
    debugPrint('Cleanup error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => RestockCartProvider()),
        ChangeNotifierProvider(create: (_) => DiscountProvider()),
        ChangeNotifierProvider(create: (_) => FeeProvider()),
        ChangeNotifierProvider(create: (_) => MutationProvider()),
        ChangeNotifierProvider(create: (_) => AuditProvider()),
      ],
      child: const DepotKayuApp(),
    ),
  );
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
      builder: (context, child) => OfflineIndicator(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: child ?? const SizedBox(),
        ),
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.sync: (context) => const SyncScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.sales: (context) => const SalesScreen(),
        AppRoutes.cart: (context) => const CartScreen(),
        AppRoutes.payment: (context) => const PaymentScreen(),
        AppRoutes.confirmation: (context) => const ConfirmationScreen(),
        AppRoutes.restockCart: (context) => const RestockCartScreen(),
        AppRoutes.restockPayment: (context) => const RestockPaymentScreen(),
        AppRoutes.restockConfirmation: (context) => const RestockConfirmationScreen(),
        AppRoutes.holdOrders: (context) => const HoldOrderScreen(),
        '/piutang': (context) => const DebtReceivableMenuScreen(),
        '/piutang_pelanggan': (context) => const PiutangScreen(),
        '/hutang_supplier': (context) => const HutangScreen(),
        AppRoutes.stokOpname: (context) => const StokOpnameScreen(),
        AppRoutes.stock: (context) => const AddStockScreen(),
        '/mutation': (context) => const MutationScreen(),
        AppRoutes.product: (context) => const ProductScreen(),
        AppRoutes.discountMenu: (context) => const DiscountFeeMenuScreen(),
        AppRoutes.discount: (context) => const DiscountScreen(),
        AppRoutes.fee: (context) => const FeeScreen(),
        AppRoutes.report: (context) => const ReportScreen(),
        AppRoutes.setting: (context) => const SettingScreen(),
        '/report_detail': (context) => const ReportDetailScreen(),
        '/report_stock_opname_detail': (context) => const StockOpnameDetailScreen(),
        '/installment_detail': (context) => const InstallmentDetailScreen(),
        '/struk': (context) => const StrukScreen(),
      },
    );
  }
}




