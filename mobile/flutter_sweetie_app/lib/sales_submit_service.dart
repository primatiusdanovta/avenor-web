part of 'main.dart';

class _SalesSubmitService {
  static Future<Map<String, dynamic>?> submit({
    required Dio dio,
    required bool mockMode,
    required Map<String, dynamic>? salesPayload,
    required Map<String, dynamic>? productsPayload,
    required Map<String, dynamic>? queuePayload,
    required String customerName,
    required String customerPhone,
    required String customerSocial,
    required List<_SaleItemDraft> items,
    required String paymentMethod,
    required bool requireProof,
    required int? promoId,
    required XFile? proof,
    required Future<void> Function() onRefreshAll,
    required VoidCallback onSyncMockDerivedState,
    required bool Function(Map<String, dynamic>) isCountedAsOnHand,
    required String Function(DateTime) formatYmdHis,
  }) async {
    if (mockMode) {
      return _submitMock(
        salesPayload: salesPayload,
        productsPayload: productsPayload,
        queuePayload: queuePayload,
        customerName: customerName,
        items: items,
        paymentMethod: paymentMethod,
        promoId: promoId,
        onSyncMockDerivedState: onSyncMockDerivedState,
        isCountedAsOnHand: isCountedAsOnHand,
        formatYmdHis: formatYmdHis,
      );
    }

    final form = FormData();
    form.fields
      ..add(MapEntry('customer_nama', customerName))
      ..add(MapEntry('payment_method', paymentMethod));

    if (promoId != null) {
      form.fields.add(MapEntry('promo_id', '$promoId'));
    }

    for (var index = 0; index < items.length; index++) {
      form.fields
        ..add(
            MapEntry('items[$index][id_product]', '${items[index].productId}'))
        ..add(MapEntry('items[$index][quantity]', '${items[index].quantity}'));

      if (items[index].variantId != null) {
        form.fields.add(
          MapEntry(
            'items[$index][product_variant_id]',
            '${items[index].variantId}',
          ),
        );
      }

      for (var toppingIndex = 0;
          toppingIndex < items[index].extraToppingIds.length;
          toppingIndex++) {
        form.fields.add(
          MapEntry(
            'items[$index][extra_topping_ids][$toppingIndex]',
            '${items[index].extraToppingIds[toppingIndex]}',
          ),
        );
      }
    }

    final response = await dio.post('/offline-sales', data: form);
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : null;
  }

  static Map<String, dynamic> _submitMock({
    required Map<String, dynamic>? salesPayload,
    required Map<String, dynamic>? productsPayload,
    required Map<String, dynamic>? queuePayload,
    required String customerName,
    required List<_SaleItemDraft> items,
    required String paymentMethod,
    required int? promoId,
    required VoidCallback onSyncMockDerivedState,
    required bool Function(Map<String, dynamic>) isCountedAsOnHand,
    required String Function(DateTime) formatYmdHis,
  }) {
    final products = ((salesPayload?['products'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final catalogProducts = ((productsPayload?['products'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final promos =
        ((salesPayload?['promos'] as List?) ?? []).cast<Map<String, dynamic>>();
    final extraToppings = ((salesPayload?['extra_toppings'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    Map<String, dynamic>? promo;
    if (promoId != null) {
      for (final entry in promos) {
        if (entry['id'] == promoId) {
          promo = entry;
          break;
        }
      }
    }

    double subtotal = 0;
    final mappedItems = <Map<String, dynamic>>[];

    for (final item in items) {
      final product =
          products.firstWhere((entry) => entry['id_product'] == item.productId);
      final variants =
          ((product['variants'] as List?) ?? []).cast<Map<String, dynamic>>();
      Map<String, dynamic>? variant;
      for (final entry in variants) {
        if ((entry['id'] as num?)?.toInt() == item.variantId) {
          variant = entry;
          break;
        }
      }
      variant ??= variants.isEmpty
          ? null
          : variants.firstWhere(
              (entry) => entry['is_default'] == true,
              orElse: () => variants.first,
            );

      final selectedExtraToppings = extraToppings.where((entry) {
        final toppingId = (entry['id'] as num?)?.toInt();
        return toppingId != null && item.extraToppingIds.contains(toppingId);
      }).toList();

      final unitPrice = ((variant?['price'] as num?)?.toDouble() ??
              (product['harga'] as num?)?.toDouble() ??
              0)
          .toDouble();
      final toppingPerUnit = selectedExtraToppings.fold<double>(
        0,
        (sum, entry) => sum + ((entry['price'] as num?)?.toDouble() ?? 0),
      );
      final line = (unitPrice + toppingPerUnit) * item.quantity;
      subtotal += line;
      final updatedRemaining = max(
        (((product['remaining'] ?? product['stock']) as num?)?.toInt() ?? 0) -
            item.quantity,
        0,
      );
      product['remaining'] = updatedRemaining;
      product['stock'] = updatedRemaining;
      product['option_label'] = '${product['nama_product']} | stock $updatedRemaining';

      for (final catalogProduct in catalogProducts) {
        if (catalogProduct['id_product'] == item.productId) {
          final stock = (catalogProduct['stock'] as num?)?.toInt() ?? 0;
          final updatedStock = max(stock - item.quantity, 0);
          catalogProduct['stock'] = updatedStock;
          catalogProduct['option_label'] =
              '${catalogProduct['nama_product']} | stock $updatedStock';
          break;
        }
      }

      mappedItems.add({
        'id_product': item.productId,
        'nama_product':
            '${product['nama_product']}${variant?['name'] != null ? ' - ${variant?['name']}' : ''}',
        'product_variant_id': item.variantId,
        'product_variant_name': variant?['name'],
        'extra_topping_ids': item.extraToppingIds,
        'extra_toppings': selectedExtraToppings,
        'quantity': item.quantity,
        'harga': line,
      });
    }

    final discount = (promo?['potongan'] as num?)?.toDouble() ?? 0;
    final total = (subtotal - discount).clamp(0, subtotal).toDouble();
    final sales =
        ((salesPayload?['sales'] as List?) ?? []).cast<Map<String, dynamic>>();
    final now = DateTime.now();

    final saleNumber =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${(now.year % 100).toString().padLeft(2, '0')} - ${sales.length + 1}';
    final transactionCode = 'TRX-${now.millisecondsSinceEpoch}';

    sales.insert(0, {
      'transaction_code': transactionCode,
      'sale_number': saleNumber,
      'payment_method': paymentMethod,
      'payment_status': 'paid',
      'approval_status': 'disetujui',
      'nama_customer': customerName,
      'promo': promo?['nama_promo'],
      'created_at': formatYmdHis(now),
      'total_quantity': items.fold<int>(0, (sum, item) => sum + item.quantity),
      'total_harga': total,
      'items': mappedItems,
    });

    final queueItems =
        ((queuePayload?['items'] as List?) ?? []).cast<Map<String, dynamic>>();
    final queueNumber = queueItems
            .where((item) => item['sale_number']?.toString().startsWith(
                      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${(now.year % 100).toString().padLeft(2, '0')}',
                    ) ==
                true)
            .length +
        1;
    queueItems.add({
      'sale_number': saleNumber,
      'queue_number': queueNumber,
      'transaction_code': transactionCode,
      'customer_name': customerName,
      'payment_status': 'paid',
      'created_at': formatYmdHis(now),
      'details': mappedItems
          .map((item) => {
                'nama_product': item['nama_product'],
                'quantity': item['quantity'],
                'extra_toppings': ((item['extra_toppings'] as List?) ?? [])
                    .cast<Map<String, dynamic>>()
                    .map((entry) => entry['name']?.toString() ?? '')
                    .where((name) => name.isNotEmpty)
                    .toList(),
              })
          .toList(),
    });

    final onhands =
        ((productsPayload?['onhands'] as List?) ?? []).cast<Map<String, dynamic>>();
    if (onhands.isNotEmpty) {
      for (final item in items) {
        var remainingToDeduct = item.quantity;
        for (final onhand in onhands) {
          if (remainingToDeduct <= 0) {
            break;
          }
          if (onhand['id_product'] != item.productId ||
              !isCountedAsOnHand(onhand)) {
            continue;
          }

          final available =
              (onhand['remaining_quantity'] as num?)?.toInt() ?? 0;
          final deducted =
              available >= remainingToDeduct ? remainingToDeduct : available;
          final remaining = available - deducted;

          onhand['sold_quantity'] =
              ((onhand['sold_quantity'] as num?)?.toInt() ?? 0) + deducted;
          onhand['remaining_quantity'] = remaining;
          onhand['sold_out'] = remaining == 0;
          onhand['status_label'] = remaining == 0 ? 'Sold out' : 'Masih dibawa';
          onhand['max_return'] = remaining;

          remainingToDeduct -= deducted;
        }
      }
    }

    onSyncMockDerivedState();

    return {
      'transaction_code': transactionCode,
      'sale_number': saleNumber,
      'created_at': formatYmdHis(now),
      'customer_name': customerName,
      'total_amount': total,
    };
  }
}
