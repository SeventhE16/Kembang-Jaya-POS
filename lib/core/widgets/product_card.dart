import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/product_model.dart';
import '../constants/app_colors.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int cartQuantity;
  final VoidCallback? onAdd;
  final bool showEditDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool allowZeroStock;
  final bool showBasePrice;

  const ProductCard({
    super.key,
    required this.product,
    this.cartQuantity = 0,
    this.onAdd,
    this.showEditDelete = false,
    this.onEdit,
    this.onDelete,
    this.allowZeroStock = false,
    this.showBasePrice = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = !allowZeroStock && product.trackStock && product.stock <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colorDivider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colorIconLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: context.colorPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMD),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${_formatNumber((showBasePrice ? product.basePrice : product.sellPrice).toInt())} · Stok ${product.stock}${showEditDelete ? ' ${product.unit}' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colorTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          if (showEditDelete) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined, color: context.colorPrimary, size: 20),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: context.colorPrimary, size: 20),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ] else ...[
            if (cartQuantity > 0) ...[
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${cartQuantity}x',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colorPrimary,
                  ),
                ),
              ),
            ],
            if (isOutOfStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colorStockEmpty,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Stok 0',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              SizedBox(
                width: 40,
                height: 40,
                child: Material(
                  color: context.colorPrimary,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(10),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
}