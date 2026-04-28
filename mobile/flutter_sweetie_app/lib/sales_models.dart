part of 'main.dart';

class _SaleItemDraft {
  const _SaleItemDraft({
    required this.productId,
    required this.variantId,
    required this.extraToppingIds,
    required this.sugarLevel,
    required this.quantity,
  });

  final int? productId;
  final int? variantId;
  final List<int> extraToppingIds;
  final String sugarLevel;
  final int quantity;

  _SaleItemDraft copyWith({
    int? productId,
    int? variantId,
    List<int>? extraToppingIds,
    String? sugarLevel,
    int? quantity,
  }) {
    return _SaleItemDraft(
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      extraToppingIds: extraToppingIds ?? this.extraToppingIds,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      quantity: quantity ?? this.quantity,
    );
  }
}

Map<String, dynamic> buildSmoothiesSalesTestFixture() {
  return {
    'sales': <Map<String, dynamic>>[
      {
        'transaction_code': 'TRX-1001',
        'sale_number': '11/04/26 - 1',
        'payment_method': 'Cash',
        'payment_status': 'paid',
        'approval_status': 'disetujui',
        'nama_customer': 'Pelanggan Lama',
        'no_telp': '08123456789',
        'promo': null,
        'created_at': '2026-04-11 09:00:00',
        'total_quantity': 1,
        'total_harga': 18000,
        'items': [
          {
            'nama_product': 'Berry Blast - Reguler',
            'quantity': 1,
            'sugar_level': 'Normal',
            'extra_toppings': const [],
          },
        ],
      },
    ],
    'products': <Map<String, dynamic>>[
      {
        'id_product': 1,
        'nama_product': 'Berry Blast',
        'harga': 18000,
        'remaining': 12,
        'option_label': 'Berry Blast | Sisa 12',
        'variants': [
          {
            'id': 11,
            'name': 'Reguler',
            'price': 18000,
            'total_satuan_ml': 350,
            'is_default': true,
          },
          {
            'id': 12,
            'name': 'Large',
            'price': 22000,
            'total_satuan_ml': 500,
            'is_default': false,
          },
        ],
      },
      {
        'id_product': 2,
        'nama_product': 'Tropical Glow',
        'harga': 20000,
        'remaining': 9,
        'option_label': 'Tropical Glow | Sisa 9',
        'variants': [
          {
            'id': 13,
            'name': 'Reguler',
            'price': 20000,
            'total_satuan_ml': 350,
            'is_default': true,
          },
          {
            'id': 14,
            'name': 'Large',
            'price': 24000,
            'total_satuan_ml': 500,
            'is_default': false,
          },
        ],
      },
    ],
    'promos': <Map<String, dynamic>>[
      {
        'id': 99,
        'kode_promo': 'HEMAT5',
        'nama_promo': 'Hemat 5K',
        'potongan': 5000,
        'minimal_quantity': 1,
        'minimal_belanja': 15000,
        'option_label': 'Hemat 5K | HEMAT5',
      },
    ],
    'extra_toppings': <Map<String, dynamic>>[
      {
        'id': 21,
        'name': 'Boba',
        'price': 3000,
      },
      {
        'id': 22,
        'name': 'Chia Seed',
        'price': 4000,
      },
    ],
    'sops': <Map<String, dynamic>>[
      {
        'id_sop': 1,
        'title': 'Pre-Blend Station',
        'detail': 'Cek gelas, blender, dan bahan dasar sebelum proses dimulai.',
      },
      {
        'id_sop': 2,
        'title': 'Final Check Topping',
        'detail': 'Pastikan topping sesuai pesanan sebelum minuman diserahkan.',
      },
      {
        'id_sop': 3,
        'title': 'Serah-Terima Customer',
        'detail':
            'Sebutkan nama menu, size, dan konfirmasi pembayaran saat menyerahkan.',
      },
    ],
  };
}
