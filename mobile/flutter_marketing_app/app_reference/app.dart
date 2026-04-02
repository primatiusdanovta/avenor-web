import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_marketing_app/src/screens/login_screen.dart';
import 'package:flutter_marketing_app/src/services/api_client.dart';
import 'package:flutter_marketing_app/src/services/session_store.dart';
import 'package:flutter_marketing_app/src/state/session_controller.dart';

class AvenorMarketingApp extends StatelessWidget {
  const AvenorMarketingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => SessionStore()),
        Provider(create: (_) => ApiClient()),
        ChangeNotifierProxyProvider2<SessionStore, ApiClient, SessionController>(
          create: (context) => SessionController(
            sessionStore: context.read<SessionStore>(),
            apiClient: context.read<ApiClient>(),
          )..restoreSession(),
          update: (context, sessionStore, apiClient, previous) => previous ??
              SessionController(
                sessionStore: sessionStore,
                apiClient: apiClient,
              ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Avenor Marketing',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB68A35),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0F1115),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF171A20),
            surfaceTintColor: Colors.transparent,
          ),
        ),
        home: Consumer<SessionController>(
          builder: (context, session, _) {
            if (session.isRestoring) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return session.isAuthenticated
                ? const HomeShell()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        final dashboard = session.dashboard;
        final attendance = session.attendance;
        final products = session.products;
        final sales = session.sales;
        final knowledge = session.knowledge;

        if (dashboard == null || attendance == null || products == null || sales == null || knowledge == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = dashboard['stats'] as Map<String, dynamic>? ?? {};
        final todayAttendance = attendance['today_attendance'] as Map<String, dynamic>? ?? {};
        final onhands = (products['onhands'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final salesRows = (sales['sales'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final knowledgeRows = (knowledge['products'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

        return Scaffold(
          appBar: AppBar(
            title: Text(session.user?.nama ?? 'Marketing'),
            actions: [
              IconButton(
                onPressed: session.refreshAll,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                onPressed: session.logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: session.refreshAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(label: 'On Hand', value: '${stats['onhand_count'] ?? 0}'),
                    _MetricCard(label: 'Pending Return', value: '${stats['pending_return_count'] ?? 0}'),
                    _MetricCard(label: 'Pending Take', value: '${stats['pending_take_count'] ?? 0}'),
                    _MetricCard(label: 'Sales Approved', value: '${stats['approved_sales_count'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 16),
                _BlockCard(
                  title: 'Absensi Hari Ini',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${todayAttendance['status'] ?? '-'}'),
                      Text('Check in: ${todayAttendance['check_in'] ?? '-'}'),
                      Text('Check out: ${todayAttendance['check_out'] ?? '-'}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton(
                            onPressed: () => _attendanceAction(context, true),
                            child: const Text('Quick Check In'),
                          ),
                          OutlinedButton(
                            onPressed: () => _attendanceAction(context, false),
                            child: const Text('Quick Check Out'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _BlockCard(
                  title: 'On Hand',
                  child: onhands.isEmpty
                      ? const Text('Belum ada data on hand.')
                      : Column(
                          children: onhands
                              .take(5)
                              .map((item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item['nama_product']?.toString() ?? '-'),
                                    subtitle: Text('${item['take_status_label']} • ${item['status_label']}'),
                                    trailing: Text('${item['remaining_quantity'] ?? 0}'),
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _BlockCard(
                  title: 'Recent Sales',
                  child: salesRows.isEmpty
                      ? const Text('Belum ada transaksi.')
                      : Column(
                          children: salesRows
                              .take(5)
                              .map((item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item['transaction_code']?.toString() ?? '-'),
                                    subtitle: Text('${item['approval_status'] ?? '-'} • ${item['created_at'] ?? '-'}'),
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _BlockCard(
                  title: 'Product Knowledge',
                  child: knowledgeRows.isEmpty
                      ? const Text('Belum ada data knowledge.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: knowledgeRows
                              .take(3)
                              .map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(item['nama_product']?.toString() ?? '-'),
                                  ))
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _attendanceAction(BuildContext context, bool isCheckIn) async {
    final session = context.read<SessionController>();

    try {
      if (isCheckIn) {
        await session.checkIn(
          status: 'hadir',
          latitude: -6.2,
          longitude: 106.8,
        );
      } else {
        await session.checkOut(
          status: 'hadir',
          latitude: -6.2,
          longitude: 106.8,
        );
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isCheckIn ? 'Check in berhasil.' : 'Check out berhasil.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.readError(error))),
      );
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

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
              Text(label),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
