part of 'main.dart';

Future<void> showSmoothiesSalesHistorySheet(
  BuildContext context, {
  required List<Map<String, dynamic>> sales,
  required NumberFormat currency,
}) {
  return showMaterialModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SalesHistorySheet(
      sales: sales,
      currency: currency,
    ),
  );
}

class _OfflineSalesManagementPage extends StatefulWidget {
  const _OfflineSalesManagementPage({
    required this.sales,
    required this.products,
    required this.promos,
    required this.extraToppings,
    required this.currency,
    required this.onUpdateSale,
    required this.onDeleteSale,
  });

  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> promos;
  final List<Map<String, dynamic>> extraToppings;
  final NumberFormat currency;
  final Future<void> Function({
    required Map<String, dynamic> sale,
    required Map<String, dynamic> payload,
  }) onUpdateSale;
  final Future<void> Function(Map<String, dynamic> sale) onDeleteSale;

  @override
  State<_OfflineSalesManagementPage> createState() =>
      _OfflineSalesManagementPageState();
}

class _OfflineSalesManagementPageState
    extends State<_OfflineSalesManagementPage> {
  late List<Map<String, dynamic>> _sales;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _sales =
        widget.sales.map((sale) => Map<String, dynamic>.from(sale)).toList();
  }

  Future<void> _editSale(Map<String, dynamic> sale) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _OfflineSaleEditorDialog(
        sale: sale,
        products: widget.products,
        promos: widget.promos,
        extraToppings: widget.extraToppings,
        currency: widget.currency,
      ),
    );

    if (!mounted || payload == null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.onUpdateSale(sale: sale, payload: payload);
      setState(() {
        final index = _sales.indexWhere(
          (entry) =>
              entry['transaction_code']?.toString() ==
              sale['transaction_code']?.toString(),
        );
        if (index >= 0) {
          _sales[index] = _applyUpdatedSale(_sales[index], payload);
        }
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _deleteSale(Map<String, dynamic> sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus transaksi'),
        content: Text(
          'Transaksi ${sale['transaction_code'] ?? '-'} akan dihapus. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.onDeleteSale(sale);
      setState(() {
        _sales.removeWhere(
          (entry) =>
              entry['transaction_code']?.toString() ==
              sale['transaction_code']?.toString(),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Map<String, dynamic> _applyUpdatedSale(
    Map<String, dynamic> current,
    Map<String, dynamic> payload,
  ) {
    final promoId = payload['promo_id'] as int?;
    final promo = widget.promos.cast<Map<String, dynamic>?>().firstWhere(
          (item) => (item?['id'] as num?)?.toInt() == promoId,
          orElse: () => null,
        );
    final items = ((payload['items'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(_buildDisplayItem)
        .toList();
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + ((item['harga'] as num?)?.toDouble() ?? 0),
    );
    final discount = (promo?['potongan'] as num?)?.toDouble() ?? 0;

    return {
      ...current,
      'nama_customer': payload['customer_nama'],
      'no_telp': payload['customer_no_telp'],
      'tiktok_instagram': payload['customer_tiktok_instagram'],
      'promo_id': promoId,
      'promo': promo?['nama_promo'],
      'kode_promo': promo?['kode_promo'],
      'payment_method': payload['payment_method'],
      'total_quantity': items.fold<int>(
        0,
        (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
      ),
      'total_harga': (subtotal - discount).clamp(0, subtotal),
      'items': items,
    };
  }

  Map<String, dynamic> _buildDisplayItem(Map<String, dynamic> item) {
    final productId = (item['id_product'] as num?)?.toInt();
    final variantId = (item['product_variant_id'] as num?)?.toInt();
    final product = widget.products.cast<Map<String, dynamic>?>().firstWhere(
          (entry) => (entry?['id_product'] as num?)?.toInt() == productId,
          orElse: () => null,
        );
    final variants =
        ((product?['variants'] as List?) ?? []).cast<Map<String, dynamic>>();
    final variant = variants.cast<Map<String, dynamic>?>().firstWhere(
          (entry) => (entry?['id'] as num?)?.toInt() == variantId,
          orElse: () => null,
        );
    final extraToppingIds =
        ((item['extra_topping_ids'] as List?) ?? []).cast<int>();
    final toppings = widget.extraToppings
        .where(
            (entry) => extraToppingIds.contains((entry['id'] as num?)?.toInt()))
        .map(
          (entry) => {
            'id': entry['id'],
            'name': entry['name'],
            'price': entry['price'],
          },
        )
        .toList();
    final unitPrice = ((variant?['price'] as num?)?.toDouble() ??
            (product?['harga'] as num?)?.toDouble() ??
            0) +
        toppings.fold<double>(
          0,
          (sum, entry) => sum + ((entry['price'] as num?)?.toDouble() ?? 0),
        );
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

    return {
      'id_product': productId,
      'nama_product':
          '${product?['nama_product'] ?? '-'}${variant?['name'] != null ? ' - ${variant?['name']}' : ''}',
      'product_variant_id': variantId,
      'product_variant_name': variant?['name'],
      'extra_topping_ids': extraToppingIds,
      'extra_toppings': toppings,
      'sugar_level': item['sugar_level'] ?? 'Normal',
      'quantity': quantity,
      'harga': unitPrice * quantity,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _BlockCard(
          title: 'Penjualan Offline',
          subtitle:
              'Riwayat transaksi kasir offline. Owner bisa edit atau hapus tiap transaksi dari sini.',
          child: _sales.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Belum ada transaksi offline yang tersimpan.'),
                )
              : Column(
                  children: _sales.map((sale) {
                    final items = ((sale['items'] as List?) ?? [])
                        .cast<Map<String, dynamic>>();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE7D9F4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sale['transaction_code']?.toString() ??
                                          '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sale['nama_customer']
                                                  ?.toString()
                                                  .trim()
                                                  .isNotEmpty ==
                                              true
                                          ? sale['nama_customer'].toString()
                                          : 'Customer umum',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusChip(
                                label:
                                    sale['approval_status']?.toString() ?? '-',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MiniPill(
                                label:
                                    'Qty ${((sale['total_quantity'] as num?)?.toInt() ?? 0)}',
                              ),
                              _MiniPill(
                                label: sale['payment_method']?.toString() ??
                                    'Cash',
                              ),
                              _MiniPill(
                                label: widget.currency.format(
                                  (sale['total_harga'] as num?)?.toDouble() ??
                                      0,
                                ),
                              ),
                              _MiniPill(
                                label: sale['promo']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? sale['promo'].toString()
                                    : 'Tanpa promo',
                              ),
                            ],
                          ),
                          if (items.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...items.take(5).map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '${item['nama_product'] ?? '-'} x${item['quantity'] ?? 0} • Sugar ${item['sugar_level'] ?? 'Normal'}${(((item['extra_toppings'] as List?) ?? []).isEmpty) ? '' : ' • ${((item['extra_toppings'] as List?) ?? []).cast<Map<String, dynamic>>().map((topping) => topping['name']).whereType<String>().join(', ')}'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed:
                                    _submitting ? null : () => _editSale(sale),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _submitting
                                    ? null
                                    : () => _deleteSale(sale),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _OfflineSaleEditorDialog extends StatefulWidget {
  const _OfflineSaleEditorDialog({
    required this.sale,
    required this.products,
    required this.promos,
    required this.extraToppings,
    required this.currency,
  });

  final Map<String, dynamic> sale;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> promos;
  final List<Map<String, dynamic>> extraToppings;
  final NumberFormat currency;

  @override
  State<_OfflineSaleEditorDialog> createState() =>
      _OfflineSaleEditorDialogState();
}

class _OfflineSaleEditorDialogState extends State<_OfflineSaleEditorDialog> {
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _customerSocialController;
  late List<_OfflineSaleEditorLine> _lines;
  late String _paymentMethod;
  int? _promoId;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(
      text: widget.sale['nama_customer']?.toString() ?? '',
    );
    _customerPhoneController = TextEditingController(
      text: widget.sale['no_telp']?.toString() ?? '',
    );
    _customerSocialController = TextEditingController(
      text: widget.sale['tiktok_instagram']?.toString() ?? '',
    );
    _paymentMethod = widget.sale['payment_method']?.toString() ?? 'Cash';
    _promoId = (widget.sale['promo_id'] as num?)?.toInt();
    _lines = ((widget.sale['items'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(
          (item) => _OfflineSaleEditorLine(
            saleItemId: (item['id_penjualan_offline'] as num?)?.toInt(),
            productId: (item['id_product'] as num?)?.toInt(),
            variantId: (item['product_variant_id'] as num?)?.toInt(),
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            sugarLevel: item['sugar_level']?.toString() ?? 'Normal',
            extraToppingIds:
                ((item['extra_topping_ids'] as List?) ?? []).cast<int>(),
          ),
        )
        .toList();
    if (_lines.isEmpty) {
      _lines = [const _OfflineSaleEditorLine()];
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerSocialController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _productById(int? id) {
    for (final product in widget.products) {
      if ((product['id_product'] as num?)?.toInt() == id) {
        return product;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _variantsForProduct(int? productId) {
    final product = _productById(productId);
    return ((product?['variants'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  int? _defaultVariantId(int? productId) {
    final variants = _variantsForProduct(productId);
    for (final variant in variants) {
      if (variant['is_default'] == true) {
        return (variant['id'] as num?)?.toInt();
      }
    }
    if (variants.isEmpty) {
      return null;
    }
    return (variants.first['id'] as num?)?.toInt();
  }

  String _toppingLabel(List<int> toppingIds) {
    if (toppingIds.isEmpty) {
      return 'Tanpa topping';
    }

    return widget.extraToppings
        .where((item) => toppingIds.contains((item['id'] as num?)?.toInt()))
        .map((item) => item['name']?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .join(', ');
  }

  Future<void> _editToppings(int index) async {
    final working = _lines[index].extraToppingIds.toSet();
    final selected = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Extra Topping'),
          content: SizedBox(
            width: 420,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.extraToppings.map((topping) {
                final id = (topping['id'] as num?)?.toInt();
                final isSelected = id != null && working.contains(id);

                return FilterChip(
                  selected: isSelected,
                  label: Text(
                    '${topping['name'] ?? 'Topping'} • ${widget.currency.format((topping['price'] as num?)?.toDouble() ?? 0)}',
                  ),
                  onSelected: id == null
                      ? null
                      : (value) {
                          setDialogState(() {
                            if (value) {
                              working.add(id);
                            } else {
                              working.remove(id);
                            }
                          });
                        },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(const <int>[]),
              child: const Text('Kosongkan'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                working.toList()..sort(),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _lines[index] = _lines[index].copyWith(extraToppingIds: selected);
    });
  }

  Map<String, dynamic> _collectPayload() {
    return {
      'customer_nama': _customerNameController.text.trim(),
      'customer_no_telp': _customerPhoneController.text.trim(),
      'customer_tiktok_instagram': _customerSocialController.text.trim(),
      'payment_method': _paymentMethod,
      if (_promoId != null) 'promo_id': _promoId,
      'items': _lines
          .where((line) => line.productId != null && line.quantity > 0)
          .map(
            (line) => {
              if (line.saleItemId != null)
                'id_penjualan_offline': line.saleItemId,
              'id_product': line.productId,
              if (line.variantId != null) 'product_variant_id': line.variantId,
              'quantity': line.quantity,
              'sugar_level': line.sugarLevel,
              'extra_topping_ids': line.extraToppingIds,
            },
          )
          .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Penjualan Offline'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'Nama customer'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerPhoneController,
                decoration: const InputDecoration(labelText: 'No. telepon'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerSocialController,
                decoration:
                    const InputDecoration(labelText: 'TikTok / Instagram'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration:
                    const InputDecoration(labelText: 'Metode pembayaran'),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Qris', child: Text('Qris')),
                ],
                onChanged: (value) =>
                    setState(() => _paymentMethod = value ?? 'Cash'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _promoId,
                decoration: const InputDecoration(labelText: 'Promo'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tanpa promo'),
                  ),
                  ...widget.promos.map(
                    (promo) => DropdownMenuItem<int?>(
                      value: (promo['id'] as num?)?.toInt(),
                      child: Text(
                        promo['nama_promo']?.toString() ?? 'Promo',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _promoId = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Item transaksi',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _lines.add(const _OfflineSaleEditorLine());
                    }),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._lines.asMap().entries.map((entry) {
                final index = entry.key;
                final line = entry.value;
                final variants = _variantsForProduct(line.productId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF6FE),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7D9F4)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Item ${index + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: _lines.length == 1
                                ? null
                                : () => setState(() => _lines.removeAt(index)),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: line.productId,
                        decoration: const InputDecoration(labelText: 'Product'),
                        items: widget.products.map((product) {
                          return DropdownMenuItem<int>(
                            value: (product['id_product'] as num?)?.toInt(),
                            child: Text(
                              product['nama_product']?.toString() ?? '-',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _lines[index] = _lines[index].copyWith(
                              productId: value,
                              variantId: _defaultVariantId(value),
                              clearVariantId:
                                  _variantsForProduct(value).isEmpty,
                            );
                          });
                        },
                      ),
                      if (variants.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: line.variantId ??
                              _defaultVariantId(line.productId),
                          decoration:
                              const InputDecoration(labelText: 'Varian'),
                          items: variants.map((variant) {
                            return DropdownMenuItem<int>(
                              value: (variant['id'] as num?)?.toInt(),
                              child: Text(
                                '${variant['name'] ?? 'Varian'} • ${widget.currency.format((variant['price'] as num?)?.toDouble() ?? 0)}',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() {
                            _lines[index] =
                                _lines[index].copyWith(variantId: value);
                          }),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '${line.quantity}',
                              decoration:
                                  const InputDecoration(labelText: 'Quantity'),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final quantity = int.tryParse(value) ?? 1;
                                _lines[index] = _lines[index].copyWith(
                                  quantity: quantity.clamp(1, 999),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: line.sugarLevel,
                              decoration: const InputDecoration(
                                  labelText: 'Sugar Level'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Normal',
                                  child: Text('Normal'),
                                ),
                                DropdownMenuItem(
                                  value: 'Less',
                                  child: Text('Less'),
                                ),
                                DropdownMenuItem(
                                  value: 'No Sugar',
                                  child: Text('No Sugar'),
                                ),
                              ],
                              onChanged: (value) => setState(() {
                                _lines[index] = _lines[index].copyWith(
                                  sugarLevel: value ?? 'Normal',
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Topping: ${_toppingLabel(line.extraToppingIds)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _editToppings(index),
                            child: const Text('Pilih topping'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final payload = _collectPayload();
            final items = ((payload['items'] as List?) ?? []);
            if (items.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Tambahkan minimal satu item transaksi.')),
              );
              return;
            }
            Navigator.of(context).pop(payload);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _OfflineSaleEditorLine {
  const _OfflineSaleEditorLine({
    this.saleItemId,
    this.productId,
    this.variantId,
    this.quantity = 1,
    this.sugarLevel = 'Normal',
    this.extraToppingIds = const <int>[],
  });

  final int? saleItemId;
  final int? productId;
  final int? variantId;
  final int quantity;
  final String sugarLevel;
  final List<int> extraToppingIds;

  _OfflineSaleEditorLine copyWith({
    int? productId,
    int? variantId,
    int? quantity,
    String? sugarLevel,
    List<int>? extraToppingIds,
    bool clearVariantId = false,
  }) {
    return _OfflineSaleEditorLine(
      saleItemId: this.saleItemId,
      productId: productId ?? this.productId,
      variantId: clearVariantId ? null : (variantId ?? this.variantId),
      quantity: quantity ?? this.quantity,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      extraToppingIds: extraToppingIds ?? this.extraToppingIds,
    );
  }
}
