import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../constants/app_routes.dart';
import '../../data/dummy/dummy_data.dart';

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
                  const SizedBox(width: 12),
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
                      ValueListenableBuilder<Map<String, String>>(
                        valueListenable: DummyData().currentUser,
                        builder: (context, user, child) {
                          return Text(
                            user['name'] ?? 'Staff',
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
            _DrawerItem(
              icon: Icons.grid_view_rounded,
              label: 'Manajemen',
              route: AppRoutes.management,
              isSelected: currentRoute == AppRoutes.management,
              onTap: () => _navigateTo(context, AppRoutes.management),
            ),
            _DrawerItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Transaksi Penjualan',
              route: AppRoutes.sales,
              isSelected: currentRoute == AppRoutes.sales,
              onTap: () => _navigateTo(context, AppRoutes.sales),
            ),
            _DrawerItem(
              icon: Icons.local_offer_outlined,
              label: 'Diskon, Biaya',
              route: AppRoutes.discountMenu,
              isSelected: currentRoute == AppRoutes.discountMenu,
              onTap: () => _navigateTo(context, AppRoutes.discountMenu),
            ),
            _DrawerItem(
              icon: Icons.bar_chart_rounded,
              label: 'Laporan',
              route: AppRoutes.report,
              isSelected: currentRoute == AppRoutes.report,
              onTap: () => _navigateTo(context, AppRoutes.report),
            ),
            _DrawerItem(
              icon: Icons.inventory_2_outlined,
              label: 'Manajemen Stok',
              route: AppRoutes.stock,
              isSelected: currentRoute == AppRoutes.stock,
              onTap: () => _navigateTo(context, AppRoutes.stock),
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Pengaturan',
              route: AppRoutes.setting,
              isSelected: currentRoute == AppRoutes.setting,
              onTap: () => _navigateTo(context, AppRoutes.setting),
            ),

            const Spacer(),

            // Logout
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              route: '/', // <-- FIX: Diubah jadi '/' biar sesuai main.dart
              isSelected: false,
              isLogout: true,
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 16),
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