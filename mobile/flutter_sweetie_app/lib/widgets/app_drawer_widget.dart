import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/session_controller.dart';

class AppDrawerWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final VoidCallback? onClose;

  const AppDrawerWidget({
    required this.currentIndex,
    required this.onNavigate,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        final isOwner = session.user?.role == 'owner';

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      session.user?.nama ?? 'Sweetie',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    Text(
                      (session.user?.role ?? 'user').toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              if (isOwner) ...[
                _SectionHeader('MENU UTAMA'),
                _DrawerItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  index: 0,
                  current: currentIndex,
                  onTap: () {
                    onNavigate(0);
                    onClose?.call();
                  },
                ),
                const Divider(height: 16),
                _SectionHeader('STOK DAN INVENTORY'),
                _DrawerItem(
                  icon: Icons.shopping_bag,
                  label: 'Product',
                  onTap: () {
                    // TODO: Navigate to Product CRUD screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.calculate,
                  label: 'HPP',
                  onTap: () {
                    // TODO: Navigate to HPP CRUD screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.grain,
                  label: 'Raw Material',
                  onTap: () {
                    // TODO: Navigate to Raw Material CRUD screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.add_circle,
                  label: 'Extra Topping',
                  onTap: () {
                    // TODO: Navigate to Extra Topping CRUD screen
                    onClose?.call();
                  },
                ),
                const Divider(height: 16),
                _SectionHeader('KEUANGAN'),
                _DrawerItem(
                  icon: Icons.money_off,
                  label: 'Pengeluaran',
                  onTap: () {
                    // TODO: Navigate to Pengeluaran CRUD screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.receipt,
                  label: 'Account Receivables',
                  onTap: () {
                    // TODO: Navigate to AR CRUD screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.payment,
                  label: 'Account Payables',
                  onTap: () {
                    // TODO: Navigate to AP CRUD screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.shopping_cart,
                  label: 'Penjualan Online',
                  onTap: () {
                    // TODO: Navigate to Online Sales view screen
                    onClose?.call();
                  },
                ),
                const Divider(height: 16),
                _SectionHeader('KARYAWAN'),
                _DrawerItem(
                  icon: Icons.notifications,
                  label: 'Notifikasi',
                  onTap: () {
                    // TODO: Navigate to Notifications screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.calendar_today,
                  label: 'Absensi Karyawan',
                  index: 1,
                  current: currentIndex,
                  onTap: () {
                    onNavigate(1);
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.book,
                  label: 'Product Knowledge',
                  onTap: () {
                    // TODO: Navigate to Product Knowledge CRUD screen
                    onClose?.call();
                  },
                ),
                const Divider(height: 16),
                _SectionHeader('PENGATURAN'),
                _DrawerItem(
                  icon: Icons.trending_up,
                  label: 'Target Penjualan',
                  onTap: () {
                    // TODO: Navigate to Target Penjualan CRUD screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.local_offer,
                  label: 'Promo',
                  onTap: () {
                    // TODO: Navigate to Promo CRUD screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.people,
                  label: 'Users',
                  onTap: () {
                    // TODO: Navigate to Users CRUD screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.person,
                  label: 'Customers',
                  onTap: () {
                    // TODO: Navigate to Customers CRUD screen
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.description,
                  label: 'SOP',
                  onTap: () {
                    // TODO: Navigate to SOP CRUD screen
                    onClose?.call();
                  },
                ),
              ] else ...[
                _SectionHeader('MENU'),
                _DrawerItem(
                  icon: Icons.calendar_today,
                  label: 'Absensi',
                  index: 1,
                  current: currentIndex,
                  onTap: () {
                    onNavigate(1);
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.point_of_sale,
                  label: 'Kasir',
                  index: 3,
                  current: currentIndex,
                  onTap: () {
                    onNavigate(3);
                    onClose?.call();
                  },
                ),
                _DrawerItem(
                  icon: Icons.book,
                  label: 'Product Knowledge',
                  index: 4,
                  current: currentIndex,
                  onTap: () {
                    onNavigate(4);
                    onClose?.call();
                  },
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  session.logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? index;
  final int? current;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.index,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index != null && current != null && index == current;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: isSelected,
      selectedTileColor:
          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
      onTap: onTap,
    );
  }
}
