import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../state/session_controller.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      _DashboardTab(),
      _AttendanceTab(),
      _ProductsTab(),
      _SalesTab(),
      _KnowledgeTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Consumer<SessionController>(
          builder: (context, session, _) => Text(session.user?.nama ?? 'Sweetie'),
        ),
        actions: [
          IconButton(
            onPressed: () => context.read<SessionController>().refreshAll(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => context.read<SessionController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Absensi'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Barang'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sales'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Knowledge'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        final data = session.dashboard;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        final kpi = data['sweetie_kpi'] as Map<String, dynamic>? ?? {};
        final target = data['target_summary'] as Map<String, dynamic>? ?? {};
        final sales = (data['recent_sales'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

        return RefreshIndicator(
          onRefresh: session.refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InfoCard(title: 'On Hand', body: '${stats['onhand_count'] ?? 0}'),
                  _InfoCard(title: 'Pending Return', body: '${stats['pending_return_count'] ?? 0}'),
                  _InfoCard(title: 'Pending Take', body: '${stats['pending_take_count'] ?? 0}'),
                  _InfoCard(title: 'Sales Approved', body: '${stats['approved_sales_count'] ?? 0}'),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'KPI Sweetie',
                children: [
                  Text('Sales score: ${kpi['sales_score'] ?? 0}'),
                  Text('Attendance score: ${kpi['attendance_score'] ?? 0}'),
                  Text('Hours score: ${kpi['hours_score'] ?? 0}'),
                  Text('Total score: ${kpi['total_score'] ?? 0}'),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Target Bulan Ini',
                children: [
                  Text('Daily target: ${target['daily']?['target_qty'] ?? 0} pcs'),
                  Text('Weekly target: ${target['weekly']?['target_qty'] ?? 0} pcs'),
                  Text('Monthly target: ${target['monthly']?['target_qty'] ?? 0} pcs'),
                  Text('Bonus total: ${target['bonus_total'] ?? 0}'),
                  if (target['reminder'] != null) Text(target['reminder'].toString()),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Recent Sales',
                children: sales.isEmpty
                    ? const [Text('Belum ada transaksi.')]
                    : sales
                        .map((item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['nama_product']?.toString() ?? '-'),
                              subtitle: Text(item['transaction_code']?.toString() ?? '-'),
                              trailing: Text('${item['quantity'] ?? 0} pcs'),
                            ))
                        .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceTab extends StatefulWidget {
  const _AttendanceTab();

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  final _notesController = TextEditingController();
  String _status = 'hadir';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        final data = session.attendance;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final today = data['today_attendance'] as Map<String, dynamic>? ?? {};
        final recent = (data['recent_attendances'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

        return RefreshIndicator(
          onRefresh: session.refreshAttendance,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Absensi Hari Ini',
                children: [
                  Text('Status: ${today['status'] ?? '-'}'),
                  Text('Check in: ${today['check_in'] ?? '-'}'),
                  Text('Check out: ${today['check_out'] ?? '-'}'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                      DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                      DropdownMenuItem(value: 'izin', child: Text('Izin')),
                      DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                    ],
                    onChanged: (value) => setState(() => _status = value ?? 'hadir'),
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Catatan'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _submitAttendance(context, true),
                          child: const Text('Check In'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _submitAttendance(context, false),
                          child: const Text('Check Out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Riwayat Absensi',
                children: recent.isEmpty
                    ? const [Text('Belum ada riwayat absensi.')]
                    : recent
                        .map((item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['attendance_date']?.toString() ?? '-'),
                              subtitle: Text('${item['check_in'] ?? '-'} - ${item['check_out'] ?? '-'}'),
                              trailing: Text(item['status']?.toString() ?? '-'),
                            ))
                        .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitAttendance(BuildContext context, bool isCheckIn) async {
    final session = context.read<SessionController>();
    try {
      if (isCheckIn) {
        await session.checkIn(
          status: _status,
          latitude: -6.2,
          longitude: 106.8,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else {
        await session.checkOut(
          status: _status,
          latitude: -6.2,
          longitude: 106.8,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isCheckIn ? 'Check in berhasil.' : 'Check out berhasil.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.readError(error))),
      );
    }
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  int? _productId;
  int? _onhandId;
  final _takeQty = TextEditingController(text: '1');
  final _returnQty = TextEditingController(text: '1');

  @override
  void dispose() {
    _takeQty.dispose();
    _returnQty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        final data = session.products;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = (data['products'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final onhands = (data['onhands'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final returnItems = (data['today_return_items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _productId ??= products.isNotEmpty ? products.first['id_product'] as int? : null;
        _onhandId ??= returnItems.isNotEmpty ? returnItems.first['id_product_onhand'] as int? : null;

        return RefreshIndicator(
          onRefresh: session.refreshProducts,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Ambil Barang',
                children: [
                  DropdownButtonFormField<int>(
                    value: _productId,
                    items: products
                        .map((item) => DropdownMenuItem<int>(
                              value: item['id_product'] as int,
                              child: Text(item['option_label']?.toString() ?? '-'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _productId = value),
                    decoration: const InputDecoration(labelText: 'Product'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _takeQty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _productId == null ? null : () => _submitTake(context),
                    child: const Text('Kirim Request'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Return Barang',
                children: [
                  DropdownButtonFormField<int>(
                    value: _onhandId,
                    items: returnItems
                        .map((item) => DropdownMenuItem<int>(
                              value: item['id_product_onhand'] as int,
                              child: Text('${item['nama_product']} | sisa ${item['remaining_quantity']}'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _onhandId = value),
                    decoration: const InputDecoration(labelText: 'On Hand'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _returnQty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity Return'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _onhandId == null ? null : () => _submitReturn(context),
                    child: const Text('Kirim Return'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Data On Hand',
                children: onhands.isEmpty
                    ? const [Text('Belum ada on hand.')]
                    : onhands
                        .map((item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['nama_product']?.toString() ?? '-'),
                              subtitle: Text('${item['take_status_label']} • ${item['status_label']}'),
                              trailing: Text('${item['remaining_quantity'] ?? 0}'),
                            ))
                        .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitTake(BuildContext context) async {
    final session = context.read<SessionController>();
    try {
      await session.takeProduct(
        productId: _productId!,
        quantity: int.tryParse(_takeQty.text) ?? 1,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request pengambilan dikirim.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.readError(error))),
      );
    }
  }

  Future<void> _submitReturn(BuildContext context) async {
    final session = context.read<SessionController>();
    try {
      await session.requestReturn(
        onhandId: _onhandId!,
        quantity: int.tryParse(_returnQty.text) ?? 1,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request return dikirim.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.readError(error))),
      );
    }
  }
}

class _SalesTab extends StatefulWidget {
  const _SalesTab();

  @override
  State<_SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<_SalesTab> {
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _customerSocial = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  int? _productId;
  int? _promoId;
  File? _proofFile;

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _customerSocial.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        final data = session.sales;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = (data['products'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final promos = (data['promos'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final sales = (data['sales'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _productId ??= products.isNotEmpty ? products.first['id_product'] as int? : null;

        return RefreshIndicator(
          onRefresh: session.refreshSales,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Input Sales Offline',
                children: [
                  TextField(controller: _customerName, decoration: const InputDecoration(labelText: 'Nama Customer')),
                  const SizedBox(height: 12),
                  TextField(controller: _customerPhone, decoration: const InputDecoration(labelText: 'No. Telp')),
                  const SizedBox(height: 12),
                  TextField(controller: _customerSocial, decoration: const InputDecoration(labelText: 'TikTok / Instagram')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _productId,
                    items: products
                        .map((item) => DropdownMenuItem<int>(
                              value: item['id_product'] as int,
                              child: Text(item['option_label']?.toString() ?? '-'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _productId = value),
                    decoration: const InputDecoration(labelText: 'Product'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _promoId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Tanpa Promo')),
                      ...promos.map((item) => DropdownMenuItem<int?>(
                            value: item['id'] as int,
                            child: Text(item['option_label']?.toString() ?? '-'),
                          )),
                    ],
                    onChanged: (value) => setState(() => _promoId = value),
                    decoration: const InputDecoration(labelText: 'Promo'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickProof,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(_proofFile == null ? 'Pilih Bukti' : 'Ganti Bukti'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _proofFile == null ? 'Belum ada file.' : _proofFile!.path.split(Platform.pathSeparator).last,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _productId == null || _proofFile == null ? null : () => _submitSale(context),
                    child: const Text('Submit Sales'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Riwayat Sales',
                children: sales.isEmpty
                    ? const [Text('Belum ada transaksi.')]
                    : sales
                        .map((item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['transaction_code']?.toString() ?? '-'),
                              subtitle: Text('${item['approval_status'] ?? '-'} • ${item['created_at'] ?? '-'}'),
                              trailing: Text('${item['total_harga'] ?? 0}'),
                            ))
                        .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() => _proofFile = File(file.path));
  }

  Future<void> _submitSale(BuildContext context) async {
    final session = context.read<SessionController>();
    try {
      await session.submitSale(
        items: [
          {
            'id_product': _productId,
            'quantity': int.tryParse(_qtyController.text) ?? 1,
          }
        ],
        customerName: _customerName.text.trim().isEmpty ? null : _customerName.text.trim(),
        customerPhone: _customerPhone.text.trim().isEmpty ? null : _customerPhone.text.trim(),
        customerSocial: _customerSocial.text.trim().isEmpty ? null : _customerSocial.text.trim(),
        promoId: _promoId,
        proofFile: _proofFile!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penjualan berhasil dikirim.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.readError(error))),
      );
    }
  }
}

class _KnowledgeTab extends StatelessWidget {
  const _KnowledgeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        final data = session.knowledge;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = (data['products'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return RefreshIndicator(
          onRefresh: session.refreshKnowledge,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: products.isEmpty
                ? [const _SectionCard(title: 'Menu Knowledge', children: [Text('Belum ada data.')])]
                : products
                    .map((item) => _SectionCard(
                          title: item['nama_product']?.toString() ?? '-',
                          children: [
                            Text(item['deskripsi']?.toString() ?? '-'),
                            const SizedBox(height: 8),
                            ...((item['fragrance_details'] as List<dynamic>? ?? [])
                                .cast<Map<String, dynamic>>()
                                .map((detail) => Text('${detail['jenis']}: ${detail['detail']}'))),
                          ],
                        ))
                    .toList(),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(body, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}


