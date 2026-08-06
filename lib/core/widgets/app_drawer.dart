import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../constants/app_routes.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/cart_provider.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {

    return Drawer(
      backgroundColor: Theme.of(context).drawerTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Image.asset(
                    AppAssets.logo,
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(width: AppDimensions.spacingMD),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kembang Jaya',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.user;
                          return Text(
                            user?.displayName ?? 'Staff',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // Menu Items
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final userModel = authProvider.userModel;
                
                return Column(
                  children: [
                    if (userModel?.hasAccess('management') ?? false)
                      _DrawerItem(
                        icon: Icons.grid_view_rounded,
                        label: 'Manajemen',
                        route: AppRoutes.product,
                        isSelected: currentRoute == AppRoutes.product,
                        onTap: () => _navigateTo(context, AppRoutes.product),
                      ),
                    if (userModel?.hasAccess('sales') ?? true) // default true if needed, but safer false. Let's make it true for sales if userModel is null so app isn't empty on load.
                      _DrawerItem(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Transaksi Penjualan',
                        route: AppRoutes.sales,
                        isSelected: currentRoute == AppRoutes.sales,
                        onTap: () => _navigateTo(context, AppRoutes.sales),
                      ),
                    if (userModel?.hasAccess('holdOrders') ?? true)
                      _DrawerItem(
                        icon: Icons.pause_circle_outline,
                        label: 'Pesanan Tertunda',
                        route: AppRoutes.holdOrders,
                        isSelected: currentRoute == AppRoutes.holdOrders,
                        onTap: () => _navigateTo(context, AppRoutes.holdOrders),
                      ),
                    if (userModel?.hasAccess('piutang') ?? true)
                      _DrawerItem(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Piutang & Hutang',
                        route: AppRoutes.piutang,
                        isSelected: currentRoute == AppRoutes.piutang,
                        onTap: () => _navigateTo(context, AppRoutes.piutang),
                      ),
                    if (userModel?.hasAccess('management') ?? false)
                      _DrawerItem(
                        icon: Icons.local_offer_outlined,
                        label: 'Diskon, Biaya',
                        route: AppRoutes.discountMenu,
                        isSelected: currentRoute == AppRoutes.discountMenu,
                        onTap: () => _navigateTo(context, AppRoutes.discountMenu),
                      ),
                    if (userModel?.hasAccess('report') ?? false)
                      _DrawerItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'Laporan',
                        route: AppRoutes.report,
                        isSelected: currentRoute == AppRoutes.report,
                        onTap: () => _navigateTo(context, AppRoutes.report),
                      ),
                    if (userModel?.hasAccess('management') ?? false)
                      _DrawerItem(
                        icon: Icons.inventory_2_outlined,
                        label: 'Suplai Barang',
                        route: AppRoutes.stock,
                        isSelected: currentRoute == AppRoutes.stock,
                        onTap: () => _navigateTo(context, AppRoutes.stock),
                      ),
                    if (userModel?.hasAccess('management') ?? false)
                      _DrawerItem(
                        icon: Icons.fact_check_outlined,
                        label: 'Stok Opname',
                        route: AppRoutes.stokOpname,
                        isSelected: currentRoute == AppRoutes.stokOpname,
                        onTap: () => _navigateTo(context, AppRoutes.stokOpname),
                      ),
                    if (userModel?.hasAccess('management') ?? false)
                      _DrawerItem(
                        icon: Icons.swap_horiz,
                        label: 'Mutasi Grade',
                        route: '/mutation',
                        isSelected: currentRoute == '/mutation',
                        onTap: () => _navigateTo(context, '/mutation'),
                      ),
                    _DrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Pengaturan',
                      route: AppRoutes.setting,
                      isSelected: currentRoute == AppRoutes.setting,
                      onTap: () => _navigateTo(context, AppRoutes.setting),
                    ),
                  ],
                );
              },
            ),

            const Spacer(),

            // Logout
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              route: '/', // <-- FIX: Diubah jadi '/' biar sesuai main.dart
              isSelected: false,
              isLogout: true,
              onTap: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: AppDimensions.spacingMD),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    // <-- FIX: Tangkap navigator sebelum context dibunuh oleh pop
    final navigator = Navigator.of(context);
    navigator.pop(); // close drawer

    if (currentRoute != route) {
      Provider.of<CartProvider>(context, listen: false).clearCart();
      navigator.pushReplacementNamed(route); // Pakai variable navigator
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;
  final bool isLogout;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLogout
        ? AppColors.primary
        : isSelected
        ? AppColors.primary
        : Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 24),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}








