import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_drawer.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class DebtReceivableMenuScreen extends StatelessWidget {
  const DebtReceivableMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.piutang),
      appBar: AppBar(
        title: Text('Piutang & Hutang', style: Theme.of(context).textTheme.titleLarge),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMenuCard(
                context,
                title: 'Piutang',
                subtitle: 'Kelola tagihan pelanggan',
                icon: Icons.account_balance_wallet_outlined,
                color: context.colorPrimary,
                route: '/piutang_pelanggan',
              ),
              const SizedBox(height: AppDimensions.spacingLG),
              _buildMenuCard(
                context,
                title: 'Hutang',
                subtitle: 'Kelola hutang ke supplier',
                icon: Icons.store_mall_directory_outlined,
                color: context.colorError,
                route: '/hutang_supplier',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppDimensions.radius),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(AppDimensions.radius),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingLG),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radius),
            border: Border.all(color: context.colorDivider, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingMD),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: context.colorTextSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colorTextSecondary, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}