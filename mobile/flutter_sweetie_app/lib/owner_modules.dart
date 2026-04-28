part of 'main.dart';

const List<NavigationDestination> _ownerDestinations = <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    label: 'Dashboard',
  ),
  NavigationDestination(
    icon: Icon(Icons.inventory_2_outlined),
    selectedIcon: Icon(Icons.inventory_2),
    label: 'Stock',
  ),
  NavigationDestination(
    icon: Icon(Icons.groups_outlined),
    selectedIcon: Icon(Icons.groups),
    label: 'Karyawan',
  ),
  NavigationDestination(
    icon: Icon(Icons.account_balance_wallet_outlined),
    selectedIcon: Icon(Icons.account_balance_wallet),
    label: 'Finance',
  ),
  NavigationDestination(
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings),
    label: 'Pengaturan',
  ),
];

const List<NavigationDestination> _employeeDestinations =
    <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.fingerprint_outlined),
    selectedIcon: Icon(Icons.fingerprint),
    label: 'Absensi',
  ),
  NavigationDestination(
    icon: Icon(Icons.point_of_sale_outlined),
    selectedIcon: Icon(Icons.point_of_sale),
    label: 'Kasir',
  ),
  NavigationDestination(
    icon: Icon(Icons.auto_stories_outlined),
    selectedIcon: Icon(Icons.auto_stories),
    label: 'Knowledge',
  ),
];

enum _OwnerModuleType { generic, hpp, salesTargets, readOnly }

class _OwnerModuleDefinition {
  const _OwnerModuleDefinition({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.type = _OwnerModuleType.generic,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final _OwnerModuleType type;
}

const List<_OwnerModuleDefinition> _ownerStockModules = [
  _OwnerModuleDefinition(
    key: 'products',
    title: 'Product',
    subtitle: 'CRUD product owner terhubung ke website.',
    icon: Icons.shopping_bag_rounded,
    accent: Color(0xFF6F90D8),
  ),
  _OwnerModuleDefinition(
    key: 'hpp',
    title: 'HPP',
    subtitle: 'Kelola perhitungan HPP product.',
    icon: Icons.calculate_rounded,
    accent: Color(0xFF8E79D6),
    type: _OwnerModuleType.hpp,
  ),
  _OwnerModuleDefinition(
    key: 'raw-materials',
    title: 'Raw Material',
    subtitle: 'CRUD bahan baku dan waste.',
    icon: Icons.science_rounded,
    accent: Color(0xFFD980B4),
  ),
  _OwnerModuleDefinition(
    key: 'extra-toppings',
    title: 'Extra Topping',
    subtitle: 'CRUD topping untuk kasir.',
    icon: Icons.icecream_rounded,
    accent: Color(0xFF84A7E8),
  ),
];

const List<_OwnerModuleDefinition> _ownerEmployeeModules = [
  _OwnerModuleDefinition(
    key: 'notifications',
    title: 'Notifications',
    subtitle: 'CRUD notifikasi karyawan.',
    icon: Icons.notifications_active_rounded,
    accent: Color(0xFFD980B4),
  ),
  _OwnerModuleDefinition(
    key: 'attendance-history',
    title: 'Absensi Karyawan',
    subtitle: 'Riwayat absensi karyawan dengan filter tanggal.',
    icon: Icons.event_note_rounded,
    accent: Color(0xFF8E79D6),
    type: _OwnerModuleType.readOnly,
  ),
  _OwnerModuleDefinition(
    key: 'product-knowledge',
    title: 'Product Knowledge',
    subtitle: 'Kelola panduan product dari data website.',
    icon: Icons.menu_book_rounded,
    accent: Color(0xFF6F90D8),
  ),
];

const List<_OwnerModuleDefinition> _ownerFinanceModules = [
  _OwnerModuleDefinition(
    key: 'offline-sales-history',
    title: 'Penjualan Offline',
    subtitle: 'Lihat, edit, dan hapus transaksi kasir offline.',
    icon: Icons.point_of_sale_rounded,
    accent: Color(0xFFB488E9),
  ),
  _OwnerModuleDefinition(
    key: 'expenses',
    title: 'Pengeluaran',
    subtitle: 'CRUD pengeluaran bahan baku dan operasional.',
    icon: Icons.money_off_csred_rounded,
    accent: Color(0xFF8E79D6),
  ),
  _OwnerModuleDefinition(
    key: 'account-receivables',
    title: 'Account Receivables',
    subtitle: 'CRUD piutang store.',
    icon: Icons.receipt_long_rounded,
    accent: Color(0xFFD980B4),
  ),
  _OwnerModuleDefinition(
    key: 'account-payables',
    title: 'Account Payables',
    subtitle: 'CRUD hutang usaha.',
    icon: Icons.payments_rounded,
    accent: Color(0xFF6F90D8),
  ),
  _OwnerModuleDefinition(
    key: 'online-sales',
    title: 'Penjualan Online',
    subtitle: 'View penjualan online seperti website.',
    icon: Icons.shopping_cart_checkout_rounded,
    accent: Color(0xFF84A7E8),
    type: _OwnerModuleType.readOnly,
  ),
];

const List<_OwnerModuleDefinition> _ownerSettingModules = [
  _OwnerModuleDefinition(
    key: 'sales-targets',
    title: 'Target Penjualan',
    subtitle: 'Update target karyawan dan revenue.',
    icon: Icons.trending_up_rounded,
    accent: Color(0xFF8E79D6),
    type: _OwnerModuleType.salesTargets,
  ),
  _OwnerModuleDefinition(
    key: 'promos',
    title: 'Promo',
    subtitle: 'CRUD promo owner.',
    icon: Icons.local_offer_rounded,
    accent: Color(0xFFD980B4),
  ),
  _OwnerModuleDefinition(
    key: 'users',
    title: 'Users',
    subtitle: 'CRUD user owner dan karyawan.',
    icon: Icons.people_alt_rounded,
    accent: Color(0xFF6F90D8),
  ),
  _OwnerModuleDefinition(
    key: 'customers',
    title: 'Customers',
    subtitle: 'CRUD customer store.',
    icon: Icons.person_rounded,
    accent: Color(0xFF84A7E8),
  ),
  _OwnerModuleDefinition(
    key: 'sops',
    title: 'SOP',
    subtitle: 'CRUD SOP store.',
    icon: Icons.description_rounded,
    accent: Color(0xFFB488E9),
  ),
];

extension _OwnerModuleStateActions on _MarketingRootState {
  Future<void> _openOwnerModulePage({
    required _OwnerModuleDefinition module,
    required Widget employeeAttendancePage,
    required Widget knowledgePage,
  }) async {
    if (module.key == 'offline-sales-history') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _OwnerStandalonePage(
            title: module.title,
            child: _OfflineSalesManagementPage(
              sales: _asMapList(_sales?['sales']),
              products: _asMapList(_sales?['products']),
              promos: _asMapList(_sales?['promos']),
              extraToppings: _asMapList(_sales?['extra_toppings']),
              currency: _currency,
              onUpdateSale: _updateOfflineSaleTransaction,
              onDeleteSale: _deleteOfflineSaleTransaction,
            ),
          ),
        ),
      );
      return;
    }

    if (module.key == 'attendance-history') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _OwnerStandalonePage(
            title: module.title,
            child: employeeAttendancePage,
          ),
        ),
      );
      return;
    }

    if (module.key == 'notifications') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _OwnerModulePage(
            module: module,
            onFetch: () => _fetchOwnerModule(module.key),
            onCreate: (payload) => _storeOwnerModule(module.key, payload),
            onUpdate: (record, payload) =>
                _updateOwnerModule(module.key, record, payload),
            onDelete: (record) => _deleteOwnerModule(module.key, record),
            currency: _currency,
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OwnerModulePage(
          module: module,
          onFetch: () => _fetchOwnerModule(module.key),
          onCreate: (payload) => _storeOwnerModule(module.key, payload),
          onUpdate: (record, payload) =>
              _updateOwnerModule(module.key, record, payload),
          onDelete: (record) => _deleteOwnerModule(module.key, record),
          currency: _currency,
        ),
      ),
    );
  }

  Map<String, dynamic> _mockOwnerModule(String module) {
    switch (module) {
      case 'products':
        return {
          'title': 'Product',
          'description': 'Mock data product owner.',
          'items': _asMapList(_products?['products']).map((item) {
            return {
              'id': item['id_product'],
              'nama_product': item['nama_product'],
              'harga': item['harga'],
              'harga_modal': 0,
              'stock': item['stock'],
              'deskripsi': item['deskripsi'],
            };
          }).toList(),
        };
      case 'product-knowledge':
        return {
          'title': 'Product Knowledge',
          'description': 'Mock product knowledge.',
          'items': _asMapList(_knowledge?['products']).map((item) {
            return {
              'id': item['id_product'],
              'nama_product': item['nama_product'],
              'deskripsi': item['deskripsi'],
              'harga': item['harga'] ?? 0,
              'stock': item['stock'] ?? 0,
            };
          }).toList(),
        };
      case 'notifications':
        return {
          'title': 'Notifications',
          'description': 'Mock notifications.',
          'items': _asMapList(_notifications?['notifications']),
          'read_only': true,
        };
      default:
        return {
          'title': module,
          'description': 'Mock module $module.',
          'items': <Map<String, dynamic>>[],
        };
    }
  }
}

class _OwnerCategoryPage extends StatelessWidget {
  const _OwnerCategoryPage({
    required this.title,
    required this.subtitle,
    required this.modules,
    required this.onOpenModule,
  });

  final String title;
  final String subtitle;
  final List<_OwnerModuleDefinition> modules;
  final ValueChanged<_OwnerModuleDefinition> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _BlockCard(
          title: title,
          subtitle: subtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semua submenu memakai pola popup form seperti website pada saat tambah atau edit data.',
                style: TextStyle(color: kSweetieInk.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 16),
              ...modules.map((module) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => onOpenModule(module),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: module.accent.withValues(alpha: 0.18),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x110F0A05),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: module.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(module.icon, color: module.accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  module.subtitle,
                                  style: TextStyle(
                                    color: kSweetieInk.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: module.accent),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerStandalonePage extends StatelessWidget {
  const _OwnerStandalonePage({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: kSweetieInk,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5EAFB), Color(0xFFFDF8FE), Color(0xFFF4F0FC)],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

class _OwnerColumnConfig {
  const _OwnerColumnConfig(this.key, this.label);

  final String key;
  final String label;
}

class _OwnerFieldConfig {
  const _OwnerFieldConfig({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.optionsKey,
  });

  final String key;
  final String label;
  final String type;
  final bool required;
  final String? optionsKey;
}

class _OwnerModuleUiConfig {
  const _OwnerModuleUiConfig({
    required this.columns,
    required this.fields,
  });

  final List<_OwnerColumnConfig> columns;
  final List<_OwnerFieldConfig> fields;
}

const Map<String, _OwnerModuleUiConfig> _ownerModuleUiConfigs = {
  'products': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('nama_product', 'Nama Product'),
      _OwnerColumnConfig('harga', 'Harga'),
      _OwnerColumnConfig('harga_modal', 'HPP'),
      _OwnerColumnConfig('stock', 'Stock'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'nama_product',
          label: 'Nama Product',
          type: 'text',
          required: true),
      _OwnerFieldConfig(
          key: 'harga', label: 'Harga', type: 'number', required: true),
      _OwnerFieldConfig(
          key: 'stock', label: 'Stock', type: 'number', required: true),
      _OwnerFieldConfig(key: 'deskripsi', label: 'Deskripsi', type: 'textarea'),
    ],
  ),
  'product-knowledge': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('nama_product', 'Nama Product'),
      _OwnerColumnConfig('deskripsi', 'Deskripsi'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'nama_product',
          label: 'Nama Product',
          type: 'text',
          required: true),
      _OwnerFieldConfig(key: 'deskripsi', label: 'Deskripsi', type: 'textarea'),
    ],
  ),
  'raw-materials': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('nama_rm', 'Raw Material'),
      _OwnerColumnConfig('satuan', 'Satuan'),
      _OwnerColumnConfig('harga', 'Harga'),
      _OwnerColumnConfig('quantity', 'Qty / Pack'),
      _OwnerColumnConfig('stock', 'Stock'),
      _OwnerColumnConfig('waste_materials', 'Waste'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'nama_rm',
          label: 'Nama Raw Material',
          type: 'text',
          required: true),
      _OwnerFieldConfig(
          key: 'satuan',
          label: 'Satuan',
          type: 'select',
          required: true,
          optionsKey: 'satuan_options'),
      _OwnerFieldConfig(
          key: 'harga', label: 'Harga', type: 'number', required: true),
      _OwnerFieldConfig(
          key: 'quantity', label: 'Quantity', type: 'number', required: true),
      _OwnerFieldConfig(
          key: 'stock', label: 'Stock', type: 'number', required: true),
      _OwnerFieldConfig(
          key: 'waste_materials', label: 'Waste Materials', type: 'number'),
    ],
  ),
  'extra-toppings': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('name', 'Nama Topping'),
      _OwnerColumnConfig('price', 'Harga'),
      _OwnerColumnConfig('is_active', 'Active'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'name', label: 'Nama Topping', type: 'text', required: true),
      _OwnerFieldConfig(
          key: 'price', label: 'Harga', type: 'number', required: true),
      _OwnerFieldConfig(
          key: 'is_active',
          label: 'Status Aktif',
          type: 'bool',
          required: true),
    ],
  ),
  'expenses': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('category', 'Kategori'),
      _OwnerColumnConfig('title', 'Judul'),
      _OwnerColumnConfig('amount', 'Nominal'),
      _OwnerColumnConfig('expense_date', 'Tanggal'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'category',
          label: 'Kategori',
          type: 'select',
          required: true,
          optionsKey: 'expense_categories'),
      _OwnerFieldConfig(
          key: 'title', label: 'Judul', type: 'text', required: true),
      _OwnerFieldConfig(
          key: 'amount', label: 'Nominal', type: 'number', required: true),
      _OwnerFieldConfig(
          key: 'expense_date', label: 'Tanggal', type: 'date', required: true),
      _OwnerFieldConfig(key: 'notes', label: 'Catatan', type: 'textarea'),
    ],
  ),
  'account-payables': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('account_payable', 'Account Payable'),
      _OwnerColumnConfig('amount', 'Nominal'),
      _OwnerColumnConfig('due_date', 'Jatuh Tempo'),
      _OwnerColumnConfig('notes', 'Catatan'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'account_payable',
          label: 'Account Payable',
          type: 'text',
          required: true),
      _OwnerFieldConfig(
          key: 'amount', label: 'Nominal', type: 'number', required: true),
      _OwnerFieldConfig(
          key: 'due_date', label: 'Jatuh Tempo', type: 'date', required: true),
      _OwnerFieldConfig(key: 'notes', label: 'Catatan', type: 'textarea'),
    ],
  ),
  'promos': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('nama_promo', 'Nama Promo'),
      _OwnerColumnConfig('potongan', 'Potongan'),
      _OwnerColumnConfig('masa_aktif', 'Masa Aktif'),
      _OwnerColumnConfig('minimal_quantity', 'Min Qty'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'nama_promo', label: 'Nama Promo', type: 'text', required: true),
      _OwnerFieldConfig(
          key: 'potongan', label: 'Potongan', type: 'number', required: true),
      _OwnerFieldConfig(
          key: 'masa_aktif', label: 'Masa Aktif', type: 'date', required: true),
      _OwnerFieldConfig(
          key: 'minimal_quantity',
          label: 'Minimal Quantity',
          type: 'number',
          required: true),
      _OwnerFieldConfig(
          key: 'minimal_belanja',
          label: 'Minimal Belanja',
          type: 'number',
          required: true),
    ],
  ),
  'customers': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('nama', 'Nama'),
      _OwnerColumnConfig('no_telp', 'No Telp'),
      _OwnerColumnConfig('tiktok_instagram', 'TikTok/IG'),
      _OwnerColumnConfig('pembelian_terakhir', 'Pembelian Terakhir'),
    ],
    fields: [
      _OwnerFieldConfig(key: 'nama', label: 'Nama', type: 'text'),
      _OwnerFieldConfig(key: 'no_telp', label: 'No Telepon', type: 'text'),
      _OwnerFieldConfig(
          key: 'tiktok_instagram', label: 'TikTok/Instagram', type: 'text'),
      _OwnerFieldConfig(
          key: 'pembelian_terakhir', label: 'Pembelian Terakhir', type: 'date'),
    ],
  ),
  'sops': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('title', 'Judul'),
      _OwnerColumnConfig('detail', 'Detail'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'title', label: 'Judul SOP', type: 'text', required: true),
      _OwnerFieldConfig(
          key: 'detail', label: 'Detail SOP', type: 'textarea', required: true),
    ],
  ),
  'users': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('nama', 'Nama'),
      _OwnerColumnConfig('role_label', 'Role'),
      _OwnerColumnConfig('status', 'Status'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'nama', label: 'Nama', type: 'text', required: true),
      _OwnerFieldConfig(
          key: 'permission_role_id',
          label: 'Role',
          type: 'select',
          required: true,
          optionsKey: 'role_options'),
      _OwnerFieldConfig(
          key: 'status',
          label: 'Status',
          type: 'select',
          required: true,
          optionsKey: 'status_options'),
      _OwnerFieldConfig(key: 'password', label: 'Password', type: 'password'),
    ],
  ),
  'account-receivables': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('receivable_name', 'Piutang'),
      _OwnerColumnConfig('place_name', 'Tempat'),
      _OwnerColumnConfig('total_value', 'Total'),
      _OwnerColumnConfig('status', 'Status'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'receivable_name',
          label: 'Nama Piutang',
          type: 'text',
          required: true),
      _OwnerFieldConfig(
          key: 'place_name',
          label: 'Nama Tempat',
          type: 'text',
          required: true),
      _OwnerFieldConfig(
          key: 'consignment_date',
          label: 'Tanggal Titip',
          type: 'date',
          required: true),
      _OwnerFieldConfig(
          key: 'due_date', label: 'Jatuh Tempo', type: 'date', required: true),
      _OwnerFieldConfig(
          key: 'consigned_value',
          label: 'Nominal Dititipkan',
          type: 'number',
          required: true),
      _OwnerFieldConfig(
          key: 'total_value',
          label: 'Total Nilai',
          type: 'number',
          required: true),
      _OwnerFieldConfig(
          key: 'status',
          label: 'Status',
          type: 'select',
          required: true,
          optionsKey: 'account_receivable_status_options'),
      _OwnerFieldConfig(
          key: 'items_summary', label: 'Ringkasan Item', type: 'textarea'),
      _OwnerFieldConfig(key: 'notes', label: 'Catatan', type: 'textarea'),
    ],
  ),
  'online-sales': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('order_id', 'Order ID'),
      _OwnerColumnConfig('order_status', 'Status'),
      _OwnerColumnConfig('total_amount', 'Total'),
      _OwnerColumnConfig('paid_time', 'Paid Time'),
    ],
    fields: [],
  ),
  'notifications': _OwnerModuleUiConfig(
    columns: [
      _OwnerColumnConfig('title', 'Judul'),
      _OwnerColumnConfig('status', 'Status'),
      _OwnerColumnConfig('target_role', 'Target'),
      _OwnerColumnConfig('published_at', 'Publish'),
    ],
    fields: [
      _OwnerFieldConfig(
          key: 'title', label: 'Judul', type: 'text', required: true),
      _OwnerFieldConfig(
          key: 'body',
          label: 'Isi Notifikasi',
          type: 'textarea',
          required: true),
      _OwnerFieldConfig(
          key: 'target_role',
          label: 'Target Role',
          type: 'select',
          required: true,
          optionsKey: 'notification_target_options'),
      _OwnerFieldConfig(
          key: 'status',
          label: 'Status',
          type: 'select',
          required: true,
          optionsKey: 'notification_status_options'),
      _OwnerFieldConfig(
          key: 'published_at', label: 'Tanggal Publish', type: 'date'),
    ],
  ),
};

class _OwnerModulePage extends StatefulWidget {
  const _OwnerModulePage({
    required this.module,
    required this.onFetch,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    required this.currency,
  });

  final _OwnerModuleDefinition module;
  final Future<Map<String, dynamic>> Function() onFetch;
  final Future<void> Function(Map<String, dynamic> payload) onCreate;
  final Future<void> Function(String record, Map<String, dynamic> payload)
      onUpdate;
  final Future<void> Function(String record) onDelete;
  final NumberFormat currency;

  @override
  State<_OwnerModulePage> createState() => _OwnerModulePageState();
}

class _OwnerModulePageState extends State<_OwnerModulePage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final data = await widget.onFetch();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (error, stackTrace) {
      developer.log(
        'Owner module reload failed',
        name: 'SmoothiesSweetieApp.OwnerModule',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      _showFailureMessage('Gagal memuat data module.', error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _describeError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        final errors = data['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }
        }
      }

      return error.message ?? 'Terjadi kesalahan pada koneksi.';
    }

    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Terjadi kesalahan tak terduga.';
    }

    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  void _showFailureMessage(String fallback, Object error) {
    if (!mounted) return;

    final message = _describeError(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.isNotEmpty ? message : fallback),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data ?? const <String, dynamic>{};
    final items = _asMapList(data['items']);
    final readOnly = (data['read_only'] as bool?) ?? false;

    return _OwnerStandalonePage(
      title: widget.module.title,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _BlockCard(
                  title: data['title']?.toString() ?? widget.module.title,
                  subtitle:
                      data['description']?.toString() ?? widget.module.subtitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!readOnly &&
                          widget.module.type == _OwnerModuleType.generic) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _openCreateFlow,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Tambah'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildModuleBody(items, data),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModuleBody(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> data,
  ) {
    if (widget.module.type == _OwnerModuleType.salesTargets) {
      return _buildSalesTargets(data);
    }
    if (widget.module.type == _OwnerModuleType.hpp) {
      return _buildHpp(data);
    }
    return _buildGenericTable(items, data);
  }

  _OwnerModuleUiConfig _configFor(String key) =>
      _ownerModuleUiConfigs[key] ??
      const _OwnerModuleUiConfig(columns: [], fields: []);

  Widget _buildGenericTable(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> data,
  ) {
    final config = _configFor(widget.module.key);
    final readOnly = (data['read_only'] as bool?) ?? false;

    if (items.isEmpty) {
      return const Text('Belum ada data.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          ...config.columns
              .map((column) => DataColumn(label: Text(column.label))),
          const DataColumn(label: Text('Aksi')),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              ...config.columns.map((column) {
                return DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(_formatModuleCell(item, column)),
                  ),
                );
              }),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showItemDetail(item, data),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    if (!readOnly && config.fields.isNotEmpty)
                      IconButton(
                        onPressed: _saving ? null : () => _openEditFlow(item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    if (!readOnly)
                      IconButton(
                        onPressed:
                            _saving ? null : () => _deleteGenericItem(item),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    if (readOnly)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('-'),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatCell(dynamic value) {
    if (value == null) {
      return '-';
    }
    if (value is bool) {
      return value ? 'Aktif' : 'Nonaktif';
    }
    if (value is num) {
      return value % 1 == 0 ? value.toInt().toString() : value.toString();
    }
    if (value is List) {
      return value
          .map((item) => item is Map<String, dynamic>
              ? item.values.join(' - ')
              : item.toString())
          .join(', ');
    }
    final text = value.toString();
    return text.isEmpty ? '-' : text;
  }

  String _formatModuleCell(
    Map<String, dynamic> item,
    _OwnerColumnConfig column,
  ) {
    if (widget.module.key == 'raw-materials' &&
        column.key == 'waste_materials' &&
        item[column.key] != null) {
      final text = _formatCell(item[column.key]);
      if (text == '-' || text.startsWith('-')) {
        return text;
      }

      return '-$text';
    }

    return _formatCell(item[column.key]);
  }

  Future<void> _openCreateFlow() async {
    if (widget.module.key == 'products') {
      await _openProductForm();
      return;
    }
    if (widget.module.key == 'product-knowledge') {
      await _openProductKnowledgeForm();
      return;
    }
    await _openGenericForm(config: _configFor(widget.module.key));
  }

  Future<void> _openEditFlow(Map<String, dynamic> item) async {
    if (widget.module.key == 'products') {
      await _openProductForm(initialItem: item);
      return;
    }
    if (widget.module.key == 'product-knowledge') {
      await _openProductKnowledgeForm(initialItem: item);
      return;
    }
    await _openGenericForm(
      config: _configFor(widget.module.key),
      initialItem: item,
    );
  }

  Future<void> _showItemDetail(
    Map<String, dynamic> item,
    Map<String, dynamic> data,
  ) async {
    final config = _configFor(widget.module.key);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Detail ${widget.module.title}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.module.key == 'products' &&
                    item['image_url']?.toString().isNotEmpty == true) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: CachedNetworkImage(
                        imageUrl: item['image_url'].toString(),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.module.key == 'product-knowledge' &&
                    item['image_url']?.toString().isNotEmpty == true) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: CachedNetworkImage(
                        imageUrl: item['image_url'].toString(),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ...config.columns.map((column) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InfoRow(
                      label: column.label,
                      value: _formatModuleCell(item, column),
                    ),
                  );
                }),
                if (widget.module.key == 'products') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Variants',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._asMapList(item['variants']).map((variant) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF6FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              label: 'Nama',
                              value: variant['name']?.toString() ?? '-',
                            ),
                            _InfoRow(
                              label: 'Harga',
                              value: widget.currency.format(
                                  (variant['price'] as num?)?.toDouble() ?? 0),
                            ),
                            _InfoRow(
                              label: 'Total Satuan',
                              value:
                                  '${(variant['total_satuan_ml'] as num?)?.toDouble() ?? 0}',
                            ),
                            _InfoRow(
                              label: 'Default',
                              value: variant['is_default'] == true
                                  ? 'Ya'
                                  : 'Tidak',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                if (widget.module.type == _OwnerModuleType.hpp) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Komposisi Raw Material',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._asMapList(item['details']).map((detail) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF6FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              label: 'Raw Material',
                              value: detail['nama_rm']?.toString() ?? '-',
                            ),
                            _InfoRow(
                              label: 'Presentase',
                              value: '${detail['presentase'] ?? 0}',
                            ),
                            _InfoRow(
                              label: 'Harga Final',
                              value: widget.currency.format(
                                  (detail['harga_final'] as num?)?.toDouble() ??
                                      0),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGenericItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Apakah anda ingin hapus data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Iya'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await widget.onDelete('${item['id']}');
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      await _showSuccessDialog('${widget.module.title} berhasil dihapus.');
    } catch (error, stackTrace) {
      developer.log(
        'Owner module delete failed',
        name: 'SmoothiesSweetieApp.OwnerModule',
        error: error,
        stackTrace: stackTrace,
      );
      _showFailureMessage('Gagal menghapus data.', error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openGenericForm({
    required _OwnerModuleUiConfig config,
    Map<String, dynamic>? initialItem,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _OwnerGenericFormDialog(
        title: initialItem == null
            ? 'Tambah ${widget.module.title}'
            : 'Edit ${widget.module.title}',
        fields: config.fields,
        initialItem: initialItem,
        extraOptions: _dialogOptions(),
      ),
    );

    if (result == null) return;

    setState(() => _saving = true);
    try {
      if (initialItem == null) {
        await widget.onCreate(result);
      } else {
        await widget.onUpdate('${initialItem['id']}', result);
      }
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      await _showSuccessDialog(
        initialItem == null
            ? '${widget.module.title} berhasil ditambahkan.'
            : '${widget.module.title} berhasil diperbarui.',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Owner generic form save failed',
        name: 'SmoothiesSweetieApp.OwnerModule',
        error: error,
        stackTrace: stackTrace,
      );
      _showFailureMessage('Gagal menyimpan data.', error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openProductForm({Map<String, dynamic>? initialItem}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _OwnerProductFormDialog(
        title: initialItem == null ? 'Tambah Product' : 'Edit Product',
        initialItem: initialItem,
        currency: widget.currency,
      ),
    );

    if (result == null) return;

    setState(() => _saving = true);
    try {
      if (initialItem == null) {
        await widget.onCreate(result);
      } else {
        await widget.onUpdate('${initialItem['id']}', result);
      }
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      await _showSuccessDialog(
        initialItem == null
            ? 'Product berhasil ditambahkan.'
            : 'Product berhasil diperbarui.',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Owner product save failed',
        name: 'SmoothiesSweetieApp.OwnerModule',
        error: error,
        stackTrace: stackTrace,
      );
      _showFailureMessage('Gagal menyimpan product.', error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openProductKnowledgeForm({
    Map<String, dynamic>? initialItem,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _OwnerProductKnowledgeFormDialog(
        title: initialItem == null
            ? 'Tambah Product Knowledge'
            : 'Edit Product Knowledge',
        initialItem: initialItem,
      ),
    );

    if (result == null) return;

    setState(() => _saving = true);
    try {
      if (initialItem == null) {
        await widget.onCreate(result);
      } else {
        await widget.onUpdate('${initialItem['id']}', result);
      }
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      await _showSuccessDialog(
        initialItem == null
            ? 'Product knowledge berhasil ditambahkan.'
            : 'Product knowledge berhasil diperbarui.',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Owner product knowledge save failed',
        name: 'SmoothiesSweetieApp.OwnerModule',
        error: error,
        stackTrace: stackTrace,
      );
      _showFailureMessage('Gagal menyimpan product knowledge.', error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showSuccessDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kSweetieLavender,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(kSweetieLogoAsset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            const Text(
              'Berhasil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _dialogOptions() {
    final data = _data ?? const <String, dynamic>{};

    return {
      'satuan_options': const [
        {'value': 'pcs', 'label': 'pcs'},
        {'value': 'ML', 'label': 'ML'},
        {'value': 'gram', 'label': 'gram'},
        {'value': 'kg', 'label': 'kg'},
      ],
      'expense_categories': const [
        {'value': 'bahan_baku', 'label': 'Bahan Baku'},
        {'value': 'operasional', 'label': 'Operasional'},
      ],
      'role_options': _asMapList(data['role_options']),
      'status_options': ((data['status_options'] as List?) ?? const [])
          .map((item) => {'value': '$item', 'label': '$item'})
          .toList(),
      'notification_target_options': const [
        {'value': 'all', 'label': 'Semua Role'},
        {'value': 'owner', 'label': 'Owner'},
        {'value': 'karyawan', 'label': 'Karyawan'},
        {'value': 'marketing', 'label': 'Marketing'},
        {'value': 'sales_field_executive', 'label': 'Sales Field Executive'},
      ],
      'notification_status_options': const [
        {'value': 'draft', 'label': 'Draft'},
        {'value': 'published', 'label': 'Published'},
      ],
      'account_receivable_status_options': const [
        {'value': 'dititipkan', 'label': 'Dititipkan'},
        {'value': 'dibayar_sebagian', 'label': 'Dibayar Sebagian'},
        {'value': 'lunas', 'label': 'Lunas'},
        {'value': 'jatuh_tempo', 'label': 'Jatuh Tempo'},
      ],
    };
  }

  Widget _buildSalesTargets(Map<String, dynamic> data) {
    final items = _asMapList(data['items']);
    return Column(
      children: items.map((item) {
        final isRevenue = item['type'] == 'revenue';
        final hasExistingTarget = item['exists'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['label']?.toString() ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => _deleteSalesTarget('${item['role']}'),
                    child: const Text('Delete'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _saving
                        ? null
                        : () => _openSalesTargetForm(item, isRevenue),
                    child: Text(hasExistingTarget ? 'Edit' : 'Tambah'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Basis Target',
                value: isRevenue ? 'Revenue' : 'Botol Terjual',
              ),
              const SizedBox(height: 6),
              if (isRevenue) ...[
                _InfoRow(
                    label: 'Monthly Revenue',
                    value: _formatCell(item['monthly_target_revenue'])),
                _InfoRow(
                    label: 'Minimum KPI',
                    value: _formatCell(item['minimum_kpi_value'])),
                _InfoRow(
                    label: 'Maks. Terlambat',
                    value: _formatCell(item['maximum_late_days'])),
                _InfoRow(
                    label: 'Min. Attendance %',
                    value: _formatCell(item['minimum_attendance_percentage'])),
                _InfoRow(
                    label: 'Bonus', value: _formatCell(item['revenue_bonus'])),
              ] else ...[
                _InfoRow(
                    label: 'Target Harian',
                    value: _formatCell(item['daily_target_qty'])),
                _InfoRow(
                    label: 'Bonus Harian',
                    value: _formatCell(item['daily_bonus'])),
                _InfoRow(
                    label: 'Target Mingguan',
                    value: _formatCell(item['weekly_target_qty'])),
                _InfoRow(
                    label: 'Bonus Mingguan',
                    value: _formatCell(item['weekly_bonus'])),
                _InfoRow(
                    label: 'Target Bulanan',
                    value: _formatCell(item['monthly_target_qty'])),
                _InfoRow(
                    label: 'Bonus Bulanan',
                    value: _formatCell(item['monthly_bonus'])),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _deleteSalesTarget(String role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Apakah anda ingin hapus data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Iya'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await widget.onDelete(role);
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      await _showSuccessDialog('Target penjualan berhasil dihapus.');
    } catch (error, stackTrace) {
      developer.log(
        'Owner sales target delete failed',
        name: 'SmoothiesSweetieApp.OwnerModule',
        error: error,
        stackTrace: stackTrace,
      );
      _showFailureMessage('Gagal menghapus target penjualan.', error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openSalesTargetForm(
    Map<String, dynamic> item,
    bool isRevenue,
  ) async {
    final fields = isRevenue
        ? const [
            _OwnerFieldConfig(
                key: 'monthly_target_revenue',
                label: 'Monthly Revenue',
                type: 'number',
                required: true),
            _OwnerFieldConfig(
                key: 'minimum_kpi_value',
                label: 'Minimum KPI',
                type: 'number',
                required: true),
            _OwnerFieldConfig(
                key: 'maximum_late_days',
                label: 'Maks. Terlambat',
                type: 'number',
                required: true),
            _OwnerFieldConfig(
                key: 'minimum_attendance_percentage',
                label: 'Min. Attendance %',
                type: 'number',
                required: true),
            _OwnerFieldConfig(
                key: 'revenue_bonus',
                label: 'Bonus Revenue',
                type: 'number',
                required: true),
          ]
        : const [
            _OwnerFieldConfig(
                key: 'daily_target_qty',
                label: 'Target Harian',
                type: 'number',
                required: true),
            _OwnerFieldConfig(
                key: 'daily_bonus',
                label: 'Bonus Harian',
                type: 'number',
                required: true),
            _OwnerFieldConfig(
                key: 'weekly_target_qty',
                label: 'Target Mingguan',
                type: 'number',
                required: true),
            _OwnerFieldConfig(
                key: 'weekly_bonus',
                label: 'Bonus Mingguan',
                type: 'number',
                required: true),
            _OwnerFieldConfig(
                key: 'monthly_target_qty',
                label: 'Target Bulanan',
                type: 'number',
                required: true),
            _OwnerFieldConfig(
                key: 'monthly_bonus',
                label: 'Bonus Bulanan',
                type: 'number',
                required: true),
          ];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _OwnerGenericFormDialog(
        title: 'Edit ${item['label']}',
        fields: fields,
        initialItem: item,
        extraOptions: const {},
      ),
    );

    if (result == null) return;

    setState(() => _saving = true);
    try {
      await widget.onUpdate('${item['role']}', result);
      if (!mounted) return;
      await _reload();
    } catch (error, stackTrace) {
      developer.log(
        'Owner sales target save failed',
        name: 'SmoothiesSweetieApp.OwnerModule',
        error: error,
        stackTrace: stackTrace,
      );
      _showFailureMessage('Gagal menyimpan target penjualan.', error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _buildHpp(Map<String, dynamic> data) {
    final items = _asMapList(data['items']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saving ? null : () => _openHppForm(data),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah HPP'),
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Text('Belum ada perhitungan HPP.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Total HPP')),
                DataColumn(label: Text('Updated')),
                DataColumn(label: Text('Aksi')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item['nama_product']?.toString() ?? '-')),
                    DataCell(
                        Text(widget.currency.format(item['total_hpp'] ?? 0))),
                    DataCell(Text(item['updated_at']?.toString() ?? '-')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showItemDetail(item, data),
                            icon: const Icon(Icons.visibility_outlined),
                          ),
                          IconButton(
                            onPressed: _saving
                                ? null
                                : () => _openHppForm(data, initialItem: item),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed:
                                _saving ? null : () => _deleteGenericItem(item),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _openHppForm(
    Map<String, dynamic> data, {
    Map<String, dynamic>? initialItem,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _HppFormDialog(
        title: initialItem == null ? 'Tambah HPP' : 'Edit HPP',
        products: _asMapList(data['products']),
        rawMaterials: _asMapList(data['raw_materials']),
        initialItem: initialItem,
      ),
    );

    if (result == null) return;

    setState(() => _saving = true);
    try {
      if (initialItem == null) {
        await widget.onCreate(result);
      } else {
        await widget.onUpdate('${initialItem['id']}', result);
      }
      if (!mounted) return;
      await _reload();
    } catch (error, stackTrace) {
      developer.log(
        'Owner HPP save failed',
        name: 'SmoothiesSweetieApp.OwnerModule',
        error: error,
        stackTrace: stackTrace,
      );
      _showFailureMessage('Gagal menyimpan HPP.', error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _OwnerGenericFormDialog extends StatefulWidget {
  const _OwnerGenericFormDialog({
    required this.title,
    required this.fields,
    required this.initialItem,
    required this.extraOptions,
  });

  final String title;
  final List<_OwnerFieldConfig> fields;
  final Map<String, dynamic>? initialItem;
  final Map<String, List<Map<String, dynamic>>> extraOptions;

  @override
  State<_OwnerGenericFormDialog> createState() =>
      _OwnerGenericFormDialogState();
}

class _OwnerGenericFormDialogState extends State<_OwnerGenericFormDialog> {
  late final Map<String, TextEditingController> _controllers;
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields)
        field.key: TextEditingController(
          text: widget.initialItem?[field.key]?.toString() ?? '',
        ),
    };
    for (final field in widget.fields) {
      if (field.type == 'bool') {
        _values[field.key] = widget.initialItem?[field.key] == true;
      } else {
        _values[field.key] = widget.initialItem?[field.key];
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.fields.map(_buildField).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_collectPayload()),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildField(_OwnerFieldConfig field) {
    final options = field.optionsKey == null
        ? const <Map<String, dynamic>>[]
        : widget.extraOptions[field.optionsKey] ??
            const <Map<String, dynamic>>[];

    if (field.type == 'select') {
      final initialValue = _values[field.key]?.toString();
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          initialValue: initialValue != null && initialValue.isNotEmpty
              ? initialValue
              : null,
          decoration: InputDecoration(labelText: field.label),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: '${option['value']}',
              child: Text(option['label']?.toString() ?? '${option['value']}'),
            );
          }).toList(),
          onChanged: (value) => setState(() => _values[field.key] = value),
        ),
      );
    }

    if (field.type == 'bool') {
      return SwitchListTile(
        value: _values[field.key] == true,
        onChanged: (value) => setState(() => _values[field.key] = value),
        title: Text(field.label),
        contentPadding: EdgeInsets.zero,
      );
    }

    if (field.type == 'date') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: _controllers[field.key],
          readOnly: true,
          onTap: () async {
            final initialDate = DateTime.tryParse(
                  _controllers[field.key]?.text.trim() ?? '',
                ) ??
                DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            setState(() {
              _controllers[field.key]?.text =
                  '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            });
          },
          decoration: InputDecoration(
            labelText: field.required ? '${field.label} *' : field.label,
            hintText: 'YYYY-MM-DD',
            suffixIcon: const Icon(Icons.calendar_month_rounded),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: _controllers[field.key],
        obscureText: field.type == 'password',
        keyboardType: field.type == 'number'
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        maxLines: field.type == 'textarea' ? 4 : 1,
        decoration: InputDecoration(
          labelText: field.required ? '${field.label} *' : field.label,
        ),
      ),
    );
  }

  Map<String, dynamic> _collectPayload() {
    final payload = <String, dynamic>{};

    for (final field in widget.fields) {
      if (field.type == 'bool') {
        payload[field.key] = _values[field.key] == true;
        continue;
      }

      if (field.type == 'select') {
        final selected = _values[field.key]?.toString();
        if (selected != null && selected.isNotEmpty) {
          payload[field.key] = int.tryParse(selected) ?? selected;
        }
        continue;
      }

      final raw = _controllers[field.key]?.text.trim() ?? '';
      if (raw.isEmpty) {
        if (field.required && field.type == 'number') {
          payload[field.key] = 0;
        }
        continue;
      }

      if (field.type == 'number') {
        payload[field.key] = num.tryParse(raw) ?? 0;
      } else {
        payload[field.key] = raw;
      }
    }

    return payload;
  }
}

class _OwnerProductFormDialog extends StatefulWidget {
  const _OwnerProductFormDialog({
    required this.title,
    required this.initialItem,
    required this.currency,
  });

  final String title;
  final Map<String, dynamic>? initialItem;
  final NumberFormat currency;

  @override
  State<_OwnerProductFormDialog> createState() =>
      _OwnerProductFormDialogState();
}

class _OwnerProductFormDialogState extends State<_OwnerProductFormDialog> {
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;
  late List<Map<String, dynamic>> _variants;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialItem?['nama_product']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: '${widget.initialItem?['harga'] ?? 0}',
    );
    _stockController = TextEditingController(
      text: '${widget.initialItem?['stock'] ?? 0}',
    );
    _descriptionController = TextEditingController(
      text: widget.initialItem?['deskripsi']?.toString() ?? '',
    );
    _variants = _asMapList(widget.initialItem?['variants'])
        .map((item) => <String, dynamic>{
              'id': item['id'],
              'name': item['name']?.toString() ?? '',
              'price': '${item['price'] ?? 0}',
              'total_satuan_ml': '${item['total_satuan_ml'] ?? 0}',
              'is_default': item['is_default'] == true,
            })
        .toList();
    if (_variants.isEmpty) {
      _variants = [
        {
          'name': 'Reguler',
          'price': '${widget.initialItem?['harga'] ?? 0}',
          'total_satuan_ml': '0',
          'is_default': true,
        },
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (picked == null) return;
    setState(() => _imageFile = picked);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.initialItem?['image_url']?.toString();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Product *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Harga *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Foto Product',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label:
                        Text(_imageFile == null ? 'Pilih Foto' : 'Ganti Foto'),
                  ),
                ],
              ),
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_imageFile!.path),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                )
              else if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Variants',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _variants.add({
                        'name': '',
                        'price': _priceController.text.trim().isEmpty
                            ? '0'
                            : _priceController.text.trim(),
                        'total_satuan_ml': '0',
                        'is_default': _variants.isEmpty,
                      });
                    }),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Variant'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._variants.asMap().entries.map((entry) {
                final index = entry.key;
                final variant = entry.value;
                return _ProductVariantEditorCard(
                  index: index,
                  variant: variant,
                  currency: widget.currency,
                  canDelete: _variants.length > 1,
                  onChanged: (next) => setState(() => _variants[index] = next),
                  onDelete: () => setState(() => _variants.removeAt(index)),
                  onMakeDefault: () => setState(() {
                    for (var i = 0; i < _variants.length; i += 1) {
                      _variants[i]['is_default'] = i == index;
                    }
                  }),
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
          onPressed: () => Navigator.of(context).pop(_collectPayload()),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Map<String, dynamic> _collectPayload() {
    final variants = _variants
        .map((variant) => {
              if (variant['id'] != null) 'id': variant['id'],
              'name': variant['name']?.toString().trim() ?? '',
              'price': num.tryParse(variant['price']?.toString() ?? '') ?? 0,
              'total_satuan_ml':
                  num.tryParse(variant['total_satuan_ml']?.toString() ?? '') ??
                      0,
              'is_default': variant['is_default'] == true,
            })
        .where((variant) => (variant['name']?.toString().isNotEmpty ?? false))
        .toList();

    if (!variants.any((variant) => variant['is_default'] == true) &&
        variants.isNotEmpty) {
      variants.first['is_default'] = true;
    }

    return {
      'nama_product': _nameController.text.trim(),
      'harga': num.tryParse(_priceController.text.trim()) ?? 0,
      'stock': int.tryParse(_stockController.text.trim()) ?? 0,
      'deskripsi': _descriptionController.text.trim(),
      'variants': variants,
      if (_imageFile != null) 'gambar': _imageFile,
    };
  }
}

class _OwnerProductKnowledgeFormDialog extends StatefulWidget {
  const _OwnerProductKnowledgeFormDialog({
    required this.title,
    required this.initialItem,
  });

  final String title;
  final Map<String, dynamic>? initialItem;

  @override
  State<_OwnerProductKnowledgeFormDialog> createState() =>
      _OwnerProductKnowledgeFormDialogState();
}

class _OwnerProductKnowledgeFormDialogState
    extends State<_OwnerProductKnowledgeFormDialog> {
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialItem?['nama_product']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialItem?['deskripsi']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (picked == null) return;
    setState(() => _imageFile = picked);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.initialItem?['image_url']?.toString();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Product *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Foto Product Knowledge',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label:
                        Text(_imageFile == null ? 'Pilih Foto' : 'Ganti Foto'),
                  ),
                ],
              ),
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_imageFile!.path),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                )
              else if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
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
          onPressed: () => Navigator.of(context).pop(_collectPayload()),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Map<String, dynamic> _collectPayload() {
    return {
      'nama_product': _nameController.text.trim(),
      'deskripsi': _descriptionController.text.trim(),
      if (_imageFile != null) 'gambar': _imageFile,
    };
  }
}

class _ProductVariantEditorCard extends StatelessWidget {
  const _ProductVariantEditorCard({
    required this.index,
    required this.variant,
    required this.currency,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
    required this.onMakeDefault,
  });

  final int index;
  final Map<String, dynamic> variant;
  final NumberFormat currency;
  final bool canDelete;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onMakeDefault;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kSweetieLavender),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Variant ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (variant['is_default'] == true)
                  const Chip(label: Text('Default')),
                IconButton(
                  onPressed: canDelete ? onDelete : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            TextFormField(
              initialValue: variant['name']?.toString() ?? '',
              onChanged: (value) => onChanged({...variant, 'name': value}),
              decoration: const InputDecoration(labelText: 'Nama Variant'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: variant['price']?.toString() ?? '0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => onChanged({...variant, 'price': value}),
              decoration: const InputDecoration(labelText: 'Harga'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: variant['total_satuan_ml']?.toString() ?? '0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) =>
                  onChanged({...variant, 'total_satuan_ml': value}),
              decoration: const InputDecoration(labelText: 'Total Satuan'),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onMakeDefault,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Jadikan Default'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HppFormDialog extends StatefulWidget {
  const _HppFormDialog({
    required this.title,
    required this.products,
    required this.rawMaterials,
    required this.initialItem,
  });

  final String title;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> rawMaterials;
  final Map<String, dynamic>? initialItem;

  @override
  State<_HppFormDialog> createState() => _HppFormDialogState();
}

class _HppFormDialogState extends State<_HppFormDialog> {
  String? _selectedProductId;
  late List<Map<String, dynamic>> _rows;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialItem?['id_product']?.toString();
    _rows = _asMapList(widget.initialItem?['details'])
        .map((item) => {
              'id_rm': '${item['id_rm'] ?? ''}',
              'presentase': '${item['presentase'] ?? ''}',
            })
        .toList();
    if (_rows.isEmpty) {
      _rows = [
        {'id_rm': '', 'presentase': ''},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedProductId,
                decoration: const InputDecoration(labelText: 'Product'),
                items: widget.products.map((product) {
                  return DropdownMenuItem<String>(
                    value: '${product['id_product']}',
                    child: Text(product['nama_product']?.toString() ?? '-'),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedProductId = value),
              ),
              const SizedBox(height: 14),
              ..._rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              row['id_rm']?.toString().isNotEmpty == true
                                  ? row['id_rm']?.toString()
                                  : null,
                          decoration:
                              const InputDecoration(labelText: 'Raw Material'),
                          items: widget.rawMaterials.map((material) {
                            return DropdownMenuItem<String>(
                              value: '${material['id_rm']}',
                              child:
                                  Text(material['nama_rm']?.toString() ?? '-'),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() {
                            _rows[index]['id_rm'] = value ?? '';
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: row['presentase']?.toString() ?? '',
                          decoration:
                              const InputDecoration(labelText: 'Presentase'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) =>
                              _rows[index]['presentase'] = value,
                        ),
                      ),
                      IconButton(
                        onPressed: _rows.length == 1
                            ? null
                            : () => setState(() => _rows.removeAt(index)),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _rows.add({'id_rm': '', 'presentase': ''});
                  }),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Raw Material'),
                ),
              ),
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
          onPressed: () => Navigator.of(context).pop({
            'id_product': int.tryParse(_selectedProductId ?? '') ?? 0,
            'items': _rows
                .where((row) =>
                    (row['id_rm']?.toString().isNotEmpty ?? false) &&
                    (row['presentase']?.toString().isNotEmpty ?? false))
                .map((row) => {
                      'id_rm': int.tryParse(row['id_rm']!.toString()) ?? 0,
                      'presentase':
                          num.tryParse(row['presentase']!.toString()) ?? 0,
                    })
                .toList(),
          }),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
