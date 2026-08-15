import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_drawer.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class DiscountFeeMenuScreen extends StatelessWidget {
  const DiscountFeeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.discountMenu),
      appBar: AppBar(
        title: Text('Diskon, Biaya', style: Theme.of(context).textTheme.titleLarge),
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
                title: 'Diskon',
                subtitle: 'Kelola diskon nominal & persen',
                icon: Icons.percent,
                color: context.colorPrimary,
                route: AppRoutes.discount,
              ),
              const SizedBox(height: AppDimensions.spacingLG),
              _buildMenuCard(
                context,
                title: 'Biaya',
                subtitle: 'Kelola biaya antar, jasa potong, dll',
                icon: Icons.payments_outlined,
                color: Colors.blue.shade600,
                route: AppRoutes.fee,
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
              Icon(Icons.chevron_right, color: context.colorTextHint, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}


