import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/session_controller.dart';
import '../../widgets/popup_form_widget.dart';
import '../../widgets/app_drawer_widget.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _DashboardTab(),
      _AttendanceTab(),
      _ProductsTab(),
      _SalesTab(),
      _KnowledgeTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Consumer<SessionController>(
          builder: (context, session, _) => Row(
            children: [
              // Queue Icon (center logo above bar)
              Expanded(
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      // TODO: Show queue panel
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Queue feature - Coming soon')),
                      );
                    },
                    icon: const Icon(Icons.assignment),
                    tooltip: 'Antrian Penjualan',
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(session.user?.nama ?? 'Sweetie'),
              ),
            ],
          ),
        ),
        actions: [
          // Notifications Icon (both owner and karyawan)
          IconButton(
            onPressed: () {
              // TODO: Show notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications - Coming soon')),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikasi',
          ),
          // Kasir Icon (owner only)
          Consumer<SessionController>(
            builder: (context, session, _) {
              final isOwner = session.user?.role == 'owner';
              if (!isOwner) return const SizedBox.shrink();
              
              return IconButton(
                onPressed: () {
                  setState(() => _index = 3); // Navigate to Sales tab
                },
                icon: const Icon(Icons.point_of_sale),
                tooltip: 'Kasir',
              );
            },
          ),
          IconButton(
            onPressed: () => context.read<SessionController>().refreshAll(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => context.read<SessionController>().logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: AppDrawerWidget(
        currentIndex: _index,
        onNavigate: (index) => setState(() => _index = index),
        onClose: () => Navigator.pop(context),
      ),
      body: IndexedStack(index: _index, children: pages),
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
        final recentSales = (data['recent_sales'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

        return RefreshIndicator(
          onRefresh: session.refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(label: 'On Hand Hari Ini', value: '${stats['onhand_count'] ?? 0}'),
                  _StatCard(label: 'Pending Return', value: '${stats['pending_return_count'] ?? 0}'),
                  _StatCard(label: 'Pending Take', value: '${stats['pending_take_count'] ?? 0}'),
                  _StatCard(label: 'Sales Approved', value: '${stats['approved_sales_count'] ?? 0}'),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KPI Sweetie', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Sales score: ${kpi['sales_score'] ?? 0}'),
                      Text('Attendance score: ${kpi['attendance_score'] ?? 0}'),
                      Text('Hours score: ${kpi['hours_score'] ?? 0}'),
                      Text('Total score: ${kpi['total_score'] ?? 0}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Bulan Ini', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Daily target: ${target['daily']?['target_qty'] ?? 0} pcs'),
                      Text('Weekly target: ${target['weekly']?['target_qty'] ?? 0} pcs'),
                      Text('Monthly target: ${target['monthly']?['target_qty'] ?? 0} pcs'),
                      Text('Bonus total: ${target['bonus_total'] ?? 0}'),
                      if (target['reminder'] != null) ...[
                        const SizedBox(height: 8),
                        Text(target['reminder'].toString()),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Sales', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (recentSales.isEmpty)
                        const Text('Belum ada transaksi terbaru.')
                      else
                        ...recentSales.map(
                          (sale) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(sale['nama_product']?.toString() ?? '-'),
                            subtitle: Text('${sale['transaction_code'] ?? '-'} � ${sale['created_at'] ?? '-'}'),
                            trailing: Text('${sale['quantity'] ?? 0} pcs'),
                          ),
                        ),
                    ],
                  ),
                ),
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
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isCheckIn) async {
    final session = context.read<SessionController>();
    try {
      final action = isCheckIn ? session.checkIn : session.checkOut;
      await action(
        status: _status,
        latitude: -6.2,
        longitude: 106.8,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
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

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        final isOwner = session.user?.role == 'owner';
        
        if (isOwner) {
          return _buildOwnerAttendanceView(session);
        } else {
          return _buildKaryawanAttendanceView(session);
        }
      },
    );
  }

  Widget _buildKaryawanAttendanceView(SessionController session) {
    final data = session.attendance;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final today = data['today_attendance'] as Map<String, dynamic>?;
    final carriedProducts = (data['carried_products'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final recentAttendances = (data['recent_attendances'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return RefreshIndicator(
      onRefresh: session.refreshAttendance,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Absensi Hari Ini', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Status: ${today?['status'] ?? '-'}'),
                  Text('Check in: ${today?['check_in'] ?? '-'}'),
                  Text('Check out: ${today?['check_out'] ?? '-'}'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
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
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _submit(true),
                          child: const Text('Check In'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _submit(false),
                          child: const Text('Check Out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Barang Dibawa Hari Ini', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (carriedProducts.isEmpty)
                    const Text('Belum ada barang yang dibawa.')
                  else
                    ...carriedProducts.map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['nama_product']?.toString() ?? '-'),
                          subtitle: Text(item['status_label']?.toString() ?? '-'),
                          trailing: Text('${item['remaining_quantity'] ?? 0} sisa'),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Riwayat Absensi', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (recentAttendances.isEmpty)
                    const Text('Belum ada riwayat absensi.')
                  else
                    ...recentAttendances.map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['attendance_date']?.toString() ?? '-'),
                          subtitle: Text('${item['check_in'] ?? '-'} - ${item['check_out'] ?? '-'}'),
                          trailing: Text(item['status']?.toString() ?? '-'),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerAttendanceView(SessionController session) {
    final data = session.attendance;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final employeeAttendances = (data['employee_attendances'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return RefreshIndicator(
      onRefresh: session.refreshAttendance,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter Riwayat Absensi Karyawan', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal: '),
                    trailing: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        session.refreshAttendance();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Riwayat Absensi Karyawan - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (employeeAttendances.isEmpty)
                    const Text('Tidak ada data absensi untuk tanggal ini.')
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Nama')),
                          DataColumn(label: Text('Tanggal')),
                          DataColumn(label: Text('Check In')),
                          DataColumn(label: Text('Check Out')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Terlambat')),
                        ],
                        rows: employeeAttendances
                            .map(
                              (item) => DataRow(
                                cells: [
                                  DataCell(Text(item['employee_name']?.toString() ?? '-')),
                                  DataCell(Text(item['attendance_date']?.toString() ?? '-')),
                                  DataCell(Text(item['check_in']?.toString() ?? '-')),
                                  DataCell(Text(item['check_out']?.toString() ?? '-')),
                                  DataCell(Text(item['status']?.toString() ?? '-')),
                                  DataCell(Text(item['late_minutes']?.toString() ?? '-')),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final _qtyController = TextEditingController(text: '1');
  final _returnController = TextEditingController(text: '1');
  int? _selectedProductId;
  int? _selectedOnhandId;

  @override
  void dispose() {
    _qtyController.dispose();
    _returnController.dispose();
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

        _selectedProductId ??= products.isNotEmpty ? products.first['id_product'] as int? : null;
        _selectedOnhandId ??= returnItems.isNotEmpty ? returnItems.first['id_product_onhand'] as int? : null;

        return RefreshIndicator(
          onRefresh: session.refreshProducts,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Request Pengambilan Barang', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (data['attendance_blocked_reason'] != null)
                        Text(data['attendance_blocked_reason'].toString()),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedProductId,
                        items: products
                            .map((item) => DropdownMenuItem<int>(
                                  value: item['id_product'] as int,
                                  child: Text(item['option_label']?.toString() ?? '-'),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedProductId = value),
                        decoration: const InputDecoration(labelText: 'Product'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _selectedProductId == null
                            ? null
                            : () async {
                                try {
                                  await session.takeProduct(
                                    productId: _selectedProductId!,
                                    quantity: int.tryParse(_qtyController.text) ?? 1,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Request pengambilan dikirim.')),
                                  );
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(session.readError(error))),
                                  );
                                }
                              },
                        child: const Text('Kirim Request'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Request Return', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedOnhandId,
                        items: returnItems
                            .map((item) => DropdownMenuItem<int>(
                                  value: item['id_product_onhand'] as int,
                                  child: Text('${item['nama_product']} | sisa ${item['remaining_quantity']}'),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedOnhandId = value),
                        decoration: const InputDecoration(labelText: 'Barang On Hand'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _returnController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity Return'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _selectedOnhandId == null
                            ? null
                            : () async {
                                try {
                                  await session.requestReturn(
                                    onhandId: _selectedOnhandId!,
                                    quantity: int.tryParse(_returnController.text) ?? 1,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Request return dikirim.')),
                                  );
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(session.readError(error))),
                                  );
                                }
                              },
                        child: const Text('Kirim Return'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Semua On Hand', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (onhands.isEmpty)
                        const Text('Belum ada data on hand.')
                      else
                        ...onhands.map((item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['nama_product']?.toString() ?? '-'),

                              trailing: Text('${item['remaining_quantity'] ?? 0} sisa'),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SalesTab extends StatefulWidget {
  const _SalesTab();

  @override
  State<_SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<_SalesTab> {
  final _customerName = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  int? _selectedProductId;
  int? _selectedPromoId;
  File? _proofFile;

  @override
  void dispose() {
    _customerName.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) {
      return;
    }
    setState(() => _proofFile = File(file.path));
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
        _selectedProductId ??= products.isNotEmpty ? products.first['id_product'] as int? : null;

        return RefreshIndicator(
          onRefresh: session.refreshSales,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Input Penjualan Offline', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextField(controller: _customerName, decoration: const InputDecoration(labelText: 'Nama Customer')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedProductId,
                        items: products
                            .map((item) => DropdownMenuItem<int>(
                                  value: item['id_product'] as int,
                                  child: Text(item['option_label']?.toString() ?? '-'),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedProductId = value),
                        decoration: const InputDecoration(labelText: 'Product'),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        initialValue: _selectedPromoId,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Tanpa Promo')),
                          ...promos.map((item) => DropdownMenuItem<int?>(
                                value: item['id'] as int,
                                child: Text(item['option_label']?.toString() ?? '-'),
                              )),
                        ],
                        onChanged: (value) => setState(() => _selectedPromoId = value),
                        decoration: const InputDecoration(labelText: 'Promo'),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickProof,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(_proofFile == null ? 'Pilih Bukti' : 'Ganti Bukti'),
                          ),
                          if (_proofFile != null) Text(_proofFile!.path.split(Platform.pathSeparator).last),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _selectedProductId == null || _proofFile == null
                            ? null
                            : () async {
                                try {
                                  await session.submitSale(
                                    items: [
                                      {
                                        'id_product': _selectedProductId,
                                        'quantity': int.tryParse(_qtyController.text) ?? 1,
                                      }
                                    ],
                                    customerName: _customerName.text.trim().isEmpty ? null : _customerName.text.trim(),
                                    customerPhone: null,
                                    customerSocial: null,
                                    promoId: _selectedPromoId,
                                    proofFile: _proofFile!,
                                  );
                                  if (!context.mounted) return;
                                  // Show success popup
                                  showSalesSuccessPopup(
                                    context: context,
                                    saleData: {
                                      'transaction_code': 'Penjualan berhasil',
                                      'created_at': DateTime.now().toString(),
                                      'customer_name': _customerName.text.trim(),
                                      'total_amount': 0,
                                    },
                                    onClose: () {
                                      // Clear form
                                      _customerName.clear();
                                      _qtyController.text = '1';
                                      setState(() => _proofFile = null);
                                      session.refreshSales();
                                    },
                                  );
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(session.readError(error))),
                                  );
                                }
                              },
                        child: const Text('Submit Sales'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riwayat Transaksi', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (sales.isEmpty)
                        const Text('Belum ada transaksi.')
                      else
                        ...sales.map((item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['transaction_code']?.toString() ?? '-'),
                              subtitle: Text('${item['approval_status'] ?? '-'} � ${item['created_at'] ?? '-'}'),
                              trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(item['total_harga'] ?? 0)),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
            children: [
              if (products.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada product knowledge.')))
              else
                ...products.map((item) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nama_product']?.toString() ?? '-', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(item['deskripsi']?.toString() ?? '-'),
                            const SizedBox(height: 12),
                            ...((item['fragrance_details'] as List<dynamic>? ?? [])
                                .cast<Map<String, dynamic>>()
                                .map((detail) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text('${detail['jenis']}: ${detail['detail']}'),
                                    ))),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

