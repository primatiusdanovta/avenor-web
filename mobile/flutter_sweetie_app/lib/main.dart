import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:io';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chips_input/flutter_chips_input.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'notification_scheduler.dart';
part 'sales_history_sheet.dart';
part 'owner_modules.dart';
part 'sales_models.dart';
part 'sales_option_sheet.dart';
part 'sales_page.dart';
part 'sales_submit_service.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'SWEETIE_API_BASE_URL',
  defaultValue: 'https://avenorperfume.site/api/mobile',
);
const bool kUseMock =
    bool.fromEnvironment('SWEETIE_USE_MOCK', defaultValue: false);
const String kSweetieLogoAsset = 'assets/images/sweetie.png';
const String kSweetieQrisAsset = 'assets/images/qr_smoothies.jpeg';
const Color kSweetiePink = Color(0xFFD980B4);
const Color kSweetiePurple = Color(0xFF8E79D6);
const Color kSweetieLavender = Color(0xFFF7F0FB);
const Color kSweetieInk = Color(0xFF342A46);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      details.exceptionAsString(),
      name: 'SmoothiesSweetieApp',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  await initializeDateFormatting('id_ID');
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFFF7F1E8),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: Color(0xFFC05D3B),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aplikasi mengalami kendala tampilan.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2B2117),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF6F665F),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  runZonedGuarded(
    () => runApp(const SmoothiesSweetieApp()),
    (error, stackTrace) {
      developer.log(
        'Unhandled zone error',
        name: 'SmoothiesSweetieApp',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
  unawaited(_initializeStartupServices());
}

Future<void> _initializeStartupServices() async {
  try {
    await NotificationScheduler.instance.initialize();
  } catch (error, stackTrace) {
    developer.log(
      'Notification initialization failed',
      name: 'SmoothiesSweetieApp',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class SmoothiesSweetieApp extends StatelessWidget {
  const SmoothiesSweetieApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kSweetiePurple,
      brightness: Brightness.light,
    );

    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smoothies Sweetie',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: const Color(0xFFFDF8FE),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            Typography.blackMountainView,
          ).apply(
            bodyColor: kSweetieInk,
            displayColor: kSweetieInk,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            shadowColor: const Color(0x148E79D6),
            elevation: 1.5,
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white.withValues(alpha: 0.94),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: 76,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              return TextStyle(
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: states.contains(WidgetState.selected)
                    ? kSweetieInk
                    : const Color(0xFF766C8B),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              return IconThemeData(
                size: 24,
                color: states.contains(WidgetState.selected)
                    ? kSweetieInk
                    : const Color(0xFF766C8B),
              );
            }),
            indicatorColor: const Color(0xFFF2E6FB),
            indicatorShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFBF6FE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE9DDF5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: kSweetiePurple, width: 1.4),
            ),
          ),
        ),
        home: const MarketingRoot(),
      ),
    );
  }
}

class MarketingRoot extends StatefulWidget {
  const MarketingRoot({super.key});

  @override
  State<MarketingRoot> createState() => _MarketingRootState();
}

class _MarketingRootState extends State<MarketingRoot> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      headers: {'Accept': 'application/json'},
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final ImagePicker _picker = ImagePicker();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final DateFormat _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  StreamSubscription<Map<String, dynamic>>? _notificationTapSubscription;

  bool _loading = true;
  bool _loggingIn = false;
  bool _busy = false;
  bool _mockMode = kUseMock;
  bool _obscureLoginPassword = true;
  int _navigationIndex = 0;
  int _unreadNotificationCount = 0;
  String? _token;
  String? _error;
  String? _locationLabel;
  Map<String, dynamic>? _me;
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _attendance;
  Map<String, dynamic>? _products;
  Map<String, dynamic>? _sales;
  Map<String, dynamic>? _consignments;
  Map<String, dynamic>? _knowledge;
  Map<String, dynamic>? _notifications;
  Map<String, dynamic>? _queue;
  Map<String, dynamic>? _pendingOpenedNotification;

  @override
  void initState() {
    super.initState();
    _notificationTapSubscription = NotificationScheduler
        .instance.onNotificationTap
        .listen(_handleNotificationTap);
    unawaited(_restorePendingNotificationLaunch());
    _restoreSession();
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restorePendingNotificationLaunch() async {
    await NotificationScheduler.instance.initialize();
    final pending =
        NotificationScheduler.instance.consumePendingLaunchNotification();
    if (pending != null) {
      _handleNotificationTap(pending);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    _pendingOpenedNotification = Map<String, dynamic>.from(notification);
    unawaited(_tryPresentPendingNotification());
  }

  Future<void> _tryPresentPendingNotification() async {
    if (!mounted ||
        _loading ||
        _token == null ||
        _pendingOpenedNotification == null) {
      return;
    }

    final notification = Map<String, dynamic>.from(_pendingOpenedNotification!);
    _pendingOpenedNotification = null;

    await NotificationScheduler.instance.markNotificationsSeen([notification]);
    await _refreshNotificationBadgeState();

    if (!mounted) {
      return;
    }

    if (_navigationIndex != 0) {
      setState(() => _navigationIndex = 0);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final notifications = ((_notifications?['notifications'] as List?) ?? [])
          .cast<Map<String, dynamic>>();
      _showNotificationsSheet(
        notifications,
        initialNotification: notification,
      );
    });
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('sweetie_token');
    final useMock = prefs.getBool('sweetie_mock_mode') ?? kUseMock;

    if (!mounted) return;
    setState(() => _mockMode = useMock);

    if (useMock && (token == null || token.isEmpty)) {
      await _bootstrapMockSession();
      return;
    }

    if (token == null || token.isEmpty) {
      setState(() => _loading = false);
      await _tryPresentPendingNotification();
      return;
    }

    _setToken(token);
    try {
      await _refreshAll(showLoader: false);
    } catch (_) {
      await _clearSession();
    }

    if (mounted) {
      setState(() => _loading = false);
    }
    await _tryPresentPendingNotification();
  }

  Future<void> _bootstrapMockSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sweetie_mock_mode', true);
    _mockMode = true;
    _token = 'mock-token';
    _hydrateMockData();
    await _refreshNotificationBadgeState();
    if (mounted) {
      setState(() => _loading = false);
    }
    await _tryPresentPendingNotification();
  }

  void _hydrateMockData() {
    final now = DateTime.now();
    _me = {
      'nama': 'Alya Pramesti',
      'role': 'karyawan',
      'wilayah': 'Jakarta Barat',
      'sales_qr_url': null,
      'sales_qr_name': null,
    };
    _attendance = {
      'today_attendance': {
        'status': 'hadir',
        'check_in': '08:42:00',
        'check_out': null,
        'notes': 'Booth Lippo Puri.',
      },
      'recent_attendances': [
        {
          'attendance_date': _formatYmd(now),
          'status': 'hadir',
          'check_in': '08:42:00',
          'check_out': null,
          'check_in_location': '-6.17639, 106.79016',
          'check_out_location': '-',
        },
        {
          'attendance_date': _formatYmd(now.subtract(const Duration(days: 1))),
          'status': 'hadir',
          'check_in': '08:35:00',
          'check_out': '18:07:00',
          'check_in_location': '-6.17711, 106.79100',
          'check_out_location': '-6.17690, 106.79081',
        },
      ],
      'carried_products': [],
      'latest_location': {
        'latitude': -6.17639,
        'longitude': 106.79016,
        'recorded_at': _formatYmdHis(now),
        'source': 'check_in',
      },
    };
    _products = {
      'attendance_ready': true,
      'attendance_blocked_reason': null,
      'today_attendance': _attendance?['today_attendance'],
      'products': [
        {
          'id_product': 1,
          'nama_product': 'Berry Bliss Smoothie',
          'stock': 38,
          'harga': 38000.0,
          'deskripsi': 'Campuran stroberi, yogurt, dan madu yang manis segar.',
          'image_url': null,
          'badge_labels': ['Berry', 'Creamy', 'Best Seller'],
          'option_label': 'Berry Bliss Smoothie | stock 38',
        },
        {
          'id_product': 2,
          'nama_product': 'Mango Sunshine Smoothie',
          'stock': 24,
          'harga': 34000.0,
          'deskripsi':
              'Mango, nanas, dan jeruk yang cerah untuk menu favorit harian.',
          'image_url': null,
          'badge_labels': ['Mango', 'Fresh', 'Tropical'],
          'option_label': 'Mango Sunshine Smoothie | stock 24',
        },
        {
          'id_product': 3,
          'nama_product': 'Choco Banana Crunch',
          'stock': 16,
          'harga': 42000.0,
          'deskripsi':
              'Pisang, cokelat, dan granola untuk tekstur lebih mengenyangkan.',
          'image_url': null,
          'badge_labels': ['Chocolate', 'Banana', 'Crunchy'],
          'option_label': 'Choco Banana Crunch | stock 16',
        },
      ],
      'onhands': <Map<String, dynamic>>[],
      'today_return_items': [],
      'history_onhands': <Map<String, dynamic>>[],
    };
    _sales = {
      'sales': [
        {
          'transaction_code': 'TRX-20260402-AVN001',
          'sale_number':
              '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${(now.year % 100).toString().padLeft(2, '0')} - 1',
          'payment_method': 'Qris',
          'payment_status': 'paid',
          'approval_status': 'pending',
          'nama_customer': 'Nadia',
          'no_telp': '08123456789',
          'promo': 'Booth Launch',
          'created_at': _formatYmdHis(now.subtract(const Duration(hours: 1))),
          'total_quantity': 1,
          'total_harga': 49000.0,
          'items': [
            {
              'id_product': 1,
              'nama_product': 'Berry Bliss Smoothie - Reguler',
              'product_variant_id': 11,
              'product_variant_name': 'Reguler',
              'extra_topping_ids': [201],
              'sugar_level': 'Less',
              'extra_toppings': [
                {'id': 201, 'name': 'Pearl Boba', 'price': 6000.0},
              ],
              'quantity': 1,
              'harga': 49000.0,
            }
          ],
        }
      ],
      'products': [
        {
          'id_product': 1,
          'nama_product': 'Berry Bliss Smoothie',
          'harga': 38000.0,
          'remaining': 3,
          'option_label': 'Berry Bliss Smoothie | Sisa 3',
          'variants': [
            {
              'id': 11,
              'name': 'Reguler',
              'price': 38000.0,
              'total_satuan_ml': 350.0,
              'is_default': true,
            },
            {
              'id': 12,
              'name': 'Large',
              'price': 44000.0,
              'total_satuan_ml': 500.0,
              'is_default': false,
            },
          ],
        },
        {
          'id_product': 3,
          'nama_product': 'Choco Banana Crunch',
          'harga': 42000.0,
          'remaining': 2,
          'option_label': 'Choco Banana Crunch | Sisa 2',
          'variants': [
            {
              'id': 31,
              'name': 'Reguler',
              'price': 42000.0,
              'total_satuan_ml': 350.0,
              'is_default': true,
            },
          ],
        },
      ],
      'promos': [
        {
          'id': 7,
          'kode_promo': 'BOOST25',
          'nama_promo': 'Booth Launch',
          'potongan': 5000.0,
          'masa_aktif': _formatYmd(now.add(const Duration(days: 5))),
          'minimal_quantity': 1,
          'minimal_belanja': 35000.0,
          'option_label': 'Booth Launch | BOOST25',
        },
        {
          'id': 8,
          'kode_promo': 'DUO40',
          'nama_promo': 'Bundle 2 Item',
          'potongan': 10000.0,
          'masa_aktif': _formatYmd(now.add(const Duration(days: 3))),
          'minimal_quantity': 2,
          'minimal_belanja': 70000.0,
          'option_label': 'Bundle 2 Item | DUO40',
        },
      ],
      'extra_toppings': [
        {
          'id': 201,
          'name': 'Pearl Boba',
          'price': 6000.0,
        },
        {
          'id': 202,
          'name': 'Cheese Foam',
          'price': 7000.0,
        },
      ],
      'sops': [
        {
          'id_sop': 1,
          'title': 'Closing QRIS',
          'detail':
              'Pastikan nominal sesuai, tunjukkan QRIS, lalu arahkan pesanan ke antrian.',
        },
        {
          'id_sop': 2,
          'title': 'Check Topping',
          'detail':
              'Konfirmasi size, topping, dan label cup sebelum serahkan ke blender bar.',
        },
      ],
      'qris_image_url':
          'https://avenorperfume.site/storage/global-settings/social-hub/sales-qr.png',
      'is_smoothies_sweetie': true,
    };
    _consignments = {
      'products': <Map<String, dynamic>>[],
      'consignments': <Map<String, dynamic>>[],
    };
    _knowledge = {
      'products': [
        {
          'id_product': 1,
          'nama_product': 'Berry Bliss Smoothie',
          'deskripsi': 'White peony, almond milk, dan soft vanilla.',
          'gambar': null,
          'fragrance_details': [
            {
              'jenis': 'top',
              'detail': 'Floral',
              'deskripsi': 'Bukaan lembut dan cerah.'
            },
            {
              'jenis': 'base',
              'detail': 'Creamy',
              'deskripsi': 'Akhir aroma hangat dan halus.'
            },
          ],
        },
        {
          'id_product': 2,
          'nama_product': 'Mango Sunshine Smoothie',
          'deskripsi': 'Bergamot, neroli, white musk untuk profile segar.',
          'gambar': null,
          'fragrance_details': [
            {
              'jenis': 'top',
              'detail': 'Citrus',
              'deskripsi': 'Segar, bright, dan lively.'
            },
            {
              'jenis': 'heart',
              'detail': 'Fresh',
              'deskripsi': 'Cocok untuk daily wear.'
            },
          ],
        },
        {
          'id_product': 3,
          'nama_product': 'Choco Banana Crunch',
          'deskripsi':
              'Saffron, cedar, dan oud smoke untuk signature malam hari.',
          'gambar': null,
          'fragrance_details': [
            {
              'jenis': 'heart',
              'detail': 'Woody',
              'deskripsi': 'Nuansa kayu elegan dan tegas.'
            },
            {
              'jenis': 'base',
              'detail': 'Amber',
              'deskripsi': 'Dry down hangat dan mewah.'
            },
          ],
        },
      ],
    };
    _notifications = {
      'notifications': [
        {
          'id': 1,
          'title': 'Reminder Briefing Pagi',
          'excerpt':
              'Semua karyawan wajib hadir briefing pukul 09.00 sebelum operasional dimulai hari ini.',
          'body':
              'Semua karyawan wajib hadir briefing pukul 09.00 sebelum operasional dimulai hari ini. Mohon datang 10 menit lebih awal dan siapkan laporan stok on hand terakhir.',
          'published_at':
              _formatYmdHis(now.subtract(const Duration(minutes: 30))),
        },
        {
          'id': 2,
          'title': 'Update Promo Booth Central Park',
          'excerpt':
              'Promo BOOST25 diperpanjang sampai malam ini untuk transaksi minimal 1 item.',
          'body':
              'Promo BOOST25 diperpanjang sampai malam ini untuk transaksi minimal 1 item. Gunakan materi promo terbaru saat closing dan informasikan bonus sample untuk customer repeat order.',
          'published_at': _formatYmdHis(now.subtract(const Duration(hours: 3))),
        },
      ],
    };
    _queue = {
      'items': [
        {
          'sale_number':
              '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${(now.year % 100).toString().padLeft(2, '0')} - 1',
          'queue_number': 1,
          'transaction_code': 'TRX-20260402-AVN001',
          'customer_name': 'Nadia',
          'payment_status': 'paid',
          'created_at': _formatYmdHis(now),
          'details': [
            {
              'nama_product': 'Berry Bliss Smoothie - Reguler',
              'quantity': 1,
              'sugar_level': 'Less',
              'extra_toppings': ['Pearl Boba'],
            }
          ],
        },
      ],
    };
    _syncMockDerivedState();
  }

  void _syncMockDerivedState() {
    final onhands =
        ((_products?['onhands'] as List?) ?? []).cast<Map<String, dynamic>>();
    final sales =
        ((_sales?['sales'] as List?) ?? []).cast<Map<String, dynamic>>();
    final products =
        ((_products?['products'] as List?) ?? []).cast<Map<String, dynamic>>();
    final consignments = ((_consignments?['consignments'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    final soldByOnhand = <int, int>{};
    final activeConsignByOnhand = <int, int>{};
    for (final consignment in consignments) {
      final items =
          ((consignment['items'] as List?) ?? []).cast<Map<String, dynamic>>();
      for (final item in items) {
        final onhandId = _asInt(item['product_onhand_id'],
                    fallback: _asInt(item['id'], fallback: -1)) ==
                -1
            ? null
            : _asInt(item['product_onhand_id'],
                fallback: _asInt(item['id'], fallback: -1));
        if (onhandId == null) {
          continue;
        }
        final sold = _asInt(item['sold_quantity']);
        final returned = _asInt(item['returned_quantity']);
        final quantity = _asInt(item['quantity']);
        soldByOnhand[onhandId] = (soldByOnhand[onhandId] ?? 0) + sold;
        activeConsignByOnhand[onhandId] =
            (activeConsignByOnhand[onhandId] ?? 0) +
                max(quantity - sold - returned, 0);
      }
    }

    for (final onhand in onhands) {
      final onhandId = _asInt(onhand['id_product_onhand'], fallback: -1) == -1
          ? null
          : _asInt(onhand['id_product_onhand']);
      final takeStatus = onhand['take_status']?.toString();
      if (takeStatus != 'disetujui') {
        onhand['remaining_quantity'] =
            takeStatus == 'pending' ? 0 : (onhand['remaining_quantity'] ?? 0);
        onhand['sold_out'] = false;
        onhand['max_return'] = 0;
        continue;
      }
      final totalQuantity = _asInt(onhand['quantity']);
      final directSold = _asInt(onhand['sold_quantity']);
      final consignmentSold =
          onhandId == null ? 0 : (soldByOnhand[onhandId] ?? 0);
      final pendingReturn = onhand['return_status'] == 'pending'
          ? _asInt(onhand['quantity_dikembalikan'])
          : 0;
      final approvedReturn = _asInt(onhand['approved_return_quantity']);
      final activeConsignment =
          onhandId == null ? 0 : (activeConsignByOnhand[onhandId] ?? 0);
      final soldTotal = directSold + consignmentSold;
      final remaining = max(
        totalQuantity -
            soldTotal -
            approvedReturn -
            pendingReturn -
            activeConsignment,
        0,
      );

      onhand['remaining_quantity'] = remaining;
      onhand['sold_out'] = soldTotal >= totalQuantity;
      onhand['max_return'] = max(totalQuantity - soldTotal - approvedReturn, 0);
      if (onhand['sold_out'] == true) {
        onhand['status_label'] = 'Sold out';
      } else if (activeConsignment > 0) {
        onhand['status_label'] = 'Sebagian dititipkan consign';
      } else if (onhand['return_status'] == 'pending') {
        onhand['status_label'] = 'Menunggu approval retur';
      } else {
        onhand['status_label'] = 'Masih dibawa';
      }
    }

    final approvedSalesCount =
        sales.where((item) => item['approval_status'] == 'approved').length;
    final pendingTake =
        onhands.where((item) => item['take_status'] == 'pending').length;
    final pendingReturn =
        onhands.where((item) => item['return_status'] == 'pending').length;
    final onHandCount = onhands.isEmpty
        ? products.fold<int>(
            0,
            (sum, item) => sum + _asInt(item['stock']),
          )
        : onhands.where(_isCountedAsOnHand).fold<int>(0, (sum, item) {
            return sum + _asInt(item['remaining_quantity']);
          });

    _dashboard = {
      'stats': {
        'onhand_count': onHandCount,
        'pending_return_count': pendingReturn,
        'pending_take_count': pendingTake,
        'approved_sales_count': approvedSalesCount,
      },
      'greeting': 'Siap closing hari ini',
      'target_today': 3500000,
      'products_ready': products.length,
    };

    _attendance?['carried_products'] =
        onhands.where(_isCountedAsOnHand).toList();
    _products?['today_return_items'] =
        onhands.where(_isCountedAsOnHand).toList();
    _products?['history_onhands'] = onhands
        .where((item) =>
            item['take_status'] == 'disetujui' && !_isCountedAsOnHand(item))
        .toList();
    _sales?['products'] = _buildMockSalesProducts(onhands);
    _consignments?['products'] = _buildMockConsignmentProducts(onhands);
    _enrichConsignmentPresentationData();
  }

  void _syncDerivedConsignmentInventoryState() {
    final onhands =
        ((_products?['onhands'] as List?) ?? []).cast<Map<String, dynamic>>();
    final consignments = ((_consignments?['consignments'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    if (onhands.isEmpty) {
      _enrichConsignmentPresentationData();
      return;
    }

    final soldByOnhand = <int, int>{};
    final activeConsignByOnhand = <int, int>{};
    for (final consignment in consignments) {
      final items =
          ((consignment['items'] as List?) ?? []).cast<Map<String, dynamic>>();
      for (final item in items) {
        final onhandId = _asInt(item['product_onhand_id'],
                    fallback: _asInt(item['id'], fallback: -1)) ==
                -1
            ? null
            : _asInt(item['product_onhand_id'],
                fallback: _asInt(item['id'], fallback: -1));
        if (onhandId == null) {
          continue;
        }
        final sold = _asInt(item['sold_quantity']);
        final returned = _asInt(item['returned_quantity']);
        final quantity = _asInt(item['quantity']);
        soldByOnhand[onhandId] = (soldByOnhand[onhandId] ?? 0) + sold;
        activeConsignByOnhand[onhandId] =
            (activeConsignByOnhand[onhandId] ?? 0) +
                max(quantity - sold - returned, 0);
      }
    }

    for (final onhand in onhands) {
      final onhandId = _asInt(onhand['id_product_onhand'], fallback: -1) == -1
          ? null
          : _asInt(onhand['id_product_onhand']);
      final takeStatus = onhand['take_status']?.toString();
      if (takeStatus != 'disetujui') {
        continue;
      }

      final totalQuantity = _asInt(onhand['quantity']);
      final directSold = _asInt(onhand['sold_quantity']);
      final consignmentSold =
          onhandId == null ? 0 : (soldByOnhand[onhandId] ?? 0);
      final pendingReturn = onhand['return_status'] == 'pending'
          ? _asInt(onhand['quantity_dikembalikan'])
          : 0;
      final approvedReturn = _asInt(onhand['approved_return_quantity']);
      final activeConsignment =
          onhandId == null ? 0 : (activeConsignByOnhand[onhandId] ?? 0);
      final soldTotal = directSold + consignmentSold;
      final remaining = max(
        totalQuantity -
            soldTotal -
            approvedReturn -
            pendingReturn -
            activeConsignment,
        0,
      );

      onhand['remaining_quantity'] = remaining;
      onhand['sold_out'] = soldTotal >= totalQuantity;
      onhand['max_return'] = max(totalQuantity - soldTotal - approvedReturn, 0);
      if (onhand['sold_out'] == true) {
        onhand['status_label'] = 'Sold out';
      } else if (activeConsignment > 0) {
        onhand['status_label'] = 'Sebagian dititipkan consign';
      } else if (onhand['return_status'] == 'pending') {
        onhand['status_label'] = 'Menunggu approval retur';
      } else {
        onhand['status_label'] = 'Masih dibawa';
      }
    }

    _products?['history_onhands'] = onhands
        .where((item) =>
            item['take_status'] == 'disetujui' && !_isCountedAsOnHand(item))
        .toList();
    _consignments?['products'] = _buildMockConsignmentProducts(onhands);
    _enrichConsignmentPresentationData();
  }

  void _enrichConsignmentPresentationData() {
    final knowledgeProducts =
        ((_knowledge?['products'] as List?) ?? []).cast<Map<String, dynamic>>();
    final knowledgeById = <int, Map<String, dynamic>>{
      for (final product in knowledgeProducts)
        if ((product['id_product'] as num?)?.toInt() != null)
          (product['id_product'] as num).toInt(): product,
    };

    final consignmentProducts = ((_consignments?['products'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    for (final product in consignmentProducts) {
      final productId = (product['id_product'] as num?)?.toInt();
      final knowledge = productId == null ? null : knowledgeById[productId];
      if (knowledge == null) {
        continue;
      }
      product['fragrance_details'] = knowledge['fragrance_details'];
      product['deskripsi'] ??= knowledge['deskripsi'];
    }

    final consignments = ((_consignments?['consignments'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    for (final consignment in consignments) {
      final items =
          ((consignment['items'] as List?) ?? []).cast<Map<String, dynamic>>();
      for (final item in items) {
        Map<String, dynamic>? matchedProduct;
        try {
          matchedProduct = consignmentProducts.firstWhere(
            (product) =>
                product['id_product_onhand'] == item['product_onhand_id'],
          );
        } catch (_) {
          matchedProduct = null;
        }

        if (matchedProduct != null) {
          item['fragrance_details'] ??= matchedProduct['fragrance_details'];
          item['deskripsi'] ??= matchedProduct['deskripsi'];
        }

        final productId = (matchedProduct?['id_product'] as num?)?.toInt();
        final knowledge = productId == null ? null : knowledgeById[productId];
        if (knowledge != null) {
          item['fragrance_details'] ??= knowledge['fragrance_details'];
          item['deskripsi'] ??= knowledge['deskripsi'];
        }
      }
    }
  }

  List<Map<String, dynamic>> _buildMockSalesProducts(
      List<Map<String, dynamic>> onhands) {
    final catalog =
        ((_products?['products'] as List?) ?? []).cast<Map<String, dynamic>>();
    final currentSalesProducts =
        ((_sales?['products'] as List?) ?? []).cast<Map<String, dynamic>>();

    if (onhands.isEmpty) {
      return catalog
          .where((product) => _asInt(product['stock']) > 0)
          .map((product) {
        Map<String, dynamic>? current;
        try {
          current = currentSalesProducts.firstWhere(
            (item) => item['id_product'] == product['id_product'],
          );
        } catch (_) {
          current = null;
        }

        final stock = _asInt(product['stock']);
        return {
          'id_product': product['id_product'],
          'nama_product': product['nama_product'],
          'harga': product['harga'],
          'stock': stock,
          'remaining': stock,
          'image_url': product['image_url'],
          'badge_labels': product['badge_labels'],
          'variants': ((current?['variants'] as List?) ?? const <dynamic>[])
              .cast<Map<String, dynamic>>(),
          'option_label': '${product['nama_product']} | stock $stock',
        };
      }).toList();
    }

    final totals = <int, int>{};
    for (final onhand in onhands) {
      if (!_isCountedAsOnHand(onhand)) {
        continue;
      }
      final productId = _asInt(onhand['id_product'], fallback: -1) == -1
          ? null
          : _asInt(onhand['id_product']);
      if (productId == null) {
        continue;
      }
      totals[productId] =
          (totals[productId] ?? 0) + _asInt(onhand['remaining_quantity']);
    }

    return catalog
        .where((product) =>
            (totals[_asInt(product['id_product'], fallback: -1)] ?? 0) > 0)
        .map((product) {
      final productId = _asInt(product['id_product']);
      final remaining = totals[productId] ?? 0;
      return {
        'id_product': productId,
        'nama_product': product['nama_product'],
        'harga': product['harga'],
        'stock': product['stock'],
        'remaining': remaining,
        'image_url': product['image_url'],
        'badge_labels': product['badge_labels'],
        'variants': ((product['variants'] as List?) ?? const <dynamic>[])
            .cast<Map<String, dynamic>>(),
        'option_label': '${product['nama_product']} | Sisa $remaining',
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildMockConsignmentProducts(
      List<Map<String, dynamic>> onhands) {
    return onhands
        .where((onhand) =>
            onhand['take_status'] == 'disetujui' &&
            _asInt(onhand['remaining_quantity']) > 0)
        .map((onhand) {
      final remaining = _asInt(onhand['remaining_quantity']);
      return {
        'id_product_onhand': onhand['id_product_onhand'],
        'id_product': onhand['id_product'],
        'nama_product': onhand['nama_product'],
        'pickup_batch_code': onhand['pickup_batch_code'],
        'available_quantity': remaining,
        'option_label':
            '${onhand['nama_product']} | batch ${onhand['pickup_batch_code'] ?? '-'} | sisa $remaining',
      };
    }).toList();
  }

  static bool _isCountedAsOnHand(Map<String, dynamic> item) {
    final takeStatus = item['take_status']?.toString().toLowerCase() ?? '';
    final remainingQuantity = _asInt(item['remaining_quantity']);
    final soldOut = item['sold_out'] == true || remainingQuantity <= 0;

    return takeStatus == 'disetujui' && !soldOut;
  }

  static bool _countsTowardTarget(Map<String, dynamic> sale) {
    final approvalStatus =
        sale['approval_status']?.toString().toLowerCase().trim() ?? '';
    return approvalStatus != 'rejected' && approvalStatus != 'ditolak';
  }

  void _setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sweetie_token');
    await prefs.remove('sweetie_mock_mode');
    await NotificationScheduler.instance.clearStoredState();
    _token = null;
    _me = null;
    _dashboard = null;
    _attendance = null;
    _products = null;
    _sales = null;
    _consignments = null;
    _knowledge = null;
    _notifications = null;
    _queue = null;
    _unreadNotificationCount = 0;
    _dio.options.headers.remove('Authorization');
  }

  Future<void> _refreshNotificationBadgeState() async {
    final notifications = ((_notifications?['notifications'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final unreadCount = await NotificationScheduler.instance
        .countUnreadNotifications(notifications);

    if (!mounted) {
      return;
    }

    setState(() => _unreadNotificationCount = unreadCount);
  }

  Future<void> _login() async {
    setState(() {
      _loggingIn = true;
      _error = null;
    });

    try {
      if (_mockMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('sweetie_mock_mode', true);
        await prefs.setString('sweetie_token', 'mock-token');
        _token = 'mock-token';
        _hydrateMockData();
        await _refreshNotificationBadgeState();
        await _tryPresentPendingNotification();
        return;
      }

      final response = await _dio.post('/auth/login', data: {
        'nama': _usernameController.text.trim(),
        'password': _passwordController.text,
        'device_name': 'Smoothies Sweetie App',
      });

      final token =
          (response.data as Map<String, dynamic>)['token']?.toString() ?? '';
      if (token.isEmpty) {
        throw Exception('Token login tidak diterima.');
      }

      _setToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sweetie_mock_mode', false);
      await prefs.setString('sweetie_token', token);
      await _refreshAll(showLoader: false);
      await _tryPresentPendingNotification();
    } on DioException catch (error) {
      setState(() => _error = _readError(error));
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loggingIn = false);
      }
    }
  }

  Future<void> _refreshAll({bool showLoader = false}) async {
    if (_mockMode) {
      setState(() {
        if (showLoader) _busy = true;
        _syncMockDerivedState();
      });
      await _refreshNotificationBadgeState();
      await _tryPresentPendingNotification();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() => _busy = false);
      }
      return;
    }

    if (showLoader && mounted) {
      setState(() => _busy = true);
    }

    try {
      final meResponse = await _dio.get('/auth/me');
      final mePayload = _asMap(meResponse.data);
      final me = _asMap(mePayload['user']);
      final role = me['role']?.toString() ?? '';

      final futures = <Future<Response<dynamic>>>[
        _dio.get('/dashboard'),
        _dio.get('/attendance'),
        _dio.get('/products'),
        _dio.get('/offline-sales'),
        role == 'sales_field_executive'
            ? _dio.get('/consignments')
            : Future.value(Response(
                requestOptions: RequestOptions(path: '/consignments'),
                data: <String, dynamic>{
                  'products': <Map<String, dynamic>>[],
                  'consignments': <Map<String, dynamic>>[],
                },
              )),
        _dio.get('/product-knowledge'),
        _dio.get('/notifications'),
        _dio.get('/queue'),
      ];
      final results = await Future.wait(futures);

      if (!mounted) return;
      setState(() {
        _me = me;
        _dashboard = _asMap(results[0].data);
        _attendance = _asMap(results[1].data);
        _products = _asMap(results[2].data);
        _sales = _asMap(results[3].data);
        _consignments = _asMap(results[4].data);
        _knowledge = _asMap(results[5].data);
        _notifications = _asMap(results[6].data);
        _queue = _asMap(results[7].data);
        _syncDerivedConsignmentInventoryState();
      });
      await NotificationScheduler.instance.syncServerNotifications(
        _asMapList(_notifications?['notifications']),
      );
      await _refreshNotificationBadgeState();
      await _tryPresentPendingNotification();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<Position> _resolveLocation() async {
    if (_mockMode) {
      return Position(
        longitude: 106.79016,
        latitude: -6.17639,
        timestamp: DateTime.now(),
        accuracy: 4,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'GPS belum aktif. Nyalakan layanan lokasi terlebih dahulu.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Izin lokasi ditolak.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengaktifkannya.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _submitAttendance({
    required bool checkIn,
    required String status,
    String? notes,
  }) async {
    setState(() => _busy = true);
    try {
      final position = await _resolveLocation();
      if (!mounted) return;
      final label =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      if (_mockMode) {
        final today =
            (_attendance?['today_attendance'] as Map<String, dynamic>? ??
                <String, dynamic>{});
        final now = TimeOfDay.fromDateTime(DateTime.now()).format(context);
        today['status'] = status;
        today['notes'] = notes;
        if (checkIn) {
          today['check_in'] = now;
        } else {
          today['check_out'] = now;
        }
        _attendance?['today_attendance'] = today;
        _attendance?['latest_location'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'recorded_at': _formatYmdHis(DateTime.now()),
          'source': checkIn ? 'check_in' : 'check_out',
        };
        _locationLabel = label;
        _syncMockDerivedState();
      } else {
        await _dio.post(
            checkIn ? '/attendance/check-in' : '/attendance/check-out',
            data: {
              'status': status,
              'notes': notes,
              'latitude': position.latitude,
              'longitude': position.longitude,
            });
        _locationLabel = label;
        await _refreshAll();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(checkIn
                ? 'Check in berhasil disimpan.'
                : 'Check out berhasil disimpan.')),
      );
    } on DioException catch (error) {
      _showMessage(_readError(error));
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // ignore: unused_element
  Future<bool> _requestTake(
      {required int productId, required int quantity}) async {
    setState(() => _busy = true);
    try {
      if (_mockMode) {
        final available = ((_products?['products'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .firstWhere((item) => item['id_product'] == productId);
        final onhands = ((_products?['onhands'] as List?) ?? [])
            .cast<Map<String, dynamic>>();
        onhands.insert(0, {
          'id_product_onhand': DateTime.now().millisecondsSinceEpoch,
          'id_product': productId,
          'nama_product': available['nama_product'],
          'quantity': quantity,
          'quantity_dikembalikan': 0,
          'remaining_quantity': quantity,
          'take_status': 'pending',
          'take_status_label': 'Pending',
          'return_status': 'belum',
          'return_status_label': 'Belum retur',
          'status_label': 'Menunggu approval',
          'assignment_date': _formatYmd(DateTime.now()),
          'sold_out': false,
          'can_checkout': false,
          'max_return': quantity,
        });
        _syncMockDerivedState();
      } else {
        await _dio.post('/products/take', data: {
          'id_product': productId,
          'quantity': quantity,
        });
        await _refreshAll();
      }
      if (mounted) {
        setState(() => _navigationIndex = 2);
      }
      return true;
    } on DioException catch (error) {
      _showMessage(_readError(error));
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
    return false;
  }

  // ignore: unused_element
  Future<bool> _requestReturn(
      {required int onhandId, required int quantity}) async {
    setState(() => _busy = true);
    try {
      if (_mockMode) {
        final onhand = ((_products?['onhands'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .firstWhere((item) => item['id_product_onhand'] == onhandId);
        onhand['quantity_dikembalikan'] = quantity;
        onhand['pending_return_quantity'] = quantity;
        onhand['return_status'] = 'pending';
        onhand['return_status_label'] = 'Pending retur';
        onhand['status_label'] = 'Menunggu approval retur';
        onhand['can_checkout'] = false;
        _syncMockDerivedState();
      } else {
        await _submitReturnRequest(onhandId: onhandId, quantity: quantity);
        await _refreshAll();
      }
      if (mounted) {
        setState(() => _navigationIndex = 2);
      }
      return true;
    } on DioException catch (error) {
      _showMessage(_readError(error));
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
    return false;
  }

  Future<void> _submitSale({
    required String customerName,
    required String customerPhone,
    required String customerSocial,
    required List<_SaleItemDraft> items,
    required String paymentMethod,
    required bool requireProof,
    int? promoId,
    XFile? proof,
  }) async {
    setState(() => _busy = true);
    try {
      final saleSummary = await _SalesSubmitService.submit(
        dio: _dio,
        mockMode: _mockMode,
        salesPayload: _sales,
        productsPayload: _products,
        queuePayload: _queue,
        customerName: customerName,
        customerPhone: customerPhone,
        customerSocial: customerSocial,
        items: items,
        paymentMethod: paymentMethod,
        requireProof: requireProof,
        promoId: promoId,
        proof: proof,
        onRefreshAll: _refreshAll,
        onSyncMockDerivedState: _syncMockDerivedState,
        isCountedAsOnHand: _isCountedAsOnHand,
        formatYmdHis: _formatYmdHis,
      );
      await _refreshAll(showLoader: false);
      if (mounted) {
        await _showSaleSuccessDialog(saleSummary ?? const <String, dynamic>{});
      }
    } on DioException catch (error) {
      _showMessage(_readError(error));
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _updateOfflineSaleTransaction({
    required Map<String, dynamic> sale,
    required Map<String, dynamic> payload,
  }) async {
    setState(() => _busy = true);
    try {
      final saleId = (sale['id_penjualan_offline'] as num?)?.toInt();
      if (saleId == null) {
        throw Exception('ID transaksi tidak ditemukan.');
      }

      if (_mockMode) {
        final transactionCode = sale['transaction_code']?.toString();
        final sales = _asMapList(_sales?['sales']);
        final index = sales.indexWhere(
          (entry) => entry['transaction_code']?.toString() == transactionCode,
        );
        if (index >= 0) {
          sales[index] = {
            ...sales[index],
            ...payload,
            'transaction_code': transactionCode,
          };
        }
      } else {
        await _dio.put('/offline-sales/$saleId', data: payload);
      }

      await _refreshAll(showLoader: false);
    } on DioException catch (error) {
      _showMessage(_readError(error));
      rethrow;
    } catch (error) {
      _showMessage(error.toString());
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteOfflineSaleTransaction(Map<String, dynamic> sale) async {
    setState(() => _busy = true);
    try {
      final saleId = (sale['id_penjualan_offline'] as num?)?.toInt();
      if (saleId == null) {
        throw Exception('ID transaksi tidak ditemukan.');
      }

      if (_mockMode) {
        final transactionCode = sale['transaction_code']?.toString();
        final sales = _asMapList(_sales?['sales']);
        sales.removeWhere(
          (entry) => entry['transaction_code']?.toString() == transactionCode,
        );
      } else {
        await _dio.delete('/offline-sales/$saleId');
      }

      await _refreshAll(showLoader: false);
    } on DioException catch (error) {
      _showMessage(_readError(error));
      rethrow;
    } catch (error) {
      _showMessage(error.toString());
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<XFile?> _pickProof() async {
    if (_mockMode) {
      return XFile('mock-proof.jpg', name: 'mock-proof.jpg');
    }
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
  }

  Future<void> _showSaleSuccessDialog(Map<String, dynamic> saleSummary) {
    final amount = (saleSummary['total_amount'] as num?)?.toDouble() ??
        (saleSummary['total_harga'] as num?)?.toDouble() ??
        0;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSweetieLavender,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(kSweetieLogoAsset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            const Text(
              'Penjualan Berhasil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _InfoRow(
              label: 'No. Penjualan',
              value: saleSummary['sale_number']?.toString().trim().isNotEmpty ==
                      true
                  ? saleSummary['sale_number'].toString()
                  : (saleSummary['transaction_code']?.toString() ?? '-'),
            ),
            _InfoRow(
              label: 'Tanggal',
              value: saleSummary['created_at']?.toString() ?? '-',
            ),
            _InfoRow(
              label: 'Pemesan',
              value:
                  saleSummary['customer_name']?.toString().trim().isNotEmpty ==
                          true
                      ? saleSummary['customer_name'].toString()
                      : 'Customer umum',
            ),
            _InfoRow(
              label: 'Total',
              value: _currency.format(amount),
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

  // ignore: unused_element
  Future<XFile?> _pickConsignmentProof() async {
    if (_mockMode) {
      return XFile('mock-consignment-proof.jpg',
          name: 'mock-consignment-proof.jpg');
    }
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 82);
  }

  // ignore: unused_element
  Future<bool> _submitConsignment({
    required String placeName,
    required String address,
    required DateTime consignmentDate,
    required List<Map<String, dynamic>> items,
    required XFile proofPhoto,
  }) async {
    setState(() => _busy = true);
    try {
      final position = await _resolveLocation();
      if (_mockMode) {
        final list = ((_consignments?['consignments'] as List?) ?? [])
            .cast<Map<String, dynamic>>();
        list.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch,
          'place_name': placeName,
          'address': address,
          'consignment_date': _formatYmdHis(consignmentDate),
          'submitted_at': _formatYmdHis(DateTime.now()),
          'handover_proof_photo_url': null,
          'items': items
              .map((item) => {
                    'id': DateTime.now().millisecondsSinceEpoch +
                        (item['product_onhand_id'] as int),
                    'product_onhand_id': item['product_onhand_id'],
                    'product_name': item['product_name'],
                    'pickup_batch_code': item['pickup_batch_code'],
                    'quantity': item['quantity'],
                    'sold_quantity': 0,
                    'returned_quantity': 0,
                    'status': 'dititipkan',
                    'status_notes': null,
                  })
              .toList(),
        });
      } else {
        final form = FormData();
        form.fields
          ..add(MapEntry('place_name', placeName))
          ..add(MapEntry('address', address))
          ..add(MapEntry('consignment_date', _formatYmd(consignmentDate)))
          ..add(MapEntry('latitude', '${position.latitude}'))
          ..add(MapEntry('longitude', '${position.longitude}'));
        for (var index = 0; index < items.length; index++) {
          form.fields.add(MapEntry('items[$index][product_onhand_id]',
              '${items[index]['product_onhand_id']}'));
          form.fields.add(MapEntry(
              'items[$index][quantity]', '${items[index]['quantity']}'));
        }
        form.files.add(MapEntry(
          'handover_proof_photo',
          await MultipartFile.fromFile(proofPhoto.path,
              filename: proofPhoto.name),
        ));
        await _dio.post('/consignments', data: form);
      }
      await _refreshAll();
      if (mounted) {
        setState(() => _navigationIndex = 2);
      }
      return true;
    } on DioException catch (error) {
      _showMessage(_readError(error));
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
    return false;
  }

  // ignore: unused_element
  Future<bool> _updateConsignmentItem({
    required int itemId,
    required int soldQuantity,
    required int returnedQuantity,
    String? statusNotes,
  }) async {
    setState(() => _busy = true);
    try {
      if (_mockMode) {
        final consignments = ((_consignments?['consignments'] as List?) ?? [])
            .cast<Map<String, dynamic>>();
        for (final consignment in consignments) {
          final items = ((consignment['items'] as List?) ?? [])
              .cast<Map<String, dynamic>>();
          final index = items.indexWhere(
            (item) => _asInt(item['id'], fallback: -1) == itemId,
          );
          if (index < 0) {
            continue;
          }

          final quantity = _asInt(items[index]['quantity']);
          final resolvedStatus = soldQuantity >= quantity
              ? 'terjual'
              : returnedQuantity >= quantity
                  ? 'dikembalikan'
                  : soldQuantity > 0
                      ? 'terjual'
                      : returnedQuantity > 0
                          ? 'dikembalikan'
                          : 'dititipkan';

          items[index] = {
            ...items[index],
            'sold_quantity': soldQuantity,
            'returned_quantity': returnedQuantity,
            'status': resolvedStatus,
            'status_notes': statusNotes?.trim().isEmpty == true
                ? null
                : statusNotes?.trim(),
          };
          break;
        }
        _syncMockDerivedState();
      } else {
        await _dio.put('/consignment-items/$itemId', data: {
          'sold_quantity': soldQuantity,
          'returned_quantity': returnedQuantity,
          'status_notes':
              statusNotes?.trim().isEmpty == true ? null : statusNotes?.trim(),
        });
        await _refreshAll();
      }
      if (mounted) {
        setState(() => _navigationIndex = 2);
      }
      return true;
    } on DioException catch (error) {
      _showMessage(_readError(error));
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
    return false;
  }

  Future<void> _submitReturnRequest({
    required int onhandId,
    required int quantity,
  }) async {
    final payload = {'quantity_dikembalikan': quantity};
    await _dio.post('/products/onhand/$onhandId/return', data: payload);
  }

  Future<Map<String, dynamic>?> _lookupCustomerByPhone(String phone) async {
    final normalized = _normalizePhone(phone);
    if (normalized.isEmpty) {
      return null;
    }

    final sales =
        ((_sales?['sales'] as List?) ?? []).cast<Map<String, dynamic>>();
    for (final sale in sales) {
      final salePhone = _normalizePhone(
        sale['no_telp']?.toString() ??
            sale['customer_no_telp']?.toString() ??
            sale['phone']?.toString(),
      );
      if (salePhone == normalized) {
        return _normalizeCustomerPayload({
          'nama':
              sale['nama_customer'] ?? sale['customer_nama'] ?? sale['nama'],
          'no_telp': salePhone,
          'tiktok_instagram': sale['tiktok_instagram'] ??
              sale['customer_tiktok_instagram'] ??
              sale['social_media'],
        });
      }
    }

    if (_mockMode) {
      return null;
    }

    final response =
        await _dio.get('/offline-sales/customer', queryParameters: {
      'phone': normalized,
    });

    final responseData = response.data;
    final customer = responseData is Map<String, dynamic>
        ? (responseData['customer'] is Map<String, dynamic>
            ? responseData['customer']
            : responseData)
        : null;

    return customer is Map<String, dynamic>
        ? _normalizeCustomerPayload(customer)
        : null;
  }

  String _normalizePhone(String? phone) {
    return (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '').trim();
  }

  Map<String, dynamic> _normalizeCustomerPayload(
      Map<String, dynamic> customer) {
    return {
      'nama': customer['nama'] ??
          customer['nama_customer'] ??
          customer['customer_nama'],
      'no_telp': _normalizePhone(
        customer['no_telp']?.toString() ??
            customer['customer_no_telp']?.toString() ??
            customer['phone']?.toString(),
      ),
      'tiktok_instagram': customer['tiktok_instagram'] ??
          customer['customer_tiktok_instagram'] ??
          customer['social_media'] ??
          customer['instagram'] ??
          customer['tiktok'],
    };
  }

  Future<void> _logout() async {
    try {
      if (!_mockMode) {
        await _dio.post('/auth/logout');
      }
    } catch (_) {
      // Ignore server logout failure.
    }
    await _clearSession();
    if (mounted) {
      setState(() {
        _loading = false;
        _navigationIndex = 0;
      });
    }
  }

  Future<void> _showNotificationsSheet(
    List<Map<String, dynamic>> notifications, {
    Map<String, dynamic>? initialNotification,
  }) async {
    await NotificationScheduler.instance.markNotificationsSeen(notifications);
    if (mounted) {
      setState(() => _unreadNotificationCount = 0);
    }
    if (!mounted) {
      return;
    }

    return showMaterialModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(
        notifications: notifications,
        initialNotification: initialNotification,
      ),
    );
  }

  Future<void> _showQueueSheet() async {
    final queueItems = _asMapList(_queue?['items']);
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OwnerStandalonePage(
          title: 'Antrian Penjualan',
          child: _QueuePage(
            queueItems: queueItems,
            onCloseQueue: _closeQueueItem,
          ),
        ),
      ),
    );
  }

  Future<void> _closeQueueItem(String saleNumber) async {
    setState(() => _busy = true);
    try {
      if (_mockMode) {
        final items = _asMapList(_queue?['items']);
        items.removeWhere((item) => item['sale_number'] == saleNumber);
        _queue = {'items': items};
      } else {
        await _dio.post('/queue/close', data: {'sale_number': saleNumber});
      }

      await _refreshAll(showLoader: false);
    } on DioException catch (error) {
      _showMessage(_readError(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _refreshAttendanceForDate(DateTime date) async {
    if (_mockMode) {
      setState(() {
        _attendance = {
          ...?_attendance,
          'selected_date': _formatYmd(date),
        };
      });
      return;
    }

    setState(() => _busy = true);
    try {
      final response = await _dio.get(
        '/attendance',
        queryParameters: {'date': _formatYmd(date)},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _attendance = _asMap(response.data);
      });
    } on DioException catch (error) {
      _showMessage(_readError(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<Map<String, dynamic>> _fetchOwnerModule(String module) async {
    if (_mockMode) {
      return _mockOwnerModule(module);
    }

    final response = await _dio.get('/owner/modules/$module');
    return _asMap(response.data);
  }

  Future<void> _storeOwnerModule(
    String module,
    Map<String, dynamic> payload,
  ) async {
    if (_mockMode) return;
    await _dio.post(
      '/owner/modules/$module',
      data: await _buildOwnerModuleRequestData(payload),
    );
  }

  Future<void> _updateOwnerModule(
    String module,
    String record,
    Map<String, dynamic> payload,
  ) async {
    if (_mockMode) return;
    final requestData = await _buildOwnerModuleRequestData(payload);
    if (requestData is FormData) {
      requestData.fields.add(const MapEntry('_method', 'PUT'));
      await _dio.post(
        '/owner/modules/$module/$record',
        data: requestData,
      );
      return;
    }

    await _dio.put(
      '/owner/modules/$module/$record',
      data: requestData,
    );
  }

  Future<void> _deleteOwnerModule(String module, String record) async {
    if (_mockMode) return;
    await _dio.delete('/owner/modules/$module/$record');
  }

  Future<dynamic> _buildOwnerModuleRequestData(
      Map<String, dynamic> payload) async {
    final hasFile = _payloadContainsFile(payload);
    if (!hasFile) {
      return payload;
    }

    final form = FormData();
    await _appendFormDataEntries(form, payload);
    return form;
  }

  bool _payloadContainsFile(dynamic value) {
    if (value is XFile) return true;
    if (value is Map) {
      return value.values.any(_payloadContainsFile);
    }
    if (value is Iterable) {
      return value.any(_payloadContainsFile);
    }
    return false;
  }

  Future<void> _appendFormDataEntries(
    FormData form,
    dynamic value, {
    String? prefix,
  }) async {
    if (value == null) return;

    if (value is XFile) {
      if (prefix == null) return;
      form.files.add(
        MapEntry(
          prefix,
          await MultipartFile.fromFile(value.path, filename: value.name),
        ),
      );
      return;
    }

    if (value is Map<String, dynamic>) {
      for (final entry in value.entries) {
        final nextPrefix = prefix == null ? entry.key : '$prefix[${entry.key}]';
        await _appendFormDataEntries(form, entry.value, prefix: nextPrefix);
      }
      return;
    }

    if (value is Iterable) {
      var index = 0;
      for (final item in value) {
        final nextPrefix = '$prefix[$index]';
        await _appendFormDataEntries(form, item, prefix: nextPrefix);
        index += 1;
      }
      return;
    }

    if (prefix == null) return;
    if (value is bool) {
      form.fields.add(MapEntry(prefix, value ? '1' : '0'));
      return;
    }

    form.fields.add(MapEntry(prefix, '$value'));
  }

  Future<void> _openOwnerSalesShortcut() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OwnerStandalonePage(
          title: 'Kasir Owner',
          child: SmoothiesSalesPageModule(
            sales: _asMapList(_sales?['sales']),
            products: _asMapList(_sales?['products']),
            promos: _asMapList(_sales?['promos']),
            extraToppings: _asMapList(_sales?['extra_toppings']),
            sops: _asMapList(_sales?['sops']),
            isSmoothiesSweetie:
                (_sales?['is_smoothies_sweetie'] as bool?) ?? false,
            qrisImageUrl: _sales?['qris_image_url']?.toString(),
            busy: _busy,
            currency: _currency,
            dateTime: _dateTime,
            onPickProof: _pickProof,
            onSubmit: ({
              required customerName,
              required customerPhone,
              required customerSocial,
              required items,
              required paymentMethod,
              required requireProof,
              promoId,
              proof,
            }) =>
                _submitSale(
              customerName: customerName,
              customerPhone: customerPhone,
              customerSocial: customerSocial,
              items: items.cast<_SaleItemDraft>(),
              paymentMethod: paymentMethod,
              requireProof: requireProof,
              promoId: promoId,
              proof: proof,
            ),
            onLookupCustomer: _lookupCustomerByPhone,
            mockMode: _mockMode,
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _readError(DioException error) {
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
    return error.message ?? 'Terjadi kesalahan.';
  }

  String _formatYmd(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _formatYmdHis(DateTime value) =>
      '${_formatYmd(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_token == null) {
      return _LoginPage(
        usernameController: _usernameController,
        passwordController: _passwordController,
        loggingIn: _loggingIn,
        obscurePassword: _obscureLoginPassword,
        error: _error,
        onTogglePasswordVisibility: () {
          setState(() => _obscureLoginPassword = !_obscureLoginPassword);
        },
        onLogin: _login,
      );
    }

    final stats = _asMap(_dashboard?['stats']);
    final todayAttendance = _asMap(_attendance?['today_attendance']);
    final sales = _asMapList(_sales?['sales']);
    final salesProducts = _asMapList(_sales?['products']);
    final promos = _asMapList(_sales?['promos']);
    final salesExtraToppings = _asMapList(_sales?['extra_toppings']);
    final salesSops = _asMapList(_sales?['sops']);
    final isSmoothiesSweetie =
        (_sales?['is_smoothies_sweetie'] as bool?) ?? false;
    final salesQrisImageUrl = _sales?['qris_image_url']?.toString();
    final knowledge = _asMapList(_knowledge?['products']);
    final notifications = _asMapList(_notifications?['notifications']);
    final recentAttendances = _asMapList(_attendance?['recent_attendances']);
    final employeeAttendances =
        _asMapList(_attendance?['employee_attendances']);
    final role = (_me?['role']?.toString() ?? '');
    final isOwner = role == 'owner';

    final employeeAttendancePage = _AttendancePage(
      me: _me ?? const {},
      todayAttendance: todayAttendance,
      recentAttendances: recentAttendances,
      employeeAttendances: employeeAttendances,
      selectedDate: _attendance?['selected_date']?.toString(),
      latestLocation: _attendance?['latest_location'] as Map<String, dynamic>?,
      manualLocationLabel: _locationLabel,
      busy: _busy,
      onFilterDate: _refreshAttendanceForDate,
      onSubmitAttendance: _submitAttendance,
    );

    final salesPage = SmoothiesSalesPageModule(
      sales: sales,
      products: salesProducts,
      promos: promos,
      extraToppings: salesExtraToppings,
      sops: salesSops,
      isSmoothiesSweetie: isSmoothiesSweetie,
      qrisImageUrl: salesQrisImageUrl,
      busy: _busy,
      currency: _currency,
      dateTime: _dateTime,
      onPickProof: _pickProof,
      onSubmit: ({
        required customerName,
        required customerPhone,
        required customerSocial,
        required items,
        required paymentMethod,
        required requireProof,
        promoId,
        proof,
      }) =>
          _submitSale(
        customerName: customerName,
        customerPhone: customerPhone,
        customerSocial: customerSocial,
        items: items.cast<_SaleItemDraft>(),
        paymentMethod: paymentMethod,
        requireProof: requireProof,
        promoId: promoId,
        proof: proof,
      ),
      onLookupCustomer: _lookupCustomerByPhone,
      mockMode: _mockMode,
    );

    final knowledgePage = _KnowledgePage(
      products: knowledge,
      loading: _knowledge == null && _busy,
    );

    final ownerPages = <Widget>[
      _DashboardPage(
        me: _me ?? const {},
        dashboard: _dashboard ?? const {},
        stats: stats,
        todayAttendance: todayAttendance,
        recentAttendances: recentAttendances,
        sales: sales,
        currency: _currency,
        isOwner: true,
        onNavigate: (index) => setState(() => _navigationIndex = index),
      ),
      _OwnerCategoryPage(
        title: 'Stock and Inventory',
        subtitle: 'Kelola product, HPP, raw material, dan extra topping.',
        modules: _ownerStockModules,
        onOpenModule: (module) => _openOwnerModulePage(
          module: module,
          employeeAttendancePage: employeeAttendancePage,
          knowledgePage: knowledgePage,
        ),
      ),
      _OwnerCategoryPage(
        title: 'Karyawan',
        subtitle: 'Pantau notifikasi, absensi karyawan, dan product knowledge.',
        modules: _ownerEmployeeModules,
        onOpenModule: (module) => _openOwnerModulePage(
          module: module,
          employeeAttendancePage: employeeAttendancePage,
          knowledgePage: knowledgePage,
        ),
      ),
      _OwnerCategoryPage(
        title: 'Finance',
        subtitle:
            'Kelola penjualan offline, pengeluaran, piutang, hutang, dan penjualan online.',
        modules: _ownerFinanceModules,
        onOpenModule: (module) => _openOwnerModulePage(
          module: module,
          employeeAttendancePage: employeeAttendancePage,
          knowledgePage: knowledgePage,
        ),
      ),
      _OwnerCategoryPage(
        title: 'Pengaturan',
        subtitle: 'Atur target penjualan, promo, users, customers, dan SOP.',
        modules: _ownerSettingModules,
        onOpenModule: (module) => _openOwnerModulePage(
          module: module,
          employeeAttendancePage: employeeAttendancePage,
          knowledgePage: knowledgePage,
        ),
      ),
    ];

    final employeePages = <Widget>[
      employeeAttendancePage,
      salesPage,
      knowledgePage,
    ];

    final pages = isOwner ? ownerPages : employeePages;
    final destinations = isOwner ? _ownerDestinations : _employeeDestinations;
    final safeNavigationIndex =
        _navigationIndex.clamp(0, max(pages.length - 1, 0)).toInt();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5EAFB), Color(0xFFFDF8FE), Color(0xFFF4F0FC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBanner(
                title: _pageTitle(safeNavigationIndex),
                subtitle: _pageSubtitle(safeNavigationIndex),
                me: _me ?? const {},
                mockMode: _mockMode,
                busy: _busy,
                accent: _pageAccent(safeNavigationIndex),
                icon: _pageIcon(safeNavigationIndex),
                compact: true,
                onRefresh: () => _refreshAll(showLoader: true),
                onQueue: _showQueueSheet,
                onNotifications: () => _showNotificationsSheet(notifications),
                notificationCount: _unreadNotificationCount,
                showKasirShortcut: isOwner,
                onKasir: _openOwnerSalesShortcut,
                onLogout: _logout,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offset = Tween<Offset>(
                            begin: const Offset(0.06, 0), end: Offset.zero)
                        .animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(safeNavigationIndex),
                    child: pages[safeNavigationIndex],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x220F0A05),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NavigationBar(
                selectedIndex: safeNavigationIndex,
                onDestinationSelected: (index) =>
                    setState(() => _navigationIndex = index),
                destinations: destinations,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _pageTitle(int index) {
    final isOwner = (_me?['role']?.toString() ?? '') == 'owner';
    if (isOwner) {
      if (index == 1) return 'Stock and Inventory';
      if (index == 2) return 'Karyawan';
      if (index == 3) return 'Finance';
      if (index == 4) return 'Pengaturan';
      return 'Dashboard Owner';
    }
    if (index == 1) return 'Kasir';
    if (index == 2) {
      return 'Product Knowledge';
    }
    return 'Absensi';
  }

  String _pageSubtitle(int index) {
    final isOwner = (_me?['role']?.toString() ?? '') == 'owner';
    if (isOwner) {
      if (index == 1) {
        return 'Menu Product, HPP, Raw Material, dan Extra Topping owner.';
      }
      if (index == 2) {
        return 'Notifikasi, riwayat absensi karyawan, dan panduan product.';
      }
      if (index == 3) {
        return 'Pengeluaran, penjualan offline, piutang, hutang, dan penjualan online.';
      }
      if (index == 4) {
        return 'Target penjualan, promo, users, customers, dan SOP.';
      }
      return 'Ringkasan keuntungan owner tanpa chart, mengikuti dashboard website.';
    }
    if (index == 1) {
      return 'Input penjualan offline kasir dengan flow QRIS dan antrian seperti website.';
    }
    if (index == 2) {
      return 'Ringkasan menu, bahan, dan selling points untuk bantu pelayanan di booth.';
    }
    return 'Check in, check out, dan kirim lokasi operasional dengan cepat.';
  }

  Color _pageAccent(int index) {
    final isOwner = (_me?['role']?.toString() ?? '') == 'owner';
    if (isOwner) {
      if (index == 1) return const Color(0xFF6F90D8);
      if (index == 2) return kSweetiePink;
      if (index == 3) return kSweetiePurple;
      if (index == 4) return const Color(0xFF8C8AE8);
      return const Color(0xFFA66AE2);
    }
    if (index == 1) return kSweetiePurple;
    if (index == 2) return const Color(0xFF8C8AE8);
    return kSweetiePink;
  }

  IconData _pageIcon(int index) {
    final isOwner = (_me?['role']?.toString() ?? '') == 'owner';
    if (isOwner) {
      if (index == 1) return Icons.inventory_2_rounded;
      if (index == 2) return Icons.groups_rounded;
      if (index == 3) return Icons.account_balance_wallet_rounded;
      if (index == 4) return Icons.settings_rounded;
      return Icons.dashboard_rounded;
    }
    if (index == 1) return Icons.point_of_sale_rounded;
    if (index == 2) return Icons.auto_stories_rounded;
    return Icons.fingerprint_rounded;
  }
}

class _LoginPage extends StatelessWidget {
  const _LoginPage({
    required this.usernameController,
    required this.passwordController,
    required this.loggingIn,
    required this.obscurePassword,
    required this.error,
    required this.onTogglePasswordVisibility,
    required this.onLogin,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool loggingIn;
  final bool obscurePassword;
  final String? error;
  final VoidCallback onTogglePasswordVisibility;
  final Future<void> Function() onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE783BF),
                  Color(0xFF9E7AE6),
                  Color(0xFFF4D8F0)
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    backgroundBlendMode: BlendMode.srcOver,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.15, 0.5, 0.85],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _LoginLinesPainter()),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F0F0A05),
                              blurRadius: 28,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            kSweetieLogoAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Card(
                        color: Colors.white.withValues(alpha: 0.94),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smoothies Sweetie',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Login owner dan karyawan untuk akses kasir, stok, dan modul operasional.',
                                style: TextStyle(
                                  color: kSweetieInk.withValues(alpha: 0.72),
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username owner / karyawan',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    onPressed: onTogglePasswordVisibility,
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: kSweetiePurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  onPressed: loggingIn ? null : onLogin,
                                  child: loggingIn
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Masuk'),
                                ),
                              ),
                              if (error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final segments = [
      [
        Offset(size.width * 0.05, size.height * 0.18),
        Offset(size.width * 0.95, size.height * 0.04)
      ],
      [
        Offset(size.width * 0.02, size.height * 0.42),
        Offset(size.width * 0.82, size.height * 0.22)
      ],
      [
        Offset(size.width * 0.18, size.height * 0.88),
        Offset(size.width * 0.96, size.height * 0.62)
      ],
      [
        Offset(size.width * 0.0, size.height * 0.7),
        Offset(size.width * 0.64, size.height * 0.5)
      ],
    ];

    for (final segment in segments) {
      canvas.drawLine(segment.first, segment.last, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopBanner extends StatelessWidget {
  const _TopBanner({
    required this.title,
    required this.subtitle,
    required this.me,
    required this.mockMode,
    required this.busy,
    required this.accent,
    required this.icon,
    required this.compact,
    required this.onRefresh,
    required this.onQueue,
    required this.onNotifications,
    required this.notificationCount,
    required this.showKasirShortcut,
    required this.onKasir,
    required this.onLogout,
  });

  final String title;
  final String subtitle;
  final Map<String, dynamic> me;
  final bool mockMode;
  final bool busy;
  final Color accent;
  final IconData icon;
  final bool compact;
  final VoidCallback onRefresh;
  final VoidCallback onQueue;
  final VoidCallback onNotifications;
  final int notificationCount;
  final bool showKasirShortcut;
  final VoidCallback onKasir;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
        child: Row(
          children: [
            _TopActionButton(
              tooltip: 'Antrian Penjualan',
              onPressed: onQueue,
              child: const Icon(Icons.format_list_numbered_rounded),
            ),
            const Spacer(),
            if (showKasirShortcut)
              _TopActionButton(
                tooltip: 'Kasir',
                onPressed: onKasir,
                child: const Icon(Icons.point_of_sale_rounded),
              ),
            if (showKasirShortcut) const Spacer(),
            badges.Badge(
              position: badges.BadgePosition.topEnd(top: -8, end: -8),
              showBadge: notificationCount > 0,
              badgeStyle: const badges.BadgeStyle(
                badgeColor: kSweetiePink,
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
              badgeContent: Text(
                '$notificationCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _TopActionButton(
                tooltip: 'Notifications',
                onPressed: onNotifications,
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
            const SizedBox(width: 10),
            _TopActionButton(
              tooltip: busy ? 'Memuat...' : 'Sync Data',
              onPressed: busy ? null : onRefresh,
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
            ),
            const SizedBox(width: 10),
            _TopActionButton(
              tooltip: 'Logout',
              onPressed: () => onLogout(),
              child: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.97),
              Color.lerp(accent, Colors.white, 0.84) ?? Colors.white,
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F0A05),
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset(kSweetieLogoAsset, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            if (mockMode)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Text('Demo Mode'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(subtitle),
                        const SizedBox(height: 6),
                        Text('Aktif sebagai ',
                            style: const TextStyle(color: Color(0xFF72552B))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        onPressed: onQueue,
                        icon: const Icon(Icons.format_list_numbered_rounded),
                        tooltip: 'Antrian Penjualan',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                      if (showKasirShortcut) ...[
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: onKasir,
                          icon: const Icon(Icons.point_of_sale_rounded),
                          tooltip: 'Kasir',
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: busy ? null : onRefresh,
                        icon: busy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded),
                        tooltip: 'Refresh',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout),
                        tooltip: 'Logout',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _SalesQrSheet extends StatelessWidget {
  const _SalesQrSheet({
    required this.qrUrl,
    required this.qrName,
  });

  final String qrUrl;
  final String? qrName;

  @override
  Widget build(BuildContext context) {
    return _AnimatedSheetScaffold(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F1E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 16),
                const _SheetHeader(
                  heroTag: 'sales-qr-sheet',
                  accent: Color(0xFF2C8C82),
                  icon: Icons.qr_code_2_rounded,
                  title: 'QR Code Penjualan',
                  subtitle:
                      'Tampilkan QR code yang diunggah dari backend untuk kebutuhan closing.',
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: qrUrl.isEmpty
                      ? const Text(
                          'QR code belum diunggah oleh superadmin.',
                          textAlign: TextAlign.center,
                        )
                      : Column(
                          children: [
                            GestureDetector(
                              onTap: () => showGeneralDialog<void>(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: 'Tutup preview QR',
                                barrierColor:
                                    Colors.black.withValues(alpha: 0.9),
                                transitionDuration:
                                    const Duration(milliseconds: 240),
                                pageBuilder: (_, __, ___) =>
                                    _QrImagePreviewDialog(
                                  qrUrl: qrUrl,
                                  qrName: qrName,
                                ),
                                transitionBuilder:
                                    (context, animation, secondary, child) {
                                  final curved = CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                    reverseCurve: Curves.easeInCubic,
                                  );

                                  return FadeTransition(
                                    opacity: curved,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.96,
                                        end: 1,
                                      ).animate(curved),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Hero(
                                  tag: 'sales-qr-image-preview',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: CachedNetworkImage(
                                      imageUrl: qrUrl,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: 280,
                                      placeholder: (_, __) => const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(24),
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Text(
                                          'QR code gagal dimuat. Coba sync data lagi.',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              qrName ?? 'QR Code Sales',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap gambar untuk memperbesar.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6F665F),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _QueueSheet extends StatelessWidget {
  const _QueueSheet({
    required this.queueItems,
    required this.onCloseQueue,
  });

  final List<Map<String, dynamic>> queueItems;
  final Future<void> Function(String saleNumber) onCloseQueue;

  @override
  Widget build(BuildContext context) {
    return _AnimatedSheetScaffold(
      child: SafeArea(
        top: false,
        child: Material(
          color: const Color(0xFFFDF8FE),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const _SheetHeader(
                heroTag: 'queue-sheet',
                accent: kSweetiePurple,
                icon: Icons.format_list_numbered_rounded,
                title: 'Antrian Penjualan',
                subtitle:
                    'Nomor penjualan, nama pemesan, dan detail produk aktif.',
              ),
              Flexible(
                child: queueItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 28),
                        child: Text('Tidak ada antrian aktif.'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: queueItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = queueItems[index];
                          return _QueueSaleCard(
                            item: item,
                            onClose: () async {
                              await onCloseQueue(
                                item['sale_number']?.toString() ?? '',
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueuePage extends StatelessWidget {
  const _QueuePage({
    required this.queueItems,
    required this.onCloseQueue,
  });

  final List<Map<String, dynamic>> queueItems;
  final Future<void> Function(String saleNumber) onCloseQueue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: const Color(0xFFFDF8FE),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _SheetHeader(
              heroTag: 'queue-page',
              accent: kSweetiePurple,
              icon: Icons.format_list_numbered_rounded,
              title: 'Antrian Penjualan',
              subtitle:
                  'Nomor penjualan, nama customer, quantity, dan extra topping aktif.',
            ),
            Expanded(
              child: queueItems.isEmpty
                  ? const Center(child: Text('Tidak ada antrian aktif.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      itemCount: queueItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = queueItems[index];
                        return _QueueSaleCard(
                          item: item,
                          onClose: () async {
                            await onCloseQueue(
                              item['sale_number']?.toString() ?? '',
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueSaleCard extends StatelessWidget {
  const _QueueSaleCard({
    required this.item,
    required this.onClose,
  });

  final Map<String, dynamic> item;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    final details =
        ((item['details'] as List?) ?? []).cast<Map<String, dynamic>>();
    final customerName =
        item['customer_name']?.toString().trim().isNotEmpty == true
            ? item['customer_name'].toString()
            : 'Customer umum';
    final saleNumber = _formatQueueSaleNumber(
      rawSaleNumber: item['sale_number']?.toString(),
      createdAt: item['created_at']?.toString(),
      queueNumber: (item['queue_number'] as num?)?.toInt(),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEADCF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x148E79D6),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EDFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    saleNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: kSweetieInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _QueueElapsedBadge(createdAt: item['created_at']?.toString()),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9FD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1E3F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nama Pemesan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B799B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Detail Order',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF776887),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(details.length, (index) {
            final detail = details[index];
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == details.length - 1 ? 0 : 10),
              child: _QueueDetailTile(
                index: index + 1,
                detail: detail,
              ),
            );
          }),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Selesaikan antrian'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueElapsedBadge extends StatelessWidget {
  const _QueueElapsedBadge({required this.createdAt});

  final String? createdAt;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: Stream<DateTime>.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final startedAt = _DashboardPage._parseFlexibleDate(createdAt);
        final now = snapshot.data ?? DateTime.now();
        final elapsed =
            startedAt == null ? Duration.zero : now.difference(startedAt);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF3D8E6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Waktu berjalan',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA06B85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatElapsedDuration(elapsed),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: kSweetieInk,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QueueDetailTile extends StatelessWidget {
  const _QueueDetailTile({
    required this.index,
    required this.detail,
  });

  final int index;
  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final rawName = detail['nama_product']?.toString().trim() ?? '-';
    final variantName = detail['product_variant_name']?.toString().trim();
    final displayVariant = variantName != null && variantName.isNotEmpty
        ? variantName
        : _extractVariantName(rawName);
    final productName = _extractBaseProductName(rawName);
    final quantity = (detail['quantity'] as num?)?.toInt() ?? 0;
    final sugarLevel = detail['sugar_level']?.toString().trim();
    final toppings = ((detail['extra_toppings'] as List?) ?? [])
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE2F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEDFF9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: kSweetieInk,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kSweetieInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      quantity > 0 ? 'x$quantity' : 'x0',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7C54C6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (displayVariant != null && displayVariant.isNotEmpty)
                      _QueueBadge(
                        label: displayVariant,
                        backgroundColor: const Color(0xFFEAF6F0),
                        textColor: const Color(0xFF3A7B5D),
                      ),
                    _QueueBadge(
                      label: sugarLevel != null && sugarLevel.isNotEmpty
                          ? 'Sugar: $sugarLevel'
                          : 'Sugar: Normal',
                      backgroundColor: const Color(0xFFFFF0F7),
                      textColor: const Color(0xFFB84E88),
                    ),
                    if (toppings.isEmpty)
                      const _QueueBadge(
                        label: 'Tidak Pakai Topping',
                        backgroundColor: Color(0xFFF4F1F7),
                        textColor: Color(0xFF8E7E9D),
                      ),
                  ],
                ),
                if (toppings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: toppings
                        .map(
                          (topping) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1E6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              topping,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9B6540),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Tanpa topping tambahan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9A8EA5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _extractBaseProductName(String rawName) {
  final parts = rawName.split(' - ');
  return parts.isEmpty ? rawName : parts.first.trim();
}

String? _extractVariantName(String rawName) {
  final parts = rawName.split(' - ');
  if (parts.length < 2) {
    return null;
  }
  final variant = parts.sublist(1).join(' - ').trim();
  return variant.isEmpty ? null : variant;
}

class _QueueBadge extends StatelessWidget {
  const _QueueBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

String _formatQueueSaleNumber({
  required String? rawSaleNumber,
  required String? createdAt,
  required int? queueNumber,
}) {
  final normalized = rawSaleNumber?.trim() ?? '';
  if (normalized.isNotEmpty) {
    final parts = normalized.split(' - ');
    if (parts.length == 2) {
      final dateParts = parts.first.split('/');
      if (dateParts.length == 3) {
        final day = dateParts[0].padLeft(2, '0');
        final month = dateParts[1].padLeft(2, '0');
        final year = dateParts[2].length >= 2
            ? dateParts[2].substring(dateParts[2].length - 2)
            : dateParts[2].padLeft(2, '0');
        return '$day/$month/$year - ${parts[1].trim()}';
      }
    }
    return normalized;
  }

  final parsedCreatedAt = _DashboardPage._parseFlexibleDate(createdAt);
  if (parsedCreatedAt != null && queueNumber != null) {
    final day = parsedCreatedAt.day.toString().padLeft(2, '0');
    final month = parsedCreatedAt.month.toString().padLeft(2, '0');
    final year = (parsedCreatedAt.year % 100).toString().padLeft(2, '0');
    return '$day/$month/$year - $queueNumber';
  }

  return '-';
}

String _formatElapsedDuration(Duration duration) {
  final safeDuration = duration.isNegative ? Duration.zero : duration;
  final hours = safeDuration.inHours.toString().padLeft(2, '0');
  final minutes = (safeDuration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (safeDuration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

class _QrImagePreviewDialog extends StatelessWidget {
  const _QrImagePreviewDialog({
    required this.qrUrl,
    required this.qrName,
  });

  final String qrUrl;
  final String? qrName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  qrName ?? 'QR Code Sales',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.72,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Hero(
                      tag: 'sales-qr-image-preview',
                      child: Material(
                        color: Colors.transparent,
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: CachedNetworkImage(
                            imageUrl: qrUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const SizedBox(
                              height: 240,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (_, __, ___) => const SizedBox(
                              height: 240,
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'QR code gagal dimuat.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cubut untuk zoom dan geser gambar.',
                  style: TextStyle(
                    color: Color(0xFFD6D6D6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet({
    required this.notifications,
    this.initialNotification,
  });

  final List<Map<String, dynamic>> notifications;
  final Map<String, dynamic>? initialNotification;

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _openedInitialDetail = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_openedInitialDetail || widget.initialNotification == null) {
      return;
    }

    _openedInitialDetail = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showMaterialModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            _NotificationDetailSheet(notification: widget.initialNotification!),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimatedSheetScaffold(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F1E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 16),
                const _SheetHeader(
                  heroTag: 'notifications-sheet',
                  accent: Color(0xFFC05D3B),
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  subtitle:
                      'Judul dan ringkasan notifikasi terbaru untuk owner dan karyawan.',
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: widget.notifications.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child:
                              Text('Belum ada notifikasi untuk ditampilkan.'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: widget.notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = widget.notifications[index];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => showMaterialModalBottomSheet<void>(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _NotificationDetailSheet(
                                      notification: item),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF6E1D8),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: const Icon(
                                              Icons.notifications_none_rounded,
                                              color: Color(0xFFC05D3B),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['title']?.toString() ??
                                                      '-',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  item['excerpt']?.toString() ??
                                                      item['body']
                                                          ?.toString() ??
                                                      '-',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF6F665F),
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item['published_at']?.toString() ?? '-',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF8B7A6C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({
    required this.notification,
  });

  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context) {
    return _AnimatedSheetScaffold(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F1E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 16),
                const _SheetHeader(
                  heroTag: 'notifications-detail-sheet',
                  accent: Color(0xFFC05D3B),
                  icon: Icons.mark_email_read_outlined,
                  title: 'Detail Notifikasi',
                  subtitle: 'Isi lengkap notifikasi dari superadmin.',
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title']?.toString() ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification['published_at']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B7A6C),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        notification['body']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF2B2117),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.96),
        elevation: 2,
        shadowColor: const Color(0x160F0A05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.me,
    required this.dashboard,
    required this.stats,
    required this.todayAttendance,
    required this.recentAttendances,
    required this.sales,
    required this.currency,
    required this.isOwner,
    required this.onNavigate,
  });

  final Map<String, dynamic> me;
  final Map<String, dynamic> dashboard;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> todayAttendance;
  final List<Map<String, dynamic>> recentAttendances;
  final List<Map<String, dynamic>> sales;
  final NumberFormat currency;
  final bool isOwner;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    if (isOwner) {
      return _InventoryPage._buildOwnerDashboardView(
        context,
        dashboard: dashboard,
        currency: currency,
      );
    }

    final now = DateTime.now();
    final periodLabel = _capitalizeMonthYear(
      DateFormat('MMMM yyyy', 'id_ID').format(now),
    );
    final targetSummary =
        dashboard['target_summary'] as Map<String, dynamic>? ?? {};
    final targetSales =
        sales.where(_MarketingRootState._countsTowardTarget).toList();
    final monthAttendances = recentAttendances.where((item) {
      final date = _parseFlexibleDate(item['attendance_date']?.toString());
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();
    final monthSales = sales.where((sale) {
      final date = _parseFlexibleDate(sale['created_at']?.toString());
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();
    final monthTargetSales = targetSales.where((sale) {
      final date = _parseFlexibleDate(sale['created_at']?.toString());
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();

    final totalAttendance = monthAttendances.where((item) {
      final status = item['status']?.toString().toLowerCase() ?? '';
      return status == 'hadir' || status == 'terlambat';
    }).length;
    final totalRevenue = monthSales.fold<double>(
      0,
      (sum, sale) => sum + ((sale['total_harga'] as num?)?.toDouble() ?? 0),
    );
    final totalWorkingMinutes = monthAttendances.fold<int>(
      0,
      (sum, item) =>
          sum +
          _calculateWorkedMinutes(
            item['attendance_date']?.toString(),
            item['check_in']?.toString(),
            item['check_out']?.toString(),
          ),
    );
    final totalBonus =
        (targetSummary['bonus_total'] as num?)?.toDouble() ?? 0.0;
    final dailySold = _totalSoldQuantity(targetSales.where((sale) {
      final date = _parseFlexibleDate(sale['created_at']?.toString());
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList());
    final weeklySold = _totalSoldQuantity(targetSales.where((sale) {
      final date = _parseFlexibleDate(sale['created_at']?.toString());
      if (date == null) {
        return false;
      }
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      return !date.isBefore(weekStart) && date.isBefore(weekEnd);
    }).toList());
    final monthlySold = _totalSoldQuantity(monthTargetSales);
    final topProducts = _buildTopProducts(monthSales);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF3D2910), Color(0xFFC18B2F), Color(0xFFEFD39D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, ${me['nama'] ?? 'Tim Sweetie'}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                  'Fokus hari ini: jaga layanan tetap cepat, stok bahan baku rapi, dan tutup shift tanpa transaksi tertinggal.',
                  style:
                      TextStyle(color: Colors.white.withValues(alpha: 0.88))),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => onNavigate(1),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2B2117)),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Buka Absensi'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onNavigate(3),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white)),
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('Input Sales'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final itemWidth = (constraints.maxWidth - (spacing * 3)) / 4;

            return Row(
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _MetricCard(
                    label: 'On Hand',
                    value: '${stats['onhand_count'] ?? 0}',
                    icon: Icons.inventory_2_rounded,
                    accent: const Color(0xFFC18B2F),
                  ),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCard(
                    label: 'Pending Return',
                    value: '${stats['pending_return_count'] ?? 0}',
                    icon: Icons.assignment_return_rounded,
                    accent: const Color(0xFFC05D3B),
                  ),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCard(
                    label: 'Pending Take',
                    value: '${stats['pending_take_count'] ?? 0}',
                    icon: Icons.shopping_bag_rounded,
                    accent: const Color(0xFF6E8B3D),
                  ),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCard(
                    label: 'Sales Approved',
                    value: '${stats['approved_sales_count'] ?? 0}',
                    icon: Icons.verified_rounded,
                    accent: const Color(0xFF2C8C82),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _BlockCard(
          title: 'Ringkasan Bulan Ini',
          subtitle: 'Ringkasan performa toko untuk periode berjalan.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Periode', value: periodLabel),
              _InfoRow(
                  label: 'Total Kehadiran', value: '$totalAttendance hari'),
              _InfoRow(
                  label: 'Total Revenue', value: currency.format(totalRevenue)),
              _InfoRow(
                  label: 'Total Jam Kerja',
                  value: _formatWorkingDuration(totalWorkingMinutes)),
              _InfoRow(
                  label: 'Total Bonus', value: currency.format(totalBonus)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _BlockCard(
          title: 'Target Penjualan ${DateFormat('MM/yyyy').format(now)}',
          subtitle: 'Capaian target penjualan tim aktif.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Target Harian Terpenuhi',
                value: '$dailySold/${_readTargetQty(targetSummary['daily'])}',
              ),
              _InfoRow(
                label: 'Target Mingguan Terpenuhi',
                value: '$weeklySold/${_readTargetQty(targetSummary['weekly'])}',
              ),
              _InfoRow(
                label: 'Target Bulanan Terpenuhi',
                value:
                    '$monthlySold/${_readTargetQty(targetSummary['monthly'])}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _BlockCard(
          title: '5 Product Terlaris',
          subtitle: 'Top produk dengan penjualan tertinggi bulan ini.',
          child: topProducts.isEmpty
              ? const Text('Belum ada data penjualan produk bulan ini.')
              : Column(
                  children: topProducts.map((product) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCF8F1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'Product',
                            value: product['name']?.toString() ?? '-',
                          ),
                          _InfoRow(
                            label: 'Quantity',
                            value: '${product['quantity'] ?? 0}',
                          ),
                          _InfoRow(
                            label: 'Revenue',
                            value: currency.format(
                                (product['revenue'] as num?)?.toDouble() ?? 0),
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

  static DateTime? _parseFlexibleDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.trim().replaceFirst(' ', 'T'));
  }

  static DateTime? _parseTimeOnDate(DateTime baseDate, String rawTime) {
    final parts = rawTime.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    if (hour == null || minute == null) {
      return null;
    }
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
      second,
    );
  }

  static int _calculateWorkedMinutes(
    String? attendanceDate,
    String? checkIn,
    String? checkOut,
  ) {
    if (attendanceDate == null ||
        checkIn == null ||
        checkOut == null ||
        checkIn == '-' ||
        checkOut == '-') {
      return 0;
    }
    final baseDate = _parseFlexibleDate(attendanceDate);
    if (baseDate == null) {
      return 0;
    }
    final start = _parseTimeOnDate(baseDate, checkIn);
    final end = _parseTimeOnDate(baseDate, checkOut);
    if (start == null || end == null || end.isBefore(start)) {
      return 0;
    }
    return end.difference(start).inMinutes;
  }

  static int _totalSoldQuantity(List<Map<String, dynamic>> sourceSales) {
    return sourceSales.fold<int>(0, (sum, sale) {
      final items = (sale['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (items.isNotEmpty) {
        return sum +
            items.fold<int>(
              0,
              (itemSum, item) =>
                  itemSum + ((item['quantity'] as num?)?.toInt() ?? 0),
            );
      }
      return sum + ((sale['total_quantity'] as num?)?.toInt() ?? 0);
    });
  }

  static List<Map<String, dynamic>> _buildTopProducts(
      List<Map<String, dynamic>> sourceSales) {
    final aggregate = <String, Map<String, dynamic>>{};
    for (final sale in sourceSales) {
      final items = (sale['items'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final item in items) {
        final name = item['nama_product']?.toString() ?? 'Produk';
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final revenue = (item['harga'] as num?)?.toDouble() ?? 0;
        final bucket = aggregate.putIfAbsent(
          name,
          () => {'name': name, 'quantity': 0, 'revenue': 0.0},
        );
        bucket['quantity'] = (bucket['quantity'] as int) + quantity;
        bucket['revenue'] = (bucket['revenue'] as double) + revenue;
      }
    }

    final result = aggregate.values.toList()
      ..sort((a, b) {
        final quantityCompare =
            (b['quantity'] as int).compareTo(a['quantity'] as int);
        if (quantityCompare != 0) {
          return quantityCompare;
        }
        return (b['revenue'] as double).compareTo(a['revenue'] as double);
      });

    return result.take(5).toList();
  }

  static String _formatWorkingDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) {
      return '$minutes menit';
    }
    if (minutes == 0) {
      return '$hours jam';
    }
    return '$hours jam $minutes menit';
  }

  static int _readTargetQty(dynamic targetSection) {
    if (targetSection is Map<String, dynamic>) {
      return (targetSection['target_qty'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  static String _capitalizeMonthYear(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _AttendancePage extends StatefulWidget {
  const _AttendancePage({
    required this.me,
    required this.todayAttendance,
    required this.recentAttendances,
    required this.employeeAttendances,
    required this.selectedDate,
    required this.latestLocation,
    required this.manualLocationLabel,
    required this.busy,
    required this.onFilterDate,
    required this.onSubmitAttendance,
  });

  final Map<String, dynamic> me;
  final Map<String, dynamic> todayAttendance;
  final List<Map<String, dynamic>> recentAttendances;
  final List<Map<String, dynamic>> employeeAttendances;
  final String? selectedDate;
  final Map<String, dynamic>? latestLocation;
  final String? manualLocationLabel;
  final bool busy;
  final Future<void> Function(DateTime date) onFilterDate;
  final Future<void> Function(
      {required bool checkIn,
      required String status,
      String? notes}) onSubmitAttendance;

  @override
  State<_AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<_AttendancePage> {
  final TextEditingController _notesController = TextEditingController();
  String _status = 'hadir';

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.todayAttendance['notes']?.toString() ?? '';
    _status = widget.todayAttendance['status']?.toString() ?? 'hadir';
  }

  @override
  void didUpdateWidget(covariant _AttendancePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todayAttendance['notes'] != widget.todayAttendance['notes']) {
      _notesController.text = widget.todayAttendance['notes']?.toString() ?? '';
    }
    if (oldWidget.todayAttendance['status'] !=
        widget.todayAttendance['status']) {
      _status = widget.todayAttendance['status']?.toString() ?? 'hadir';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.me['role']?.toString() == 'owner';
    if (isOwner) {
      return _buildOwnerAttendance(context);
    }

    final checkInValue = widget.todayAttendance['check_in']?.toString();
    final checkOutValue = widget.todayAttendance['check_out']?.toString();
    final hasCheckedIn =
        checkInValue != null && checkInValue.isNotEmpty && checkInValue != '-';
    final hasCheckedOut = checkOutValue != null &&
        checkOutValue.isNotEmpty &&
        checkOutValue != '-';
    final formEnabled = !hasCheckedIn;
    final statusColor =
        hasCheckedIn ? const Color(0xFF2E7D32) : const Color(0xFFC05D3B);
    final statusLabel =
        hasCheckedIn ? 'Selamat Bekerja!' : 'Ayo Mulai Pekerjaan anda!';
    final statusState = hasCheckedIn ? 'Sudah Check In' : 'Belum Check In';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        badges.Badge(
          position: badges.BadgePosition.topStart(top: -6, start: -4),
          badgeStyle: badges.BadgeStyle(
            badgeColor: statusColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: badges.BadgeShape.square,
            borderRadius: BorderRadius.circular(999),
          ),
          badgeContent: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Image.asset(kSweetieLogoAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 6),
              Text(
                statusState,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          child: _BlockCard(
            title: 'Absensi',
            subtitle: statusLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  items: const [
                    DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                    DropdownMenuItem(
                        value: 'terlambat', child: Text('Terlambat')),
                    DropdownMenuItem(value: 'izin', child: Text('Izin')),
                    DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                  ],
                  onChanged: formEnabled
                      ? (value) => setState(() => _status = value ?? 'hadir')
                      : null,
                  decoration:
                      const InputDecoration(labelText: 'Status kehadiran'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 4,
                  enabled: formEnabled,
                  decoration: const InputDecoration(
                    labelText: 'Catatan lapangan',
                    hintText:
                        'Contoh: booth Puri, traffic pagi ramai, fokus repeat buyer.',
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: widget.busy || hasCheckedIn
                          ? null
                          : () => widget.onSubmitAttendance(
                                checkIn: true,
                                status: _status,
                                notes: _notesController.text.trim(),
                              ),
                      icon: const Icon(Icons.login_rounded),
                      label: Text(widget.busy ? 'Memproses...' : 'Check In'),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.busy || !hasCheckedIn || hasCheckedOut
                          ? null
                          : () => widget.onSubmitAttendance(
                                checkIn: false,
                                status: _status,
                                notes: _notesController.text.trim(),
                              ),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(widget.busy ? 'Memproses...' : 'Check Out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerAttendance(BuildContext context) {
    final selectedDate =
        _DashboardPage._parseFlexibleDate(widget.selectedDate) ??
            DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _BlockCard(
          title: 'Riwayat Absensi Karyawan',
          subtitle:
              'Owner hanya melihat history absensi, bukan form check in/out.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    await widget.onFilterDate(picked);
                  }
                },
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(
                  'Filter tanggal ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                ),
              ),
              const SizedBox(height: 14),
              if (widget.employeeAttendances.isEmpty)
                const Text('Belum ada data absensi karyawan pada tanggal ini.')
              else
                ...widget.employeeAttendances.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF6FE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['employee_name']?.toString() ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Tanggal',
                          value: item['attendance_date']?.toString() ?? '-',
                        ),
                        _InfoRow(
                          label: 'Check In',
                          value: item['check_in']?.toString() ?? '-',
                        ),
                        _InfoRow(
                          label: 'Check Out',
                          value: item['check_out']?.toString() ?? '-',
                        ),
                        _InfoRow(
                          label: 'Status',
                          value: item['status']?.toString() ?? '-',
                        ),
                        _InfoRow(
                          label: 'Terlambat',
                          value: '${item['late_minutes'] ?? 0} menit',
                        ),
                      ],
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

class _InventoryPage extends StatelessWidget {
  const _InventoryPage({
    required this.isSmoothiesSweetie,
    required this.products,
    required this.onhands,
    required this.historyOnhands,
    required this.consignmentProducts,
    required this.consignments,
    required this.attendanceBlockedReason,
    required this.busy,
    required this.currency,
    required this.dateTime,
    required this.onTake,
    required this.onReturn,
    required this.onPickConsignmentProof,
    required this.onSubmitConsignment,
    required this.onUpdateConsignmentItem,
  });

  final bool isSmoothiesSweetie;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> onhands;
  final List<Map<String, dynamic>> historyOnhands;
  final List<Map<String, dynamic>>? consignmentProducts;
  final List<Map<String, dynamic>>? consignments;
  final String? attendanceBlockedReason;
  final bool busy;
  final NumberFormat currency;
  final DateFormat dateTime;
  final Future<bool> Function({required int productId, required int quantity})
      onTake;
  final Future<bool> Function({required int onhandId, required int quantity})
      onReturn;
  final Future<XFile?> Function()? onPickConsignmentProof;
  final Future<bool> Function({
    required String placeName,
    required String address,
    required DateTime consignmentDate,
    required List<Map<String, dynamic>> items,
    required XFile proofPhoto,
  })? onSubmitConsignment;
  final Future<bool> Function({
    required int itemId,
    required int soldQuantity,
    required int returnedQuantity,
    String? statusNotes,
  })? onUpdateConsignmentItem;

  @override
  Widget build(BuildContext context) {
    final displayOnhands = _buildOnHandDisplayItems(onhands);
    final activeConsignments = _filterConsignmentsByItemState(
      consignments ?? const <Map<String, dynamic>>[],
      (item) => _activeConsignmentQuantity(item) > 0,
    );
    final completedConsignments = _filterConsignmentsByItemState(
      consignments ?? const <Map<String, dynamic>>[],
      (item) => _activeConsignmentQuantity(item) == 0,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (isSmoothiesSweetie) ...[
          _InventoryLauncherCard(
            title: 'Stok Tersedia',
            subtitle: products.isEmpty
                ? 'Belum ada product aktif untuk store Smoothies Sweetie.'
                : 'Tap untuk melihat stok product yang bisa dijual.',
            icon: Icons.inventory_2_rounded,
            accent: const Color(0xFF6F90D8),
            heroTag: 'inventory-sweetie-stock',
            badgeLabel: '${products.length} product',
            onTap: busy ? null : () => _openSweetieStockSheet(context),
          ),
        ] else ...[
          _InventoryLauncherCard(
            title: 'Ambil Barang',
            subtitle: attendanceBlockedReason ??
                'Tap untuk memilih product yang ingin direquest dari daftar stok.',
            icon: Icons.shopping_bag_rounded,
            accent: const Color(0xFF6E8B3D),
            heroTag: 'inventory-take',
            badgeLabel: '${products.length} product',
            onTap: busy ? null : () => _openTakeSheet(context),
          ),
          const SizedBox(height: 16),
          _InventoryLauncherCard(
            title: 'Barang On Hand',
            subtitle: displayOnhands.isEmpty
                ? 'Belum ada barang on hand.'
                : 'Tap untuk melihat detail barang yang sedang di tangan saat ini.',
            icon: Icons.inventory_2_rounded,
            accent: const Color(0xFFC18B2F),
            heroTag: 'inventory-onhand',
            badgeLabel: '${displayOnhands.length} item',
            onTap: busy ? null : () => _openOnhandSheet(context),
          ),
          const SizedBox(height: 16),
          _InventoryLauncherCard(
            title: 'History Barang',
            subtitle: historyOnhands.isEmpty
                ? 'Belum ada riwayat barang terjual atau dikembalikan.'
                : 'Tap untuk melihat barang on hand yang sudah habis terjual atau sudah dikembalikan.',
            icon: Icons.history_rounded,
            accent: const Color(0xFF2C8C82),
            heroTag: 'inventory-history',
            badgeLabel: '${historyOnhands.length} item',
            onTap: busy ? null : () => _openHistorySheet(context),
          ),
          if (consignmentProducts != null && consignments != null) ...[
            const SizedBox(height: 16),
            _InventoryLauncherCard(
              title: 'Titip Barang',
              subtitle: consignmentProducts!.isEmpty
                  ? 'Belum ada stok batch yang siap untuk consign.'
                  : 'Buat consign dari inventory dengan tanggal otomatis dan banyak item sekaligus.',
              icon: Icons.storefront_rounded,
              accent: const Color(0xFF8C6A2C),
              heroTag: 'inventory-consign-form',
              badgeLabel: '${consignmentProducts!.length} batch',
              onTap: busy ||
                      onPickConsignmentProof == null ||
                      onSubmitConsignment == null
                  ? null
                  : () => _openConsignmentFormSheet(context),
            ),
            const SizedBox(height: 16),
            _InventoryLauncherCard(
              title: 'Active Consign',
              subtitle: activeConsignments.isEmpty
                  ? 'Belum ada consign aktif.'
                  : 'Pantau consign yang masih berjalan dan edit status per item.',
              icon: Icons.history_toggle_off_rounded,
              accent: const Color(0xFF7C5B39),
              heroTag: 'inventory-consign-history',
              badgeLabel: '${activeConsignments.length} consign',
              onTap: busy || onUpdateConsignmentItem == null
                  ? null
                  : () => _openConsignmentHistorySheet(context),
            ),
            const SizedBox(height: 16),
            _InventoryLauncherCard(
              title: 'Riwayat Consign',
              subtitle: completedConsignments.isEmpty
                  ? 'Belum ada consign yang sudah diambil atau terjual.'
                  : 'Lihat consign yang sudah selesai diambil kembali atau sudah terjual.',
              icon: Icons.fact_check_outlined,
              accent: const Color(0xFF5B6F8D),
              heroTag: 'inventory-consign-completed',
              badgeLabel: '${completedConsignments.length} consign',
              onTap: busy || onUpdateConsignmentItem == null
                  ? null
                  : () => _openCompletedConsignmentHistorySheet(context),
            ),
          ],
        ],
      ],
    );
  }

  static Widget _buildOwnerDashboardView(
    BuildContext context, {
    required Map<String, dynamic> dashboard,
    required NumberFormat currency,
  }) {
    final filters = _asMap(dashboard['dashboard_filters']);
    final dashboardData = _asMap(dashboard['dashboard_data']);
    final kpis = _asMap(dashboardData['kpis']);
    final topProducts = _asMapList(dashboardData['top_products']);
    final types = _asMapList(filters['types']);
    final months = _asMapList(filters['months']);

    String labelFor(List<Map<String, dynamic>> source, dynamic value) {
      for (final item in source) {
        if ('${item['value']}' == '$value') {
          return item['label']?.toString() ?? '$value';
        }
      }
      return '$value';
    }

    final filterLabel =
        '${labelFor(types, filters['type'])} • ${labelFor(months, filters['month'])} ${filters['year'] ?? ''}';

    Widget filterChip(String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kSweetieLavender,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFFF4D9F0), Color(0xFFE9E0FB), Color(0xFFFDF8FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Owner',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Ringkasan profit, waste, dan penjualan store mengikuti fokus dashboard Sweetie.',
                style: TextStyle(color: kSweetieInk.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  filterChip(filterLabel),
                  filterChip(
                    dashboardData['period_label']?.toString() ?? '-',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Revenue',
                value: currency
                    .format((kpis['revenue_total'] as num?)?.toDouble() ?? 0),
                icon: Icons.payments_rounded,
                accent: kSweetiePurple,
              ),
            ),
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Offline Sales',
                value: currency.format(
                    (kpis['offline_revenue_total'] as num?)?.toDouble() ?? 0),
                icon: Icons.point_of_sale_rounded,
                accent: kSweetiePink,
              ),
            ),
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Online Sales',
                value: currency.format(
                    (kpis['online_revenue_total'] as num?)?.toDouble() ?? 0),
                icon: Icons.shopping_bag_rounded,
                accent: const Color(0xFF6F90D8),
              ),
            ),
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Waste Material',
                value:
                    '- ${currency.format((kpis['waste_loss_total'] as num?)?.toDouble() ?? 0)}',
                icon: Icons.delete_sweep_rounded,
                accent: const Color(0xFFC05D3B),
              ),
            ),
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Gross Profit',
                value: currency.format(
                    (kpis['gross_profit_total'] as num?)?.toDouble() ?? 0),
                icon: Icons.trending_up_rounded,
                accent: kSweetiePink,
              ),
            ),
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Net Profit',
                value: currency.format(
                    (kpis['net_profit_total'] as num?)?.toDouble() ?? 0),
                icon: Icons.account_balance_wallet_rounded,
                accent: const Color(0xFF6F90D8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _BlockCard(
          title: 'Top 3 Product Terjual',
          subtitle:
              'Produk dengan quantity terjual tertinggi pada periode aktif.',
          child: topProducts.isEmpty
              ? const Text('Belum ada data penjualan produk pada periode ini.')
              : Column(
                  children: topProducts.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF6FE),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name']?.toString() ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Qty Terjual',
                            value: '${item['quantity'] ?? 0}',
                          ),
                          _InfoRow(
                            label: 'Revenue',
                            value: currency.format(
                                (item['revenue'] as num?)?.toDouble() ?? 0),
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

  Future<void> _openSweetieStockSheet(BuildContext context) {
    return showMaterialModalBottomSheet<void>(
      context: context,
      expand: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _HistoryOnHandSheet(
        items: products
            .map((item) => {
                  'nama_product': item['nama_product'],
                  'quantity': item['stock'],
                  'status_label': 'Stok toko',
                  'assignment_date': null,
                  'sold_quantity': 0,
                  'remaining_quantity': item['stock'],
                })
            .toList(),
        currency: currency,
      ),
    );
  }

  Future<void> _openTakeSheet(BuildContext context) {
    return showMaterialModalBottomSheet<void>(
      context: context,
      expand: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _TakeProductSheet(
        products: products,
        busy: busy,
        blockedReason: attendanceBlockedReason,
        currency: currency,
        onTake: onTake,
      ),
    );
  }

  Future<void> _openOnhandSheet(BuildContext context) {
    final displayOnhands = _buildOnHandDisplayItems(onhands);

    return showMaterialModalBottomSheet<void>(
      context: context,
      expand: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _OnHandSheet(
        onhands: displayOnhands,
        busy: busy,
        currency: currency,
        onReturn: onReturn,
      ),
    );
  }

  Future<void> _openHistorySheet(BuildContext context) {
    return showMaterialModalBottomSheet<void>(
      context: context,
      expand: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _HistoryOnHandSheet(
        items: historyOnhands,
        currency: currency,
      ),
    );
  }

  Future<void> _openConsignmentFormSheet(BuildContext context) {
    return showMaterialModalBottomSheet<void>(
      context: context,
      expand: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConsignmentFormSheet(
        products: consignmentProducts ?? const <Map<String, dynamic>>[],
        busy: busy,
        dateTime: dateTime,
        onPickProof: onPickConsignmentProof!,
        onSubmit: onSubmitConsignment!,
      ),
    );
  }

  Future<void> _openConsignmentHistorySheet(BuildContext context) {
    return showMaterialModalBottomSheet<void>(
      context: context,
      expand: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConsignmentHistorySheet(
        consignments: _filterConsignmentsByItemState(
          consignments ?? const <Map<String, dynamic>>[],
          (item) => _activeConsignmentQuantity(item) > 0,
        ),
        busy: busy,
        dateTime: dateTime,
        title: 'Active Consign',
        subtitle:
            'Edit status consign per barang yang masih aktif. Barang yang dikembalikan akan kembali terbaca sebagai on hand user.',
        emptyMessage: 'Belum ada consign aktif.',
        onUpdateItem: onUpdateConsignmentItem!,
      ),
    );
  }

  Future<void> _openCompletedConsignmentHistorySheet(BuildContext context) {
    return showMaterialModalBottomSheet<void>(
      context: context,
      expand: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConsignmentHistorySheet(
        consignments: _filterConsignmentsByItemState(
          consignments ?? const <Map<String, dynamic>>[],
          (item) => _activeConsignmentQuantity(item) == 0,
        ),
        busy: busy,
        dateTime: dateTime,
        title: 'Riwayat Consign',
        subtitle:
            'Daftar consign yang sudah selesai karena item terjual atau sudah diambil kembali.',
        emptyMessage: 'Belum ada consign yang sudah diambil atau terjual.',
        readOnly: true,
        onUpdateItem: onUpdateConsignmentItem!,
      ),
    );
  }
}

List<Map<String, dynamic>> _buildOnHandDisplayItems(
    List<Map<String, dynamic>> onhands) {
  final grouped = <String, List<Map<String, dynamic>>>{};
  final orderedKeys = <String>[];
  final passthrough = <Map<String, dynamic>>[];

  for (final rawItem in onhands) {
    final item = Map<String, dynamic>.from(rawItem);
    final takeStatus = item['take_status']?.toString();

    if (takeStatus != 'disetujui') {
      item['source_onhands'] = [Map<String, dynamic>.from(item)];
      passthrough.add(item);
      continue;
    }

    final key =
        '${item['id_product'] ?? item['nama_product']}|${item['assignment_date'] ?? ''}';
    if (!grouped.containsKey(key)) {
      grouped[key] = <Map<String, dynamic>>[];
      orderedKeys.add(key);
    }
    grouped[key]!.add(item);
  }

  final merged = <Map<String, dynamic>>[
    for (final key in orderedKeys) _mergeApprovedOnHandItems(grouped[key]!),
    ...passthrough,
  ];

  merged.sort((a, b) {
    final aDate = a['assignment_date']?.toString() ?? '';
    final bDate = b['assignment_date']?.toString() ?? '';
    return bDate.compareTo(aDate);
  });

  return merged;
}

Map<String, dynamic> _mergeApprovedOnHandItems(
    List<Map<String, dynamic>> items) {
  if (items.length == 1) {
    final single = Map<String, dynamic>.from(items.first);
    single['source_onhands'] = [Map<String, dynamic>.from(items.first)];
    return single;
  }

  int sumField(String key) => items.fold<int>(
        0,
        (sum, item) => sum + ((item[key] as num?)?.toInt() ?? 0),
      );

  final merged = Map<String, dynamic>.from(items.first);
  final hasPendingReturn =
      items.any((item) => item['return_status']?.toString() == 'pending');

  merged['quantity'] = sumField('quantity');
  merged['remaining_quantity'] = sumField('remaining_quantity');
  merged['sold_quantity'] = sumField('sold_quantity');
  merged['quantity_dikembalikan'] = sumField('quantity_dikembalikan');
  merged['pending_return_quantity'] = sumField('pending_return_quantity');
  merged['approved_return_quantity'] = sumField('approved_return_quantity');
  merged['max_return'] = items
      .where((item) => item['return_status']?.toString() != 'pending')
      .fold<int>(
          0, (sum, item) => sum + ((item['max_return'] as num?)?.toInt() ?? 0));
  merged['source_onhands'] =
      items.map((item) => Map<String, dynamic>.from(item)).toList();
  merged['is_merged_onhand'] = true;
  merged['merged_count'] = items.length;
  merged['status_label'] = hasPendingReturn
      ? 'Sebagian barang sedang menunggu approval retur.'
      : 'Belum dikembalikan';
  merged['return_status'] = hasPendingReturn ? 'pending' : 'belum';
  merged['return_status_label'] =
      hasPendingReturn ? 'Sebagian Pending' : 'Belum Dikembalikan';
  merged['can_request_return'] = (merged['max_return'] as int? ?? 0) > 0;

  return merged;
}

class _InventoryLauncherCard extends StatelessWidget {
  const _InventoryLauncherCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.heroTag,
    required this.badgeLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String heroTag;
  final String badgeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F0A05),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Color.lerp(accent, Colors.white, 0.9) ?? Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Hero(
                tag: heroTag,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: accent, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 6),
                    Text(subtitle),
                    const SizedBox(height: 10),
                    _MiniPill(label: badgeLabel),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: accent.withValues(alpha: 0.82)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TakeProductSheet extends StatefulWidget {
  const _TakeProductSheet({
    required this.products,
    required this.busy,
    required this.blockedReason,
    required this.currency,
    required this.onTake,
  });

  final List<Map<String, dynamic>> products;
  final bool busy;
  final String? blockedReason;
  final NumberFormat currency;
  final Future<bool> Function({required int productId, required int quantity})
      onTake;

  @override
  State<_TakeProductSheet> createState() => _TakeProductSheetState();
}

class _TakeProductSheetState extends State<_TakeProductSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredProducts = widget.products.where((item) {
      final name = item['nama_product']?.toString().toLowerCase() ?? '';
      final description = item['deskripsi']?.toString().toLowerCase() ?? '';
      return query.isEmpty ||
          name.contains(query) ||
          description.contains(query);
    }).toList();

    return _AnimatedSheetScaffold(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F1E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 16),
                _SheetHeader(
                  heroTag: 'inventory-take',
                  accent: const Color(0xFF6E8B3D),
                  icon: Icons.shopping_bag_rounded,
                  title: 'Pilih Product',
                  subtitle: widget.blockedReason ??
                      'Cari product, buka detail, lalu tentukan quantity request.',
                ),
                const SizedBox(height: 16),
                if (widget.blockedReason != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2EC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF0C2AF)),
                    ),
                    child: Text(widget.blockedReason!),
                  ),
                if (widget.blockedReason != null) const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Cari product',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: filteredProducts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Text('Tidak ada product yang cocok.'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredProducts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filteredProducts[index];
                            final stock = (item['stock'] as num?)?.toInt() ?? 0;
                            final badges = _productBadgeLabels(item);
                            return OpenContainer<void>(
                              openBuilder: (context, _) =>
                                  _TakeProductDetailSheet(
                                item: item,
                                currency: widget.currency,
                                busy: widget.busy,
                                blockedReason: widget.blockedReason,
                                onTake: widget.onTake,
                              ),
                              closedElevation: 0,
                              openElevation: 0,
                              openColor: const Color(0xFFF7F1E8),
                              closedColor: Colors.transparent,
                              transitionDuration:
                                  const Duration(milliseconds: 360),
                              closedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              closedBuilder: (context, openContainer) =>
                                  Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x140F0A05),
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                          _showProductImageSheet(context, item),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: SizedBox(
                                          width: 58,
                                          height: 58,
                                          child: _KnowledgeImage(
                                            imageUrl: _productImageUrl(item),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              item['nama_product']
                                                      ?.toString() ??
                                                  '-',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16)),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _MiniPill(label: 'Stock $stock'),
                                              ...badges.take(2).map(
                                                    (badge) =>
                                                        _MiniPill(label: badge),
                                                  ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.north_east_rounded,
                                        color: const Color(0xFF6E8B3D)
                                            .withValues(alpha: 0.78)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TakeProductDetailSheet extends StatelessWidget {
  const _TakeProductDetailSheet({
    required this.item,
    required this.currency,
    required this.busy,
    required this.blockedReason,
    required this.onTake,
  });

  final Map<String, dynamic> item;
  final NumberFormat currency;
  final bool busy;
  final String? blockedReason;
  final Future<bool> Function({required int productId, required int quantity})
      onTake;

  @override
  Widget build(BuildContext context) {
    final stock = _asInt(item['stock']);
    final badges = _productBadgeLabels(item);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['nama_product']?.toString() ?? '-',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _showProductImageSheet(context, item),
                child: Hero(
                  tag: 'inventory-take',
                  child: Material(
                    color: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child:
                            _KnowledgeImage(imageUrl: _productImageUrl(item)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MiniPill(label: 'Stock $stock'),
                  ...badges.map((badge) => _MiniPill(label: badge)),
                ],
              ),
              if (blockedReason != null) ...[
                const SizedBox(height: 14),
                _BlockCard(
                  title: 'Belum Bisa Request',
                  child: Text(blockedReason!),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy || blockedReason != null || stock < 1
                      ? null
                      : () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => _QuantitySheet(
                              title: 'Request ${item['nama_product']}',
                              maxQuantity: stock,
                              ctaLabel: 'Kirim Request',
                              successMessage:
                                  'Request barang berhasil dikirim. Anda akan kembali ke halaman inventory.',
                              closeDepth: 2,
                              onSubmit: (qty) => onTake(
                                productId: _asInt(item['id_product']),
                                quantity: qty,
                              ),
                            ),
                          ),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Request Barang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnHandSheet extends StatefulWidget {
  const _OnHandSheet({
    required this.onhands,
    required this.busy,
    required this.currency,
    required this.onReturn,
  });

  final List<Map<String, dynamic>> onhands;
  final bool busy;
  final NumberFormat currency;
  final Future<bool> Function({required int onhandId, required int quantity})
      onReturn;

  @override
  State<_OnHandSheet> createState() => _OnHandSheetState();
}

class _OnHandSheetState extends State<_OnHandSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.onhands.where((item) {
      final name = item['nama_product']?.toString().toLowerCase() ?? '';
      final status = item['status_label']?.toString().toLowerCase() ?? '';
      final returnStatus =
          item['return_status_label']?.toString().toLowerCase() ?? '';
      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          status.contains(query) ||
          returnStatus.contains(query);
      final matchesFilter = switch (_filter) {
        'active' => item['take_status'] == 'disetujui',
        'pending' => item['take_status'] == 'pending',
        'other' => item['take_status'] != 'disetujui' &&
            item['take_status'] != 'pending',
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    final activeItems =
        filtered.where((item) => item['take_status'] == 'disetujui').toList();
    final pendingItems =
        filtered.where((item) => item['take_status'] == 'pending').toList();
    final otherItems = filtered
        .where((item) =>
            item['take_status'] != 'disetujui' &&
            item['take_status'] != 'pending')
        .toList();

    return _AnimatedSheetScaffold(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F1E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 16),
                _SheetHeader(
                  heroTag: 'inventory-onhand',
                  accent: const Color(0xFFC18B2F),
                  icon: Icons.inventory_2_rounded,
                  title: 'Barang On Hand',
                  subtitle:
                      'Cari dan filter stok yang sedang dibawa atau menunggu approval.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Cari barang on hand',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Aktif',
                        selected: _filter == 'active',
                        onTap: () => setState(() => _filter = 'active'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pending',
                        selected: _filter == 'pending',
                        onTap: () => setState(() => _filter = 'pending'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Lainnya',
                        selected: _filter == 'other',
                        onTap: () => setState(() => _filter = 'other'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                              'Tidak ada barang yang cocok dengan filter.'),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            if (activeItems.isNotEmpty)
                              _OnHandSection(
                                title: 'Sedang Dibawa',
                                subtitle: '${activeItems.length} item aktif',
                                children: activeItems
                                    .map((item) => _OnHandItemCard(
                                          item: item,
                                          busy: widget.busy,
                                          currency: widget.currency,
                                          onReturn: widget.onReturn,
                                        ))
                                    .toList(),
                              ),
                            if (pendingItems.isNotEmpty) ...[
                              if (activeItems.isNotEmpty)
                                const SizedBox(height: 14),
                              _OnHandSection(
                                title: 'Menunggu Approval',
                                subtitle:
                                    '${pendingItems.length} request pending',
                                children: pendingItems
                                    .map((item) => _OnHandItemCard(
                                          item: item,
                                          busy: widget.busy,
                                          currency: widget.currency,
                                          onReturn: widget.onReturn,
                                        ))
                                    .toList(),
                              ),
                            ],
                            if (otherItems.isNotEmpty) ...[
                              if (activeItems.isNotEmpty ||
                                  pendingItems.isNotEmpty)
                                const SizedBox(height: 14),
                              _OnHandSection(
                                title: 'Riwayat Lainnya',
                                subtitle: '${otherItems.length} item',
                                children: otherItems
                                    .map((item) => _OnHandItemCard(
                                          item: item,
                                          busy: widget.busy,
                                          currency: widget.currency,
                                          onReturn: widget.onReturn,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryOnHandSheet extends StatefulWidget {
  const _HistoryOnHandSheet({
    required this.items,
    required this.currency,
  });

  final List<Map<String, dynamic>> items;
  final NumberFormat currency;

  @override
  State<_HistoryOnHandSheet> createState() => _HistoryOnHandSheetState();
}

class _HistoryOnHandSheetState extends State<_HistoryOnHandSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.items.where((item) {
      final name = item['nama_product']?.toString().toLowerCase() ?? '';
      final status = item['status_label']?.toString().toLowerCase() ?? '';
      return query.isEmpty || name.contains(query) || status.contains(query);
    }).toList();

    return _AnimatedSheetScaffold(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F1E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 16),
                const _SheetHeader(
                  heroTag: 'inventory-history',
                  accent: Color(0xFF2C8C82),
                  icon: Icons.history_rounded,
                  title: 'History Barang',
                  subtitle:
                      'Riwayat barang on hand yang sudah habis terjual atau sudah dikembalikan.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Cari history barang',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                              'Belum ada history barang untuk ditampilkan.'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x120F0A05),
                                    blurRadius: 18,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['nama_product']?.toString() ??
                                              '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      _StatusChip(
                                        label:
                                            item['status_label']?.toString() ??
                                                '-',
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
                                            'Qty awal ${((item['quantity'] as num?)?.toInt() ?? 0)}',
                                      ),
                                      _MiniPill(
                                        label:
                                            'Terjual ${((item['sold_quantity'] as num?)?.toInt() ?? 0)}',
                                      ),
                                      _MiniPill(
                                        label:
                                            'Dikembalikan ${((item['approved_return_quantity'] as num?)?.toInt() ?? 0)}',
                                      ),
                                      _MiniPill(
                                        label: item['assignment_date']
                                                ?.toString() ??
                                            '-',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Sisa aktif ${((item['remaining_quantity'] as num?)?.toInt() ?? 0)} item',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6F665F),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFC18B2F) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFC18B2F) : const Color(0xFFE6D7C2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF5E4B38),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OnHandSection extends StatelessWidget {
  const _OnHandSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _OnHandItemCard extends StatelessWidget {
  const _OnHandItemCard({
    required this.item,
    required this.busy,
    required this.currency,
    required this.onReturn,
  });

  final Map<String, dynamic> item;
  final bool busy;
  final NumberFormat currency;
  final Future<bool> Function({required int onhandId, required int quantity})
      onReturn;

  @override
  Widget build(BuildContext context) {
    final sourceOnhands =
        (item['source_onhands'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();
    final isMerged =
        (item['is_merged_onhand'] == true) || sourceOnhands.length > 1;
    final canReturn = item['take_status'] == 'disetujui' &&
        ((item['max_return'] as num?)?.toInt() ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F0A05),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['nama_product']?.toString() ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              _StatusChip(label: item['take_status_label']?.toString() ?? '-'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(label: 'Qty ${item['quantity'] ?? 0}'),
              _MiniPill(label: 'Sisa ${item['remaining_quantity'] ?? 0}'),
              _MiniPill(label: item['return_status_label']?.toString() ?? '-'),
              if (item['assignment_date'] != null)
                _MiniPill(label: item['assignment_date']?.toString() ?? '-'),
              if (isMerged)
                _MiniPill(
                  label:
                      'Gabungan ${item['merged_count'] ?? sourceOnhands.length} approval',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item['status_label']?.toString() ?? '-'),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: !canReturn || busy
                  ? null
                  : () {
                      if (isMerged) {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => _MergedOnHandReturnSheet(
                            item: item,
                            busy: busy,
                            onReturn: onReturn,
                          ),
                        );
                        return;
                      }

                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => _QuantitySheet(
                          title: 'Retur ${item['nama_product']}',
                          maxQuantity:
                              (item['max_return'] as num?)?.toInt() ?? 1,
                          ctaLabel: 'Kirim Retur',
                          successMessage:
                              'Request retur berhasil dikirim. Anda akan kembali ke halaman inventory.',
                          closeDepth: 2,
                          onSubmit: (qty) => onReturn(
                            onhandId: _asInt(item['id_product_onhand']),
                            quantity: qty,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.assignment_return_rounded),
              label: Text(canReturn ? 'Request Retur' : 'Retur Tidak Tersedia'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MergedOnHandReturnSheet extends StatelessWidget {
  const _MergedOnHandReturnSheet({
    required this.item,
    required this.busy,
    required this.onReturn,
  });

  final Map<String, dynamic> item;
  final bool busy;
  final Future<bool> Function({required int onhandId, required int quantity})
      onReturn;

  @override
  Widget build(BuildContext context) {
    final sourceOnhands =
        (item['source_onhands'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();

    return _AnimatedSheetScaffold(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F1E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 16),
                _SheetHeader(
                  heroTag:
                      'merged-return-${item['id_product'] ?? item['nama_product']}',
                  accent: const Color(0xFFC18B2F),
                  icon: Icons.assignment_return_rounded,
                  title: item['nama_product']?.toString() ?? 'Barang On Hand',
                  subtitle:
                      'Pilih batch approval yang ingin diretur. Tampilan utama sudah digabung, tetapi request retur tetap dikirim per approval.',
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sourceOnhands.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final source = sourceOnhands[index];
                      final canReturn = source['take_status'] == 'disetujui' &&
                          source['return_status'] != 'pending' &&
                          ((source['max_return'] as num?)?.toInt() ?? 0) > 0;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x120F0A05),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Approval ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                _StatusChip(
                                  label: source['return_status_label']
                                          ?.toString() ??
                                      '-',
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
                                      'Qty ${((source['quantity'] as num?)?.toInt() ?? 0)}',
                                ),
                                _MiniPill(
                                  label:
                                      'Sisa ${((source['remaining_quantity'] as num?)?.toInt() ?? 0)}',
                                ),
                                _MiniPill(
                                  label:
                                      'Maks retur ${((source['max_return'] as num?)?.toInt() ?? 0)}',
                                ),
                                if (source['assignment_date'] != null)
                                  _MiniPill(
                                    label:
                                        source['assignment_date']?.toString() ??
                                            '-',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(source['status_label']?.toString() ?? '-'),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: !canReturn || busy
                                    ? null
                                    : () => showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) => _QuantitySheet(
                                            title:
                                                'Retur ${item['nama_product']}',
                                            maxQuantity:
                                                (source['max_return'] as num?)
                                                        ?.toInt() ??
                                                    1,
                                            ctaLabel: 'Kirim Retur',
                                            successMessage:
                                                'Request retur berhasil dikirim. Anda akan kembali ke halaman inventory.',
                                            closeDepth: 3,
                                            onSubmit: (qty) => onReturn(
                                              onhandId: _asInt(
                                                source['id_product_onhand'],
                                              ),
                                              quantity: qty,
                                            ),
                                          ),
                                        ),
                                icon:
                                    const Icon(Icons.assignment_return_rounded),
                                label: Text(canReturn
                                    ? 'Retur Batch Ini'
                                    : 'Retur Tidak Tersedia'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.heroTag,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String heroTag;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Hero(
          tag: heroTag,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 56,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFDCCFBF),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _AnimatedSheetScaffold extends StatefulWidget {
  const _AnimatedSheetScaffold({required this.child});

  final Widget child;

  @override
  State<_AnimatedSheetScaffold> createState() => _AnimatedSheetScaffoldState();
}

class _AnimatedSheetScaffoldState extends State<_AnimatedSheetScaffold> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 320),
      reverse: !_visible,
      transitionBuilder: (child, animation, secondaryAnimation) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          fillColor: Colors.transparent,
          child: child,
        );
      },
      child: _visible
          ? widget.child
          : const SizedBox.shrink(key: ValueKey('inventory-sheet-hidden')),
    );
  }
}

class _SalesPage extends StatefulWidget {
  const _SalesPage({
    required this.sales,
    required this.products,
    required this.promos,
    required this.extraToppings,
    required this.sops,
    required this.isSmoothiesSweetie,
    required this.qrisImageUrl,
    required this.busy,
    required this.currency,
    required this.dateTime,
    required this.onPickProof,
    required this.onSubmit,
    required this.onLookupCustomer,
    required this.mockMode,
  });

  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> promos;
  final List<Map<String, dynamic>> extraToppings;
  final List<Map<String, dynamic>> sops;
  final bool isSmoothiesSweetie;
  final String? qrisImageUrl;
  final bool busy;
  final NumberFormat currency;
  final DateFormat dateTime;
  final Future<XFile?> Function() onPickProof;
  final Future<void> Function({
    required String customerName,
    required String customerPhone,
    required String customerSocial,
    required List<_SaleItemDraft> items,
    required String paymentMethod,
    required bool requireProof,
    int? promoId,
    XFile? proof,
  }) onSubmit;
  final Future<Map<String, dynamic>?> Function(String phone) onLookupCustomer;
  final bool mockMode;

  @override
  State<_SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<_SalesPage> {
  final TextEditingController _customerNameController = TextEditingController();
  late final List<_SaleItemDraft> _items;
  int? _promoId;
  String _paymentMethod = 'Cash';
  bool _qrisConfirmed = false;
  final Set<String> _completedSopChecklist = <String>{};

  @override
  void initState() {
    super.initState();
    _items = <_SaleItemDraft>[];
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _productById(int? id) {
    if (id == null) {
      return null;
    }

    for (final entry in widget.products) {
      if ((entry['id_product'] as num?)?.toInt() == id) {
        return entry;
      }
    }

    return null;
  }

  Map<String, dynamic>? get _selectedPromo {
    for (final entry in widget.promos) {
      if ((entry['id'] as num?)?.toInt() == _promoId) {
        return entry;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _variantsForProduct(int? productId) {
    final product = _productById(productId);
    return ((product?['variants'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  int? _defaultVariantId(Map<String, dynamic>? product) {
    final variants =
        ((product?['variants'] as List?) ?? []).cast<Map<String, dynamic>>();
    if (variants.isEmpty) {
      return null;
    }
    for (final variant in variants) {
      if (variant['is_default'] == true) {
        return (variant['id'] as num?)?.toInt();
      }
    }
    return (variants.first['id'] as num?)?.toInt();
  }

  Map<String, dynamic>? _variantById(int? productId, int? variantId) {
    for (final variant in _variantsForProduct(productId)) {
      if ((variant['id'] as num?)?.toInt() == variantId) {
        return variant;
      }
    }
    return null;
  }

  Map<String, dynamic>? _extraToppingById(int id) {
    for (final topping in widget.extraToppings) {
      if ((topping['id'] as num?)?.toInt() == id) {
        return topping;
      }
    }
    return null;
  }

  bool get _hasAnySelectedToppings =>
      _items.any((item) => item.extraToppingIds.isNotEmpty);

  List<Map<String, String>> get _actionableSopSteps {
    final specs = [
      {
        'id': 'pre_blend',
        'title': 'Pre-Blend Check',
        'fallback':
            'Cek blender, gelas, es, dan bahan dasar sebelum proses dimulai.',
        'keywords': 'pre blend,blend,station,bahan dasar',
      },
      if (_hasAnySelectedToppings)
        {
          'id': 'final_topping',
          'title': 'Final Check Topping',
          'fallback':
              'Pastikan topping sesuai pesanan dan urutannya sudah benar.',
          'keywords': 'topping,final check,garnish',
        },
      {
        'id': 'handover',
        'title': 'Serah-Terima Customer',
        'fallback':
            'Sebutkan nama menu, size, dan status pembayaran saat pesanan diberikan.',
        'keywords': 'serah,customer,handover,pembayaran',
      },
      if (_paymentMethod == 'Qris')
        {
          'id': 'payment_verification',
          'title': 'Verifikasi QRIS',
          'fallback':
              'Pastikan customer menunjukkan bukti pembayaran QRIS sebelum transaksi ditutup.',
          'keywords': 'qris,scan',
        },
    ];

    return specs.map((spec) {
      final keywords = (spec['keywords'] ?? '')
          .split(',')
          .map((entry) => entry.trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toList();
      final matched = widget.sops.cast<Map<String, dynamic>?>().firstWhere(
        (sop) {
          final haystack =
              '${sop?['title'] ?? ''} ${sop?['detail'] ?? ''}'.toLowerCase();
          return keywords.any(haystack.contains);
        },
        orElse: () => null,
      );

      return {
        'id': spec['id'] ?? '',
        'title': matched?['title']?.toString() ?? spec['title'] ?? 'SOP',
        'detail': matched?['detail']?.toString() ?? spec['fallback'] ?? '-',
      };
    }).toList();
  }

  bool get _isSopChecklistComplete {
    final requiredStepIds =
        _actionableSopSteps.map((step) => step['id'] ?? '').toSet();
    _completedSopChecklist.removeWhere((id) => !requiredStepIds.contains(id));
    return requiredStepIds.isEmpty ||
        requiredStepIds.every(_completedSopChecklist.contains);
  }

  bool get _hasInvalidItems {
    for (final item in _items) {
      if (item.productId == null || item.quantity < 1) {
        return true;
      }

      if (_variantsForProduct(item.productId).isNotEmpty &&
          item.variantId == null) {
        return true;
      }
    }

    return _items.isEmpty;
  }

  int _productAvailableStock(Map<String, dynamic>? product) {
    if (product == null) {
      return 0;
    }

    return ((product['remaining'] ?? product['stock']) as num?)?.toInt() ?? 0;
  }

  String _variantLabel(Map<String, dynamic> variant) {
    final price =
        widget.currency.format((variant['price'] as num?)?.toDouble() ?? 0);
    return '${variant['name'] ?? 'Varian'} | $price';
  }

  String _toppingSummary(List<int> toppingIds) {
    if (toppingIds.isEmpty) {
      return 'Tanpa extra topping';
    }
    return toppingIds
        .map((id) => _extraToppingById(id)?['name']?.toString() ?? '')
        .where((label) => label.isNotEmpty)
        .join(', ');
  }

  String _sugarLevelLabel(String value) {
    switch (value) {
      case 'Less':
        return 'Less Sugar';
      case 'No Sugar':
        return 'No Sugar';
      default:
        return 'Normal Sugar';
    }
  }

  String _promoLabel(Map<String, dynamic> promo) {
    final label = promo['option_label']?.toString().trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }

    final name = promo['nama_promo']?.toString() ?? 'Promo';
    final code = promo['kode_promo']?.toString().trim();
    return code == null || code.isEmpty ? name : '$name | $code';
  }

  // ignore: unused_element
  void _scheduleCustomerLookup(String value) {
    // Field lookup nomor telepon dinonaktifkan untuk Smoothies Sweetie.
  }

  Future<void> _showSalesHistorySheet(BuildContext context) =>
      showSmoothiesSalesHistorySheet(
        context,
        sales: widget.sales,
        currency: widget.currency,
      );

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPromo() async {
    final selected = await _showSmoothiesSalesOptionSheet(
      context: context,
      heroTag: 'sales-promo',
      accent: const Color(0xFF6A47D1),
      icon: Icons.local_offer_outlined,
      title: 'Pilih Promo',
      subtitle: 'Pilih promo aktif yang sesuai dengan transaksi ini.',
      searchHint: 'Cari promo',
      emptyMessage: 'Belum ada promo aktif saat ini.',
      options: widget.promos,
      selectedId: _promoId,
      includeNoneOption: true,
      noneLabel: 'Tanpa promo',
      idResolver: (item) => (item['id'] as num?)?.toInt(),
      titleResolver: _promoLabel,
      subtitleResolver: (item) {
        final discount =
            widget.currency.format((item['potongan'] as num?)?.toDouble() ?? 0);
        return 'Potongan $discount';
      },
    );

    if (!mounted) {
      return;
    }

    setState(() => _promoId = selected);
  }

  List<int> _normalizeToppingIds(List<int> toppingIds) {
    final normalized = toppingIds.toSet().toList()..sort();
    return normalized;
  }

  bool _hasSameConfiguration(_SaleItemDraft left, _SaleItemDraft right) {
    if (left.productId != right.productId ||
        left.variantId != right.variantId ||
        left.sugarLevel != right.sugarLevel) {
      return false;
    }

    final leftToppings = _normalizeToppingIds(left.extraToppingIds);
    final rightToppings = _normalizeToppingIds(right.extraToppingIds);
    if (leftToppings.length != rightToppings.length) {
      return false;
    }

    for (var index = 0; index < leftToppings.length; index++) {
      if (leftToppings[index] != rightToppings[index]) {
        return false;
      }
    }

    return true;
  }

  int _selectedQuantityForProduct(int? productId, {int? excludingIndex}) {
    if (productId == null) {
      return 0;
    }

    var total = 0;
    for (final entry in _items.asMap().entries) {
      if (excludingIndex != null && entry.key == excludingIndex) {
        continue;
      }
      if (entry.value.productId == productId) {
        total += entry.value.quantity;
      }
    }
    return total;
  }

  double _lineUnitPrice(_SaleItemDraft item) {
    final product = _productById(item.productId);
    final variant = _variantById(item.productId, item.variantId);
    final basePrice = ((variant?['price'] as num?)?.toDouble() ??
            (product?['harga'] as num?)?.toDouble() ??
            0)
        .toDouble();
    final toppingPrice = item.extraToppingIds.fold<double>(
      0,
      (sum, id) =>
          sum + ((_extraToppingById(id)?['price'] as num?)?.toDouble() ?? 0),
    );
    return basePrice + toppingPrice;
  }

  double _lineTotal(_SaleItemDraft item) =>
      _lineUnitPrice(item) * item.quantity;

  String _lineTitle(_SaleItemDraft item) {
    final product = _productById(item.productId);
    final variant = _variantById(item.productId, item.variantId);
    final productName = product?['nama_product']?.toString() ?? 'Produk';
    final variantName = variant?['name']?.toString().trim();
    if (variantName == null || variantName.isEmpty) {
      return productName;
    }
    return '$productName - $variantName';
  }

  Future<int?> _showVariantPickerForProduct(
    Map<String, dynamic> product, {
    int? selectedVariantId,
  }) async {
    final productId = (product['id_product'] as num?)?.toInt();
    final variants = _variantsForProduct(productId);
    if (variants.isEmpty) {
      return null;
    }

    return _showSmoothiesSalesOptionSheet(
      context: context,
      heroTag:
          'sales-variant-product-$productId-${DateTime.now().microsecondsSinceEpoch}',
      accent: const Color(0xFF4A8F74),
      icon: Icons.local_drink_outlined,
      title: 'Pilih Varian',
      subtitle: 'Pilih ukuran sesuai varian product ini.',
      searchHint: 'Cari varian',
      emptyMessage: 'Belum ada varian untuk product ini.',
      options: variants,
      selectedId: selectedVariantId ?? _defaultVariantId(product),
      idResolver: (item) => (item['id'] as num?)?.toInt(),
      titleResolver: _variantLabel,
      subtitleResolver: (item) {
        final ml = (item['total_satuan_ml'] as num?)?.toDouble();
        return ml == null ? null : '${ml.toStringAsFixed(0)} ml';
      },
    );
  }

  Future<List<int>?> _showToppingPickerForDraft({
    required Map<String, dynamic> product,
    required List<int> selectedIds,
  }) async {
    if (widget.extraToppings.isEmpty) {
      return const <int>[];
    }

    final working = selectedIds.toSet();
    return showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            'Extra Topping',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih extra topping untuk ${product['nama_product'] ?? 'product'} atau lanjutkan tanpa topping.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF6F665F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.extraToppings.map((topping) {
                    final toppingId = (topping['id'] as num?)?.toInt();
                    final selected =
                        toppingId != null && working.contains(toppingId);
                    return FilterChip(
                      selected: selected,
                      label: Text(
                        '${topping['name'] ?? 'Topping'} • ${widget.currency.format((topping['price'] as num?)?.toDouble() ?? 0)}',
                      ),
                      onSelected: toppingId == null
                          ? null
                          : (value) {
                              setDialogState(() {
                                if (value) {
                                  working.add(toppingId);
                                } else {
                                  working.remove(toppingId);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(const <int>[]),
              child: const Text('Tidak Pakai'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(_normalizeToppingIds(working.toList())),
              child: const Text('Gunakan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showSugarLevelPickerForDraft({
    required String selectedSugarLevel,
  }) async {
    const options = <_StaticOption<String>>[
      _StaticOption<String>(
        value: 'Normal',
        title: 'Normal',
        subtitle: 'Rasa manis standar.',
      ),
      _StaticOption<String>(
        value: 'Less',
        title: 'Less',
        subtitle: 'Manis dikurangi.',
      ),
      _StaticOption<String>(
        value: 'No Sugar',
        title: 'No Sugar',
        subtitle: 'Tanpa tambahan gula.',
      ),
    ];

    return _showSmoothiesSalesStaticOptionsSheet(
      context: context,
      heroTag: 'sales-sugar-level-${DateTime.now().microsecondsSinceEpoch}',
      accent: const Color(0xFFD980B4),
      icon: Icons.local_cafe_outlined,
      title: 'Sugar Level',
      subtitle: 'Pilih tingkat gula untuk item ini.',
      options: options,
      selectedValue: selectedSugarLevel,
    );
  }

  Future<bool?> _showReuseDialog(_SaleItemDraft existing) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Apakah Ukuran dan Extra Topping sama?'),
        content: Text(
          '${_lineTitle(existing)}\n${_toppingSummary(existing.extraToppingIds)}',
          style: GoogleFonts.plusJakartaSans(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tidak Sama'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sama'),
          ),
        ],
      ),
    );
  }

  Future<_SaleItemDraft?> _composeDraftForProduct(
    Map<String, dynamic> product, {
    _SaleItemDraft? seed,
  }) async {
    final productId = (product['id_product'] as num?)?.toInt();
    if (productId == null) {
      return null;
    }

    var variantId = seed?.variantId;
    final variants = _variantsForProduct(productId);
    if (variants.isNotEmpty) {
      variantId = await _showVariantPickerForProduct(
        product,
        selectedVariantId: variantId,
      );
      if (!mounted || variantId == null) {
        return null;
      }
    }

    final toppingIds = await _showToppingPickerForDraft(
      product: product,
      selectedIds: seed?.extraToppingIds ?? const <int>[],
    );
    if (!mounted || toppingIds == null) {
      return null;
    }

    final sugarLevel = await _showSugarLevelPickerForDraft(
      selectedSugarLevel: seed?.sugarLevel ?? 'Normal',
    );
    if (!mounted || sugarLevel == null) {
      return null;
    }

    return _SaleItemDraft(
      productId: productId,
      variantId: variants.isEmpty ? null : variantId,
      extraToppingIds: _normalizeToppingIds(toppingIds),
      sugarLevel: sugarLevel,
      quantity: 1,
    );
  }

  void _appendOrIncreaseDraft(_SaleItemDraft draft) {
    for (final entry in _items.asMap().entries) {
      if (_hasSameConfiguration(entry.value, draft)) {
        _items[entry.key] = entry.value
            .copyWith(quantity: entry.value.quantity + draft.quantity);
        return;
      }
    }
    _items.add(draft);
  }

  Future<void> _onProductTap(Map<String, dynamic> product) async {
    final productId = (product['id_product'] as num?)?.toInt();
    final available = _productAvailableStock(product);
    if (productId == null || available < 1) {
      _showMessage('Stock product ini sedang habis.');
      return;
    }

    if (_selectedQuantityForProduct(productId) >= available) {
      _showMessage('Quantity product ini sudah mencapai stock yang tersedia.');
      return;
    }

    final existingForProduct = _items
        .asMap()
        .entries
        .where((entry) => entry.value.productId == productId)
        .toList();

    if (existingForProduct.isNotEmpty) {
      final lastDraft = existingForProduct.last.value;
      final reuse = await _showReuseDialog(lastDraft);
      if (!mounted || reuse == null) {
        return;
      }

      if (reuse) {
        if (_selectedQuantityForProduct(productId) >= available) {
          _showMessage(
              'Quantity product ini sudah mencapai stock yang tersedia.');
          return;
        }
        setState(() {
          final current = _items[existingForProduct.last.key];
          _items[existingForProduct.last.key] =
              current.copyWith(quantity: current.quantity + 1);
        });
        return;
      }
    }

    final draft = await _composeDraftForProduct(product);
    if (!mounted || draft == null) {
      return;
    }

    if (_selectedQuantityForProduct(productId) + draft.quantity > available) {
      _showMessage('Quantity product ini melebihi stock yang tersedia.');
      return;
    }

    setState(() => _appendOrIncreaseDraft(draft));
  }

  Future<void> _editLineVariant(int index) async {
    final current = _items[index];
    final product = _productById(current.productId);
    if (product == null) {
      return;
    }

    final selectedVariantId = await _showVariantPickerForProduct(
      product,
      selectedVariantId: current.variantId,
    );
    if (!mounted || selectedVariantId == null) {
      return;
    }

    setState(() {
      _items[index] = current.copyWith(variantId: selectedVariantId);
    });
  }

  Future<void> _editLineToppings(int index) async {
    final current = _items[index];
    final product = _productById(current.productId);
    if (product == null) {
      return;
    }

    final toppingIds = await _showToppingPickerForDraft(
      product: product,
      selectedIds: current.extraToppingIds,
    );
    if (!mounted || toppingIds == null) {
      return;
    }

    setState(() {
      _items[index] =
          current.copyWith(extraToppingIds: _normalizeToppingIds(toppingIds));
    });
  }

  Future<void> _editLineSugarLevel(int index) async {
    final current = _items[index];
    final sugarLevel = await _showSugarLevelPickerForDraft(
      selectedSugarLevel: current.sugarLevel,
    );
    if (!mounted || sugarLevel == null) {
      return;
    }

    setState(() {
      _items[index] = current.copyWith(sugarLevel: sugarLevel);
    });
  }

  void _changeLineQuantity(int index, int delta) {
    final current = _items[index];
    final product = _productById(current.productId);
    if (product == null) {
      return;
    }

    final nextQuantity = current.quantity + delta;
    if (nextQuantity <= 0) {
      setState(() => _items.removeAt(index));
      return;
    }

    final allowed = _productAvailableStock(product);
    final usedByOthers = _selectedQuantityForProduct(
      current.productId,
      excludingIndex: index,
    );
    if (usedByOthers + nextQuantity > allowed) {
      _showMessage('Quantity product ini melebihi stock yang tersedia.');
      return;
    }

    setState(() {
      _items[index] = current.copyWith(quantity: nextQuantity);
    });
  }

  double get _subtotal {
    double sum = 0;
    for (final item in _items) {
      sum += _lineTotal(item);
    }
    return sum;
  }

  double get _discount {
    return (_selectedPromo?['potongan'] as num?)?.toDouble() ?? 0;
  }

  int get _totalSelectedItems {
    return _items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  List<String> get _selectedItemNames {
    final names = <String>[];
    for (final item in _items) {
      final product = _productById(item.productId);
      if (product != null) {
        final toppingLabel = item.extraToppingIds.isEmpty
            ? ''
            : ' + ${_toppingSummary(item.extraToppingIds)}';
        names.add(
          '${_lineTitle(item)} (${_sugarLevelLabel(item.sugarLevel)})$toppingLabel x${item.quantity}',
        );
      }
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final qrisImageSource = kSweetieQrisAsset;
    final requiresQrisConfirmation = _paymentMethod == 'Qris';
    final width = MediaQuery.of(context).size.width;
    final compactCatalog = width < 560;
    final catalogCrossAxisCount = compactCatalog
        ? 2
        : width < 920
            ? 3
            : 4;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _BlockCard(
          title: 'Penjualan',
          subtitle:
              'Pilih product lewat foto, lalu lanjutkan popup varian dan extra topping.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'Nama customer'),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Menu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kSweetieInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap foto product. Setelah itu kasir akan memilih varian, lalu extra topping.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 1.4,
                  color: const Color(0xFF766C8B),
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: catalogCrossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: compactCatalog ? 0.75 : 0.86,
                ),
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  return _SalesCatalogCard(
                    key: ValueKey(
                      'sales-catalog-product-${product['id_product']}',
                    ),
                    product: product,
                    currency: widget.currency,
                    stock: _productAvailableStock(product),
                    onTap: () => _onProductTap(product),
                  );
                },
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF6FE),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE7D9F4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesanan Aktif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _items.isEmpty
                          ? 'Belum ada product dipilih.'
                          : 'Qty bisa ditambah atau dikurangi langsung dari kartu item.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.4,
                        color: const Color(0xFF766C8B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Pilih product dari foto di atas untuk mulai input penjualan.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._items.asMap().entries.map((entry) {
                        final product = _productById(entry.value.productId);
                        if (product == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.key == _items.length - 1 ? 0 : 12,
                          ),
                          child: _SalesOrderLineCard(
                            product: product,
                            draft: entry.value,
                            currency: widget.currency,
                            unitPrice: _lineUnitPrice(entry.value),
                            totalPrice: _lineTotal(entry.value),
                            toppingSummary:
                                _toppingSummary(entry.value.extraToppingIds),
                            sugarLevelLabel:
                                _sugarLevelLabel(entry.value.sugarLevel),
                            onDecrease: () =>
                                _changeLineQuantity(entry.key, -1),
                            onIncrease: () => _changeLineQuantity(entry.key, 1),
                            onEditVariant: () => _editLineVariant(entry.key),
                            onEditToppings: () => _editLineToppings(entry.key),
                            onEditSugarLevel: () =>
                                _editLineSugarLevel(entry.key),
                            onRemove: () =>
                                setState(() => _items.removeAt(entry.key)),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _PickerField(
                fieldKey: const ValueKey('sales-payment-method-picker'),
                heroTag: 'sales-payment-method',
                accent: const Color(0xFF2C8C82),
                icon: Icons.payments_outlined,
                label: 'Metode pembayaran',
                title: _paymentMethod,
                subtitle: _paymentMethod == 'Qris'
                    ? 'Tampilkan QRIS lalu lanjutkan transaksi ke antrian'
                    : 'Transaksi ditutup sebagai pembayaran tunai',
                onTap: () async {
                  final selected = await _showSmoothiesSalesStaticOptionsSheet(
                    context: context,
                    heroTag: 'sales-payment-sheet',
                    accent: const Color(0xFF2C8C82),
                    icon: Icons.payments_outlined,
                    title: 'Metode Pembayaran',
                    subtitle: 'Pilih alur pembayaran yang dipakai kasir.',
                    options: const [
                      _StaticOption<String>(
                        value: 'Cash',
                        title: 'Cash',
                        subtitle: 'Customer bayar tunai di kasir',
                      ),
                      _StaticOption<String>(
                        value: 'Qris',
                        title: 'Qris',
                        subtitle:
                            'Customer scan QRIS lalu pesanan masuk antrian',
                      ),
                    ],
                    selectedValue: _paymentMethod,
                  );
                  if (!mounted || selected == null) {
                    return;
                  }
                  setState(() {
                    _paymentMethod = selected;
                    if (selected != 'Qris') {
                      _qrisConfirmed = false;
                    }
                  });
                },
              ),
              if (_paymentMethod == 'Qris') ...[
                const SizedBox(height: 10),
                Container(
                  key: const ValueKey('sales-qris-panel'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F0FB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4D7F4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QRIS siap dipakai',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tunjukkan QRIS ke customer, tunggu pembayaran sukses, lalu tutup transaksi agar nomor antrian terbentuk.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        key: const ValueKey('sales-qris-image-trigger'),
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          await showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: _SalesImageFrame(
                                      imageUrl: qrisImageSource,
                                      height: 320,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () {
                                        setState(() => _qrisConfirmed = true);
                                        Navigator.of(dialogContext).pop();
                                      },
                                      child: const Text('Sudah Bayar'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _SalesImageFrame(
                            imageUrl: qrisImageSource,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _qrisConfirmed
                            ? 'Pembayaran QRIS sudah dikonfirmasi.'
                            : 'Tap gambar QRIS untuk memperbesar lalu tekan "Sudah Bayar".',
                        style: TextStyle(
                          fontSize: 12,
                          color: _qrisConfirmed
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF6F665F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('sales-qris-confirm-button'),
                          onPressed: () {
                            setState(() => _qrisConfirmed = true);
                          },
                          child: Text(
                            _qrisConfirmed
                                ? 'Pembayaran Terkonfirmasi'
                                : 'Sudah Bayar',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _PickerField(
                fieldKey: const ValueKey('sales-promo-picker'),
                heroTag: 'sales-promo',
                accent: const Color(0xFF6A47D1),
                icon: Icons.local_offer_outlined,
                label: 'Promo aktif',
                title: _selectedPromo == null
                    ? 'Tanpa promo'
                    : _selectedPromo!['nama_promo']?.toString() ?? 'Promo',
                subtitle: _selectedPromo == null
                    ? 'Tap untuk memilih promo'
                    : _promoLabel(_selectedPromo!),
                enabled: widget.promos.isNotEmpty,
                onTap: _pickPromo,
              ),
              if (_selectedPromo != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F0FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Syarat promo: min ${(_selectedPromo!['minimal_quantity'] as num?)?.toInt() ?? 0} item, min belanja ${widget.currency.format((_selectedPromo!['minimal_belanja'] as num?)?.toDouble() ?? 0)}.',
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSweetieInk,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Subtotal',
                      value: widget.currency.format(_subtotal),
                      valueColor: Colors.white,
                    ),
                    _SummaryRow(
                      label: 'Diskon',
                      value: widget.currency.format(_discount),
                      valueColor: Colors.white,
                    ),
                    _SummaryRow(
                      label: 'Total estimasi',
                      value: widget.currency
                          .format((_subtotal - _discount).clamp(0, _subtotal)),
                      valueColor: Colors.white,
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F0FB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE4D7F4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview Transaksi',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniPill(label: '$_totalSelectedItems item'),
                        _MiniPill(label: _paymentMethod),
                        _MiniPill(
                          label: _selectedPromo == null
                              ? 'Tanpa promo'
                              : (_selectedPromo!['kode_promo']
                                          ?.toString()
                                          .trim()
                                          .isNotEmpty ==
                                      true
                                  ? _selectedPromo!['kode_promo'].toString()
                                  : (_selectedPromo!['nama_promo']
                                          ?.toString() ??
                                      'Promo')),
                        ),
                        _MiniPill(
                          label: widget.currency.format(
                              (_subtotal - _discount).clamp(0, _subtotal)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedItemNames.isEmpty
                          ? 'Belum ada item valid yang dipilih.'
                          : _selectedItemNames.take(3).join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF766C8B),
                      ),
                    ),
                    if (_selectedItemNames.length > 3) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${_selectedItemNames.length - 3} item lainnya',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF766C8B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_actionableSopSteps.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F0FB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4D7F4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checklist SOP Sebelum Close',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kasir menyelesaikan langkah operasional ini sebelum pembayaran ditutup.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      ..._actionableSopSteps.map(
                        (step) => CheckboxListTile(
                          key: ValueKey('sales-sop-check-${step['id']}'),
                          value: _completedSopChecklist.contains(step['id']),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            step['title'] ?? 'SOP',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            step['detail'] ?? '-',
                            style: const TextStyle(fontSize: 12, height: 1.4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              final id = step['id'] ?? '';
                              if (id.isEmpty) {
                                return;
                              }
                              if (value == true) {
                                _completedSopChecklist.add(id);
                              } else {
                                _completedSopChecklist.remove(id);
                              }
                            });
                          },
                        ),
                      ),
                      if (!_isSopChecklistComplete)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Selesaikan checklist SOP dulu sebelum menutup pembayaran.',
                            style: TextStyle(
                              color: Color(0xFFC05D3B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('sales-submit-button'),
                  onPressed: widget.busy ||
                          widget.products.isEmpty ||
                          _hasInvalidItems ||
                          !_isSopChecklistComplete ||
                          (requiresQrisConfirmation && !_qrisConfirmed)
                      ? null
                      : () => widget.onSubmit(
                            customerName: _customerNameController.text.trim(),
                            customerPhone: '',
                            customerSocial: '',
                            items: List<_SaleItemDraft>.from(_items),
                            paymentMethod: _paymentMethod,
                            requireProof: false,
                            promoId: _promoId,
                            proof: null,
                          ),
                  child:
                      Text(widget.busy ? 'Menyimpan...' : 'Tutup pembayaran'),
                ),
              ),
            ],
          ),
        ),
        if (widget.sops.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BlockCard(
            title: 'SOP Kasir',
            subtitle:
                'Ringkasan SOP yang paling relevan untuk transaksi booth.',
            child: Column(
              children: widget.sops
                  .take(3)
                  .map(
                    (sop) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCF8F1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sop['title']?.toString() ?? 'SOP',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sop['detail']?.toString() ?? '-',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _SalesCatalogCard extends StatelessWidget {
  const _SalesCatalogCard({
    super.key,
    required this.product,
    required this.currency,
    required this.stock,
    required this.onTap,
  });

  final Map<String, dynamic> product;
  final NumberFormat currency;
  final int stock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _productImageUrl(product);
    final isOutOfStock = stock < 1;

    return InkWell(
      onTap: isOutOfStock ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Opacity(
        opacity: isOutOfStock ? 0.58 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7D9F4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x148E79D6),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: _SalesImageFrame(
                    imageUrl: imageUrl,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['nama_product']?.toString() ?? 'Product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: kSweetieInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currency.format(
                        (product['harga'] as num?)?.toDouble() ?? 0,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8E5BE8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOutOfStock ? 'Stock habis' : 'Stock $stock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOutOfStock
                            ? const Color(0xFFC05D3B)
                            : const Color(0xFF766C8B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesOrderLineCard extends StatelessWidget {
  const _SalesOrderLineCard({
    required this.product,
    required this.draft,
    required this.currency,
    required this.unitPrice,
    required this.totalPrice,
    required this.toppingSummary,
    required this.sugarLevelLabel,
    required this.onDecrease,
    required this.onIncrease,
    required this.onEditVariant,
    required this.onEditToppings,
    required this.onEditSugarLevel,
    required this.onRemove,
  });

  final Map<String, dynamic> product;
  final _SaleItemDraft draft;
  final NumberFormat currency;
  final double unitPrice;
  final double totalPrice;
  final String toppingSummary;
  final String sugarLevelLabel;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onEditVariant;
  final VoidCallback onEditToppings;
  final VoidCallback onEditSugarLevel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _productImageUrl(product);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;
    final variantName = product['variants'] == null
        ? null
        : (((product['variants'] as List?) ?? [])
                .cast<Map<String, dynamic>>()
                .firstWhere(
                  (variant) =>
                      (variant['id'] as num?)?.toInt() == draft.variantId,
                  orElse: () => const <String, dynamic>{},
                )['name'])
            ?.toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7D9F4)),
      ),
      child: Column(
        children: [
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _SalesImageFrame(
                        imageUrl: imageUrl,
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SalesOrderLineInfo(
                        productName:
                            product['nama_product']?.toString() ?? 'Product',
                        variantName: variantName,
                        toppingSummary: toppingSummary,
                        sugarLevelLabel: sugarLevelLabel,
                        draft: draft,
                        onEditVariant: onEditVariant,
                        onEditToppings: onEditToppings,
                        onEditSugarLevel: onEditSugarLevel,
                        onRemove: onRemove,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _SalesQuantityPanel(
                      quantity: draft.quantity,
                      unitPriceLabel: currency.format(unitPrice),
                      onDecrease: onDecrease,
                      onIncrease: onIncrease,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _SalesImageFrame(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SalesOrderLineInfo(
                      productName:
                          product['nama_product']?.toString() ?? 'Product',
                      variantName: variantName,
                      toppingSummary: toppingSummary,
                      sugarLevelLabel: sugarLevelLabel,
                      draft: draft,
                      onEditVariant: onEditVariant,
                      onEditToppings: onEditToppings,
                      onEditSugarLevel: onEditSugarLevel,
                      onRemove: onRemove,
                    ),
                    const SizedBox(height: 12),
                    _SalesQuantityPanel(
                      quantity: draft.quantity,
                      unitPriceLabel: currency.format(unitPrice),
                      onDecrease: onDecrease,
                      onIncrease: onIncrease,
                      compact: true,
                    ),
                  ],
                ),
          const SizedBox(height: 14),
          Center(
            child: Column(
              children: [
                const Text(
                  'Total Harga',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B799B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(totalPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kSweetieInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesOrderLineInfo extends StatelessWidget {
  const _SalesOrderLineInfo({
    required this.productName,
    required this.variantName,
    required this.toppingSummary,
    required this.sugarLevelLabel,
    required this.draft,
    required this.onEditVariant,
    required this.onEditToppings,
    required this.onEditSugarLevel,
    required this.onRemove,
  });

  final String productName;
  final String? variantName;
  final String toppingSummary;
  final String sugarLevelLabel;
  final _SaleItemDraft draft;
  final VoidCallback onEditVariant;
  final VoidCallback onEditToppings;
  final VoidCallback onEditSugarLevel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                productName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: kSweetieInk,
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Hapus item',
            ),
          ],
        ),
        if (variantName != null && variantName!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Varian: $variantName',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6F665F),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Sugar: $sugarLevelLabel',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6F665F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          toppingSummary,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Color(0xFF766C8B),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: onEditVariant,
              child: const Text('Ubah Varian'),
            ),
            OutlinedButton(
              onPressed: onEditToppings,
              child: Text(
                draft.extraToppingIds.isEmpty
                    ? 'Tambah Topping'
                    : 'Ubah Topping',
              ),
            ),
            OutlinedButton(
              onPressed: onEditSugarLevel,
              child: const Text('Ubah Sugar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SalesQuantityPanel extends StatelessWidget {
  const _SalesQuantityPanel({
    required this.quantity,
    required this.unitPriceLabel,
    required this.onDecrease,
    required this.onIncrease,
    this.compact = false,
  });

  final int quantity;
  final String unitPriceLabel;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1FD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  unitPriceLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B799B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_circle_rounded),
          ),
        ],
      ),
    );

    if (compact) {
      return content;
    }

    return SizedBox(width: 148, child: content);
  }
}

class _SalesImageFrame extends StatelessWidget {
  const _SalesImageFrame({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final normalized = imageUrl.trim();
    if (normalized.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFF5EDF9),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFFB8A6C8),
          size: 34,
        ),
      );
    }

    if (normalized.startsWith('assets/')) {
      return Image.asset(
        normalized,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return CachedNetworkImage(
      imageUrl: normalized,
      width: width,
      height: height,
      fit: fit,
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF5EDF9),
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          color: Color(0xFFB8A6C8),
          size: 34,
        ),
      ),
    );
  }
}

class _SalesHistorySheet extends StatelessWidget {
  const _SalesHistorySheet({
    required this.sales,
    required this.currency,
  });

  final List<Map<String, dynamic>> sales;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return _AnimatedSheetScaffold(
      child: SafeArea(
        top: false,
        child: Material(
          color: const Color(0xFFF7F1E6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const _SheetHeader(
                heroTag: 'sales-history-sheet',
                accent: Color(0xFF7B4AE2),
                icon: Icons.receipt_long_outlined,
                title: 'Riwayat Transaksi',
                subtitle:
                    'Semua transaksi Smoothies Sweetie ditampilkan di sini.',
              ),
              Flexible(
                child: sales.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
                        child: Text('Belum ada transaksi untuk ditampilkan.'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: sales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          final items = ((sale['items'] as List?) ?? [])
                              .cast<Map<String, dynamic>>();

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x120F0A05),
                                  blurRadius: 18,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sale['transaction_code']
                                                    ?.toString() ??
                                                '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if ((sale['sale_number']
                                                  ?.toString()
                                                  .trim()
                                                  .isNotEmpty ??
                                              false)) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Antrian ${sale['sale_number']}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    _StatusChip(
                                      label:
                                          sale['approval_status']?.toString() ??
                                              '-',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  sale['nama_customer']
                                              ?.toString()
                                              .trim()
                                              .isNotEmpty ==
                                          true
                                      ? sale['nama_customer'].toString()
                                      : 'Customer umum',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sale['created_at']?.toString() ?? '-',
                                  style: const TextStyle(fontSize: 12),
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
                                      label: sale['payment_method']
                                                  ?.toString()
                                                  .trim()
                                                  .isNotEmpty ==
                                              true
                                          ? sale['payment_method'].toString()
                                          : 'Cash',
                                    ),
                                    _MiniPill(
                                      label: sale['payment_status']
                                                  ?.toString()
                                                  .trim()
                                                  .isNotEmpty ==
                                              true
                                          ? sale['payment_status'].toString()
                                          : '-',
                                    ),
                                    _MiniPill(
                                      label: currency.format(
                                        (sale['total_harga'] as num?)
                                                ?.toDouble() ??
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
                                          padding:
                                              const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            '${item['nama_product'] ?? '-'} x${item['quantity'] ?? 0} • Sugar ${item['sugar_level'] ?? 'Normal'}${(((item['extra_toppings'] as List?) ?? []).isEmpty) ? '' : ' • ${((item['extra_toppings'] as List?) ?? []).cast<Map<String, dynamic>>().map((topping) => topping['name']).whereType<String>().join(', ')}'}',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesOptionSheet extends StatefulWidget {
  const _SalesOptionSheet({
    required this.heroTag,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.emptyMessage,
    required this.options,
    required this.selectedId,
    required this.idResolver,
    required this.titleResolver,
    this.subtitleResolver,
    this.trailingBadgeResolver,
    this.includeNoneOption = false,
    this.noneLabel = 'Tidak ada',
  });

  final String heroTag;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final String searchHint;
  final String emptyMessage;
  final List<Map<String, dynamic>> options;
  final int? selectedId;
  final int? Function(Map<String, dynamic>) idResolver;
  final String Function(Map<String, dynamic>) titleResolver;
  final String? Function(Map<String, dynamic>)? subtitleResolver;
  final String? Function(Map<String, dynamic>)? trailingBadgeResolver;
  final bool includeNoneOption;
  final String noneLabel;

  @override
  State<_SalesOptionSheet> createState() => _SalesOptionSheetState();
}

class _SalesOptionSheetState extends State<_SalesOptionSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.options.where((item) {
      final title = widget.titleResolver(item).toLowerCase();
      final subtitle = widget.subtitleResolver?.call(item)?.toLowerCase() ?? '';
      return query.isEmpty || title.contains(query) || subtitle.contains(query);
    }).toList();

    return _AnimatedSheetScaffold(
      child: SafeArea(
        top: false,
        child: Material(
          color: const Color(0xFFF7F1E6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              _SheetHeader(
                heroTag: widget.heroTag,
                accent: widget.accent,
                icon: widget.icon,
                title: widget.title,
                subtitle: widget.subtitle,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              Flexible(
                child: filtered.isEmpty && !widget.includeNoneOption
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        child: Text(widget.emptyMessage),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        children: [
                          if (widget.includeNoneOption)
                            _SelectionTile(
                              selected: widget.selectedId == null,
                              icon: widget.icon,
                              accent: widget.accent,
                              title: widget.noneLabel,
                              subtitle: 'Gunakan transaksi tanpa promo',
                              onTap: () =>
                                  Navigator.of(context).pop<int?>(null),
                            ),
                          if (widget.includeNoneOption)
                            const SizedBox(height: 10),
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(widget.emptyMessage),
                            )
                          else
                            ...filtered.map((item) {
                              final id = widget.idResolver(item);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _SelectionTile(
                                  selected: id == widget.selectedId,
                                  icon: widget.icon,
                                  accent: widget.accent,
                                  title: widget.titleResolver(item),
                                  subtitle: widget.subtitleResolver?.call(item),
                                  trailingBadgeLabel:
                                      widget.trailingBadgeResolver?.call(item),
                                  onTap: id == null
                                      ? null
                                      : () =>
                                          Navigator.of(context).pop<int?>(id),
                                ),
                              );
                            }),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class _StaticOption<T> {
  const _StaticOption({
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final T value;
  final String title;
  final String subtitle;
}

class _StaticOptionsSheet<T> extends StatelessWidget {
  const _StaticOptionsSheet({
    required this.heroTag,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedValue,
  });

  final String heroTag;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_StaticOption<T>> options;
  final T selectedValue;

  @override
  Widget build(BuildContext context) {
    return _AnimatedSheetScaffold(
      child: SafeArea(
        top: false,
        child: Material(
          color: const Color(0xFFF7F1E6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              _SheetHeader(
                heroTag: heroTag,
                accent: accent,
                icon: icon,
                title: title,
                subtitle: subtitle,
              ),
              ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final option = options[index];
                  return _SelectionTile(
                    selected: option.value == selectedValue,
                    icon: icon,
                    accent: accent,
                    title: option.title,
                    subtitle: option.subtitle,
                    onTap: () => Navigator.of(context).pop<T>(option.value),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesMultiSelectSheet extends StatefulWidget {
  const _SalesMultiSelectSheet({
    required this.heroTag,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedIds,
    required this.idResolver,
    required this.titleResolver,
    // ignore: unused_element_parameter
    this.subtitleResolver,
  });

  final String heroTag;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> options;
  final List<int> selectedIds;
  final int? Function(Map<String, dynamic>) idResolver;
  final String Function(Map<String, dynamic>) titleResolver;
  final String? Function(Map<String, dynamic>)? subtitleResolver;

  @override
  State<_SalesMultiSelectSheet> createState() => _SalesMultiSelectSheetState();
}

class _SalesMultiSelectSheetState extends State<_SalesMultiSelectSheet> {
  late final Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return _AnimatedSheetScaffold(
      child: SafeArea(
        top: false,
        child: Material(
          color: const Color(0xFFF7F1E6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              _SheetHeader(
                heroTag: widget.heroTag,
                accent: widget.accent,
                icon: widget.icon,
                title: widget.title,
                subtitle: widget.subtitle,
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  itemCount: widget.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final id = widget.idResolver(option);
                    final selected = id != null && _selectedIds.contains(id);
                    return _SelectionTile(
                      selected: selected,
                      icon: widget.icon,
                      accent: widget.accent,
                      title: widget.titleResolver(option),
                      subtitle: widget.subtitleResolver?.call(option),
                      onTap: id == null
                          ? null
                          : () => setState(() {
                                if (selected) {
                                  _selectedIds.remove(id);
                                } else {
                                  _selectedIds.add(id);
                                }
                              }),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pop<List<int>>(_selectedIds.toList()),
                    child: const Text('Gunakan topping ini'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    this.fieldKey,
    required this.heroTag,
    required this.accent,
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingBadgeLabel,
    this.enabled = true,
  });

  final Key? fieldKey;
  final String heroTag;
  final Color accent;
  final IconData icon;
  final String label;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingBadgeLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground =
        enabled ? const Color(0xFF241B13) : const Color(0xFF9D948B);
    final background = enabled ? Colors.white : const Color(0xFFF3EEE7);

    return InkWell(
      key: fieldKey,
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled
                ? accent.withValues(alpha: 0.18)
                : const Color(0xFFE5DED4),
          ),
        ),
        child: Row(
          children: [
            Hero(
              tag: heroTag,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: enabled
                        ? accent.withValues(alpha: 0.14)
                        : const Color(0xFFE8E2DA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: enabled ? accent : foreground),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7E7368),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: foreground.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingBadgeLabel != null &&
                    trailingBadgeLabel!.trim().isNotEmpty) ...[
                  _MiniPill(label: trailingBadgeLabel!),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.expand_more_rounded, color: foreground),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.selected,
    required this.icon,
    required this.accent,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailingBadgeLabel,
  });

  final bool selected;
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final String? trailingBadgeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? accent : const Color(0xFFE7DDD0),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x0F0F0A05),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: selected ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6F665F),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingBadgeLabel != null &&
                    trailingBadgeLabel!.trim().isNotEmpty) ...[
                  _MiniPill(label: trailingBadgeLabel!),
                  const SizedBox(width: 8),
                ],
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? accent : const Color(0xFF8F857A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsignmentFormSheet extends StatefulWidget {
  const _ConsignmentFormSheet({
    required this.products,
    required this.busy,
    required this.dateTime,
    required this.onPickProof,
    required this.onSubmit,
  });

  final List<Map<String, dynamic>> products;
  final bool busy;
  final DateFormat dateTime;
  final Future<XFile?> Function() onPickProof;
  final Future<bool> Function({
    required String placeName,
    required String address,
    required DateTime consignmentDate,
    required List<Map<String, dynamic>> items,
    required XFile proofPhoto,
  }) onSubmit;

  @override
  State<_ConsignmentFormSheet> createState() => _ConsignmentFormSheetState();
}

class _ConsignmentFormSheetState extends State<_ConsignmentFormSheet> {
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final List<Map<String, dynamic>> _items = [];
  DateTime _date = DateTime.now();
  XFile? _proof;
  int? _selectedProductOnhandId;

  @override
  void dispose() {
    _placeController.dispose();
    _addressController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addSelectedProduct() {
    if (_selectedProductOnhandId == null) {
      return;
    }
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (quantity <= 0) {
      return;
    }

    final product = widget.products.firstWhere(
      (item) => item['id_product_onhand'] == _selectedProductOnhandId,
    );
    final existingIndex = _items.indexWhere(
      (item) => item['product_onhand_id'] == _selectedProductOnhandId,
    );
    final availableQuantity = _asInt(product['available_quantity']);

    setState(() {
      if (existingIndex >= 0) {
        final currentQuantity = _asInt(_items[existingIndex]['quantity']);
        _items[existingIndex]['quantity'] =
            (currentQuantity + quantity).clamp(1, availableQuantity);
      } else {
        _items.add({
          'product_onhand_id': product['id_product_onhand'],
          'product_name': product['nama_product'],
          'pickup_batch_code': product['pickup_batch_code'],
          'available_quantity': availableQuantity,
          'quantity': quantity.clamp(1, availableQuantity),
        });
      }
      _quantityController.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableProducts = widget.products.where((product) {
      final productOnhandId = product['id_product_onhand'];
      final selectedItem = _items.cast<Map<String, dynamic>>().firstWhere(
            (item) => item['product_onhand_id'] == productOnhandId,
            orElse: () => <String, dynamic>{},
          );
      final selectedQuantity = _asInt(selectedItem['quantity']);
      final availableQuantity = _asInt(product['available_quantity']);
      return selectedQuantity < availableQuantity;
    }).toList();

    if (availableProducts.isEmpty) {
      _selectedProductOnhandId = null;
    } else if (_selectedProductOnhandId == null ||
        !availableProducts.any(
          (product) => product['id_product_onhand'] == _selectedProductOnhandId,
        )) {
      _selectedProductOnhandId =
          availableProducts.first['id_product_onhand'] as int;
    }

    return _AnimatedSheetScaffold(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F1E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              const _SheetHandle(),
              const SizedBox(height: 16),
              const _SheetHeader(
                heroTag: 'inventory-consign-form',
                accent: Color(0xFF8C6A2C),
                icon: Icons.storefront_rounded,
                title: 'Titip Barang',
                subtitle:
                    'Tanggal otomatis terisi sampai jam, dan sales field bisa menambahkan banyak item sekaligus.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _placeController,
                decoration: const InputDecoration(labelText: 'Nama tempat'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7DDD0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: Color(0xFF8C6A2C)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tanggal consign',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7E7368),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.dateTime.format(_date),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Otomatis mengikuti waktu submit dan tidak bisa diubah manual.',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF6F665F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _PickerField(
                heroTag: 'consign-product-batch',
                accent: const Color(0xFF8C6A2C),
                icon: Icons.inventory_2_outlined,
                label: 'Product batch',
                title: _selectedProductOnhandId == null
                    ? 'Pilih batch'
                    : (availableProducts
                            .firstWhere(
                              (product) =>
                                  product['id_product_onhand'] ==
                                  _selectedProductOnhandId,
                              orElse: () => const <String, dynamic>{},
                            )['nama_product']
                            ?.toString() ??
                        'Pilih batch'),
                subtitle: _selectedProductOnhandId == null
                    ? 'Tap untuk memilih batch consign'
                    : _consignmentBatchSubtitle(
                        availableProducts.firstWhere(
                          (product) =>
                              product['id_product_onhand'] ==
                              _selectedProductOnhandId,
                          orElse: () => const <String, dynamic>{},
                        ),
                      ),
                trailingBadgeLabel: _selectedProductOnhandId == null
                    ? null
                    : 'Stok ${_asInt(availableProducts.firstWhere(
                        (product) =>
                            product['id_product_onhand'] ==
                            _selectedProductOnhandId,
                        orElse: () => const <String, dynamic>{},
                      )['available_quantity'])}',
                enabled: availableProducts.isNotEmpty && !widget.busy,
                onTap: () async {
                  final selected = await showMaterialModalBottomSheet<int>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _SalesOptionSheet(
                      heroTag: 'consign-product-batch',
                      accent: const Color(0xFF8C6A2C),
                      icon: Icons.inventory_2_outlined,
                      title: 'Pilih Batch Consign',
                      subtitle:
                          'Pilih batch dengan sisa stok yang masih tersedia.',
                      searchHint: 'Cari batch consign',
                      emptyMessage: 'Belum ada batch yang bisa dititipkan.',
                      options: availableProducts,
                      selectedId: _selectedProductOnhandId,
                      idResolver: (item) =>
                          (item['id_product_onhand'] as num?)?.toInt(),
                      titleResolver: (item) =>
                          item['nama_product']?.toString() ?? 'Produk',
                      subtitleResolver: _consignmentBatchSubtitle,
                      trailingBadgeResolver: (item) =>
                          'Stok ${_asInt(item['available_quantity'])}',
                    ),
                  );
                  if (!mounted || selected == null) {
                    return;
                  }
                  setState(() => _selectedProductOnhandId = selected);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: widget.busy || availableProducts.isEmpty
                        ? null
                        : _addSelectedProduct,
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
              if (widget.products.isEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Belum ada stok batch yang bisa dititipkan.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 14),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['product_name']?.toString() ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _MiniPill(
                                    label:
                                        'Batch ${item['pickup_batch_code'] ?? '-'}',
                                  ),
                                  _MiniPill(
                                    label:
                                        'Maks ${item['available_quantity'] ?? 0}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 88,
                          child: TextFormField(
                            initialValue: '${item['quantity']}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty'),
                            onChanged: (value) {
                              final parsed = int.tryParse(value) ?? 1;
                              final maxQuantity =
                                  (item['available_quantity'] as num?)
                                          ?.toInt() ??
                                      parsed;
                              _items[index]['quantity'] =
                                  parsed.clamp(1, maxQuantity);
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: widget.busy
                              ? null
                              : () => setState(() => _items.removeAt(index)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.busy
                    ? null
                    : () async {
                        final file = await widget.onPickProof();
                        if (!mounted || file == null) return;
                        setState(() => _proof = file);
                      },
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_proof == null ? 'Ambil foto bukti' : _proof!.name),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.busy ||
                          _proof == null ||
                          _items.isEmpty ||
                          _placeController.text.trim().isEmpty ||
                          _addressController.text.trim().isEmpty
                      ? null
                      : () async {
                          final submittedAt = DateTime.now();
                          setState(() => _date = submittedAt);
                          final success = await widget.onSubmit(
                            placeName: _placeController.text.trim(),
                            address: _addressController.text.trim(),
                            consignmentDate: submittedAt,
                            items: _items,
                            proofPhoto: _proof!,
                          );
                          if (!context.mounted || !success) {
                            return;
                          }
                          await showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Consign berhasil'),
                              content: const Text(
                                'Data consign berhasil disimpan. Anda akan kembali ke halaman inventory.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pop();
                        },
                  child: Text(widget.busy ? 'Menyimpan...' : 'Simpan consign'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _consignmentBatchSubtitle(Map<String, dynamic> item) {
    final batch = item['pickup_batch_code']?.toString().trim();
    final fragrance = _productFragranceSummary(item, maxParts: 2);
    if (batch == null || batch.isEmpty) {
      return fragrance ?? 'Detail fragrance belum tersedia';
    }
    if (fragrance == null || fragrance.isEmpty) {
      return 'Batch $batch';
    }
    return 'Batch $batch | $fragrance';
  }
}

class _ConsignmentHistorySheet extends StatelessWidget {
  const _ConsignmentHistorySheet({
    required this.consignments,
    required this.busy,
    required this.dateTime,
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    required this.onUpdateItem,
    this.readOnly = false,
  });

  final List<Map<String, dynamic>> consignments;
  final bool busy;
  final DateFormat dateTime;
  final String title;
  final String subtitle;
  final String emptyMessage;
  final bool readOnly;
  final Future<bool> Function({
    required int itemId,
    required int soldQuantity,
    required int returnedQuantity,
    String? statusNotes,
  }) onUpdateItem;

  @override
  Widget build(BuildContext context) {
    return _AnimatedSheetScaffold(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F1E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 18),
              const _SheetHandle(),
              const SizedBox(height: 16),
              _SheetHeader(
                heroTag: 'inventory-consign-history',
                accent: Color(0xFF7C5B39),
                icon: Icons.history_toggle_off_rounded,
                title: title,
                subtitle: subtitle,
              ),
              Flexible(
                child: consignments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        child: Text(emptyMessage),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        itemCount: consignments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final consignment = consignments[index];
                          final items = ((consignment['items'] as List?) ?? [])
                              .cast<Map<String, dynamic>>();
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x120F0A05),
                                  blurRadius: 18,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        consignment['place_name']?.toString() ??
                                            '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    _StatusChip(
                                      label: '${items.length} item',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(consignment['address']?.toString() ?? '-'),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _MiniPill(
                                      label: _formatConsignmentDate(
                                        consignment['consignment_date']
                                            ?.toString(),
                                        dateTime,
                                      ),
                                    ),
                                    if ((consignment['submitted_at']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ??
                                        false))
                                      _MiniPill(
                                        label:
                                            'Submit ${_formatConsignmentDate(consignment['submitted_at']?.toString(), dateTime)}',
                                      ),
                                  ],
                                ),
                                if (items.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  ...items.map(
                                    (item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _ConsignmentHistoryItemCard(
                                        item: item,
                                        busy: busy,
                                        readOnly: readOnly,
                                        onUpdateItem: onUpdateItem,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsignmentHistoryItemCard extends StatelessWidget {
  const _ConsignmentHistoryItemCard({
    required this.item,
    required this.busy,
    this.readOnly = false,
    required this.onUpdateItem,
  });

  final Map<String, dynamic> item;
  final bool busy;
  final bool readOnly;
  final Future<bool> Function({
    required int itemId,
    required int soldQuantity,
    required int returnedQuantity,
    String? statusNotes,
  }) onUpdateItem;

  @override
  Widget build(BuildContext context) {
    final quantity = _asInt(item['quantity']);
    final soldQuantity = _asInt(item['sold_quantity']);
    final returnedQuantity = _asInt(item['returned_quantity']);
    final activeQuantity = max(quantity - soldQuantity - returnedQuantity, 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['product_name']?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _StatusChip(label: item['status']?.toString() ?? '-'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(label: 'Qty $quantity'),
              _MiniPill(label: 'Terjual $soldQuantity'),
              _MiniPill(label: 'Dikembalikan $returnedQuantity'),
              _MiniPill(label: 'Aktif $activeQuantity'),
              if ((item['pickup_batch_code']?.toString().trim().isNotEmpty ??
                  false))
                _MiniPill(label: 'Batch ${item['pickup_batch_code']}'),
            ],
          ),
          if ((item['status_notes']?.toString().trim().isNotEmpty ??
              false)) ...[
            const SizedBox(height: 8),
            Text(
              item['status_notes'].toString(),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6F665F),
              ),
            ),
          ],
          if (!readOnly) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => _EditConsignmentItemSheet(
                            item: item,
                            onUpdateItem: onUpdateItem,
                          ),
                        ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit status'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditConsignmentItemSheet extends StatefulWidget {
  const _EditConsignmentItemSheet({
    required this.item,
    required this.onUpdateItem,
  });

  final Map<String, dynamic> item;
  final Future<bool> Function({
    required int itemId,
    required int soldQuantity,
    required int returnedQuantity,
    String? statusNotes,
  }) onUpdateItem;

  @override
  State<_EditConsignmentItemSheet> createState() =>
      _EditConsignmentItemSheetState();
}

class _EditConsignmentItemSheetState extends State<_EditConsignmentItemSheet> {
  late final TextEditingController _soldController;
  late final TextEditingController _returnedController;
  late final TextEditingController _notesController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _soldController = TextEditingController(
      text: '${_asInt(widget.item['sold_quantity'])}',
    );
    _returnedController = TextEditingController(
      text: '${_asInt(widget.item['returned_quantity'])}',
    );
    _notesController = TextEditingController(
      text: widget.item['status_notes']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _soldController.dispose();
    _returnedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantity = _asInt(widget.item['quantity']);
    final sold = int.tryParse(_soldController.text.trim()) ?? 0;
    final returned = int.tryParse(_returnedController.text.trim()) ?? 0;
    final active = max(quantity - sold - returned, 0);
    final invalid = sold < 0 || returned < 0 || sold + returned > quantity;
    final mediaQuery = MediaQuery.of(context);
    final safeBottom =
        max(mediaQuery.padding.bottom, mediaQuery.viewPadding.bottom);

    return Material(
      color: const Color(0xFFF7F1E6),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: mediaQuery.viewInsets.bottom + safeBottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            Text(
              widget.item['product_name']?.toString() ?? 'Edit consign',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
                'Total consign $quantity item. Atur jumlah terjual dan dikembalikan per barang.'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _soldController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Terjual'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _returnedController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration:
                        const InputDecoration(labelText: 'Dikembalikan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Catatan status'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniPill(label: 'Qty $quantity'),
                _MiniPill(label: 'Aktif $active'),
                _MiniPill(
                  label: _consignmentStatusLabel(
                    quantity: quantity,
                    soldQuantity: sold,
                    returnedQuantity: returned,
                  ),
                ),
              ],
            ),
            if (invalid) ...[
              const SizedBox(height: 10),
              const Text(
                'Jumlah terjual dan dikembalikan tidak boleh melebihi quantity consign.',
                style: TextStyle(
                  color: Color(0xFFC05D3B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting || invalid
                    ? null
                    : () async {
                        setState(() => _submitting = true);
                        final success = await widget.onUpdateItem(
                          itemId: (widget.item['id'] as num).toInt(),
                          soldQuantity: sold,
                          returnedQuantity: returned,
                          statusNotes: _notesController.text.trim(),
                        );
                        if (!context.mounted || !success) {
                          return;
                        }
                        await showDialog<void>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Berhasil'),
                            content: const Text(
                              'Status consign berhasil diperbarui. Anda akan kembali ke halaman inventory.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pop();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                child: Text(_submitting ? 'Menyimpan...' : 'Simpan perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _consignmentStatusLabel({
  required int quantity,
  required int soldQuantity,
  required int returnedQuantity,
}) {
  if (soldQuantity >= quantity) {
    return 'Terjual';
  }
  if (returnedQuantity >= quantity) {
    return 'Dikembalikan';
  }
  if (soldQuantity > 0 && returnedQuantity > 0) {
    return 'Terjual + dikembalikan';
  }
  if (soldQuantity > 0) {
    return 'Terjual sebagian';
  }
  if (returnedQuantity > 0) {
    return 'Dikembalikan sebagian';
  }
  return 'Masih dititipkan';
}

String _formatConsignmentDate(String? value, DateFormat formatter) {
  if (value == null || value.trim().isEmpty) {
    return '-';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return formatter.format(parsed);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value.map(_asMap).where((item) => item.isNotEmpty).toList();
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ??
        double.tryParse(value.trim())?.toInt() ??
        fallback;
  }
  return fallback;
}

String _startCaseWords(String value) {
  return value
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) =>
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String? _productFragranceSummary(Map<String, dynamic> item,
    {int maxParts = 2}) {
  final details = ((item['fragrance_details'] as List?) ?? const <dynamic>[])
      .cast<Map<String, dynamic>>();
  final labels = <String>[];
  for (final detail in details) {
    final value = detail['detail']?.toString().trim();
    if (value != null && value.isNotEmpty) {
      labels.add(_startCaseWords(value));
    }
  }
  if (labels.isNotEmpty) {
    return labels.take(maxParts).join(', ');
  }

  final description = item['deskripsi']?.toString().trim();
  if (description != null && description.isNotEmpty) {
    return description;
  }

  return null;
}

int _activeConsignmentQuantity(Map<String, dynamic> item) {
  final quantity = _asInt(item['quantity']);
  final soldQuantity = _asInt(item['sold_quantity']);
  final returnedQuantity = _asInt(item['returned_quantity']);
  return max(quantity - soldQuantity - returnedQuantity, 0);
}

List<Map<String, dynamic>> _filterConsignmentsByItemState(
  List<Map<String, dynamic>> consignments,
  bool Function(Map<String, dynamic>) predicate,
) {
  final filtered = <Map<String, dynamic>>[];
  for (final consignment in consignments) {
    final items = ((consignment['items'] as List?) ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    final matchedItems =
        items.where(predicate).map(Map<String, dynamic>.from).toList();
    if (matchedItems.isEmpty) {
      continue;
    }
    filtered.add({
      ...Map<String, dynamic>.from(consignment),
      'items': matchedItems,
    });
  }
  return filtered;
}

String _productImageUrl(Map<String, dynamic> item) {
  final imageUrl = item['image_url']?.toString().trim();
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return imageUrl;
  }
  final fallback = item['gambar']?.toString().trim();
  return fallback ?? '';
}

List<String> _productBadgeLabels(Map<String, dynamic> item) {
  final labels = ((item['badge_labels'] as List?) ?? const <dynamic>[])
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toSet()
      .toList();
  if (labels.isNotEmpty) {
    return labels.take(4).toList();
  }

  final details = ((item['fragrance_details'] as List?) ?? const <dynamic>[])
      .cast<Map<String, dynamic>>();
  final detailLabels = details
      .map((detail) => detail['detail']?.toString().trim() ?? '')
      .where((entry) => entry.isNotEmpty)
      .toSet()
      .toList();
  if (detailLabels.isNotEmpty) {
    return detailLabels.take(4).toList();
  }

  return const <String>[];
}

Future<void> _showProductImageSheet(
    BuildContext context, Map<String, dynamic> item) {
  return showMaterialModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProductImageSheet(
      title: item['nama_product']?.toString() ?? 'Product',
      imageUrl: _productImageUrl(item),
    ),
  );
}

class _ProductImageSheet extends StatelessWidget {
  const _ProductImageSheet({
    required this.title,
    required this.imageUrl,
  });

  final String title;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return _AnimatedSheetScaffold(
      child: SafeArea(
        top: false,
        child: Material(
          color: const Color(0xFFF7F1E6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 18),
              const _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: _KnowledgeImage(imageUrl: imageUrl),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowledgePage extends StatefulWidget {
  const _KnowledgePage({required this.products, required this.loading});

  final List<Map<String, dynamic>> products;
  final bool loading;

  @override
  State<_KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<_KnowledgePage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedFragranceFilters = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _imageUrl(Map<String, dynamic> item) {
    final image = item['gambar']?.toString().trim();
    if (image != null && image.isNotEmpty) {
      return image;
    }
    final fallback = item['image_url']?.toString().trim();
    return fallback ?? '';
  }

  List<String> _badgeLabels(Map<String, dynamic> item) {
    final details = ((item['fragrance_details'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final labels = <String>{};
    for (final detail in details) {
      final value = detail['detail']?.toString().trim();
      final type = detail['jenis']?.toString().trim();
      if (value != null && value.isNotEmpty) {
        labels.add(_startCase(value));
      } else if (type != null && type.isNotEmpty) {
        labels.add(_startCase(type));
      }
    }
    return labels.take(6).toList();
  }

  String _startCase(String value) {
    return value
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  Future<void> _showKnowledgeDetail(Map<String, dynamic> item) {
    return showMaterialModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      expand: false,
      builder: (_) => _KnowledgeDetailSheet(
        item: item,
        imageUrl: _imageUrl(item),
        badges: _badgeLabels(item),
      ),
    );
  }

  List<String> _availableFilters() {
    final filters = <String>{};
    for (final item in widget.products) {
      filters.addAll(_badgeLabels(item));
    }
    final sorted = filters.toList()..sort();
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final availableFilters = _availableFilters();
    final filtered = widget.products.where((item) {
      final name = item['nama_product']?.toString().toLowerCase() ?? '';
      final description = item['deskripsi']?.toString().toLowerCase() ?? '';
      final badgeList = _badgeLabels(item);
      final badges = badgeList.join(' ').toLowerCase();
      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          description.contains(query) ||
          badges.contains(query);
      final matchesFilter = _selectedFragranceFilters.isEmpty ||
          badgeList.any(_selectedFragranceFilters.contains);
      return matchesQuery && matchesFilter;
    }).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Cari product knowledge',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filtered.isEmpty && query.isNotEmpty
                  ? const Icon(Icons.search_off_rounded)
                  : null,
            ),
          ),
          if (availableFilters.isNotEmpty) ...[
            SizedBox(height: 14.h),
            SizedBox(
              height: 42.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableFilters.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final label = availableFilters[index];
                  final selected = _selectedFragranceFilters.contains(label);
                  return FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF2C8C82)
                          : const Color(0xFFE1D7C9),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.86),
                    selectedColor:
                        const Color(0xFF2C8C82).withValues(alpha: 0.14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? const Color(0xFF215E59)
                            : const Color(0xFF5B4E43),
                      ),
                    ),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedFragranceFilters.add(label);
                        } else {
                          _selectedFragranceFilters.remove(label);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
          SizedBox(height: 16.h),
          Expanded(
            child: widget.loading
                ? const _KnowledgeGridSkeleton()
                : widget.products.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada product knowledge yang tersedia saat ini.',
                          style: TextStyle(fontSize: 13.sp),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada product yang cocok dengan kata kunci ini.',
                              style: TextStyle(fontSize: 13.sp),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : MasonryGridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14.h,
                            crossAxisSpacing: 12.w,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _KnowledgeGridTile(
                                item: item,
                                imageUrl: _imageUrl(item),
                                badges: _badgeLabels(item),
                                height: index.isEven ? 210.h : 250.h,
                                onTap: () => _showKnowledgeDetail(item),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeGridTile extends StatelessWidget {
  const _KnowledgeGridTile({
    required this.item,
    required this.imageUrl,
    required this.badges,
    required this.height,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final String imageUrl;
  final List<String> badges;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final heroTag = 'knowledge-image-${item['id_product']}';

    return OpenContainer<void>(
      openColor: Colors.transparent,
      closedColor: Colors.transparent,
      openElevation: 0,
      closedElevation: 0,
      transitionDuration: const Duration(milliseconds: 360),
      openBuilder: (_, __) => const SizedBox.shrink(),
      tappable: false,
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: onTap,
          child: Hero(
            tag: heroTag,
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F0A05),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: _KnowledgeImage(imageUrl: imageUrl),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.12),
                              Colors.black.withValues(alpha: 0.46),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10.w,
                      right: 10.w,
                      bottom: 10.h,
                      child: _KnowledgeBadgeWrap(
                        badges: badges.take(3).toList(),
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KnowledgeDetailSheet extends StatelessWidget {
  const _KnowledgeDetailSheet({
    required this.item,
    required this.imageUrl,
    required this.badges,
  });

  final Map<String, dynamic> item;
  final String imageUrl;
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final details = ((item['fragrance_details'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    return _AnimatedSheetScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(color: Colors.black.withValues(alpha: 0.14)),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Material(
              color: const Color(0xFFF7F1E8).withValues(alpha: 0.9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHandle(),
                    Expanded(
                      child: ListView(
                        children: [
                          Hero(
                            tag: 'knowledge-image-${item['id_product']}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18.r),
                              child: SizedBox(
                                height: 250.h,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _KnowledgeImage(imageUrl: imageUrl),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black
                                                .withValues(alpha: 0.03),
                                            Colors.black.withValues(alpha: 0.1),
                                            Colors.black
                                                .withValues(alpha: 0.42),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 18.h),
                          PageTransitionSwitcher(
                            duration: const Duration(milliseconds: 320),
                            transitionBuilder: (child, primary, secondary) =>
                                FadeScaleTransition(
                              animation: primary,
                              child: child,
                            ),
                            child: Column(
                              key: ValueKey(item['id_product']),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nama_product']?.toString() ?? '-',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24.sp,
                                      ),
                                ),
                                SizedBox(height: 12.h),
                                _KnowledgeBadgeInput(
                                  badges: badges,
                                ),
                                SizedBox(height: 16.h),
                                Container(
                                  padding: EdgeInsets.all(16.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.76),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Text(
                                    item['deskripsi']?.toString() ??
                                        'Belum ada deskripsi product.',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      height: 1.65,
                                    ),
                                  ),
                                ),
                                if (details.isNotEmpty) ...[
                                  SizedBox(height: 16.h),
                                  Text(
                                    'Fragrance Detail',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16.sp,
                                        ),
                                  ),
                                  SizedBox(height: 10.h),
                                  ...details.map((detail) {
                                    final title =
                                        detail['detail']?.toString() ??
                                            detail['jenis']?.toString() ??
                                            '-';
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 10.h),
                                      padding: EdgeInsets.all(14.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.76),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              _KnowledgeDetailBadge(
                                                label: detail['jenis']
                                                        ?.toString()
                                                        .toUpperCase() ??
                                                    'NOTE',
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if ((detail['deskripsi']
                                                  ?.toString()
                                                  .trim()
                                                  .isNotEmpty ??
                                              false)) ...[
                                            SizedBox(height: 8.h),
                                            Text(
                                              detail['deskripsi'].toString(),
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                height: 1.55,
                                                color: const Color(0xFF665C53),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeBadgeInput extends StatelessWidget {
  const _KnowledgeBadgeInput({required this.badges});

  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            filled: false,
          ),
        ),
        child: ChipsInput<String>(
          initialValue: badges,
          initialSuggestions: const [],
          enabled: false,
          decoration: const InputDecoration(
            hintText: '',
          ),
          findSuggestions: (_) => const <String>[],
          onChanged: (_) {},
          chipBuilder: (context, state, data) => Padding(
            padding: EdgeInsets.only(right: 6.w, bottom: 6.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(color: const Color(0xFFE5DACB)),
              ),
              child: Text(
                data,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4F4338),
                ),
              ),
            ),
          ),
          suggestionBuilder: (context, state, data) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _KnowledgeBadgeWrap extends StatelessWidget {
  const _KnowledgeBadgeWrap({required this.badges, this.compact = false});

  final List<String> badges;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: badges.map((badge) {
        return Container(
          constraints: BoxConstraints(maxWidth: compact ? 84.w : 120.w),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8.w : 10.w,
            vertical: compact ? 4.h : 6.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            badge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 10.sp : 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF41352A),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KnowledgeDetailBadge extends StatelessWidget {
  const _KnowledgeDetailBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE4D4),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: const Color(0xFF5A4C3C),
        ),
      ),
    );
  }
}

class _KnowledgeImage extends StatelessWidget {
  const _KnowledgeImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _KnowledgeImageFallback();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => const _KnowledgeImageShimmer(),
      errorWidget: (_, __, ___) => _KnowledgeImageFallback(),
    );
  }
}

class _KnowledgeImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDE1CF), Color(0xFFC7AB7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Icon(
                Icons.spa_outlined,
                size: 28.sp,
                color: const Color(0xFF7A6242),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Sweetie',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A3B2B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeImageShimmer extends StatelessWidget {
  const _KnowledgeImageShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8DDD0),
      highlightColor: const Color(0xFFF6F0E8),
      child: Container(
        color: const Color(0xFFE8DDD0),
      ),
    );
  }
}

class _KnowledgeGridSkeleton extends StatelessWidget {
  const _KnowledgeGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14.h,
      crossAxisSpacing: 12.w,
      itemCount: 6,
      itemBuilder: (_, index) => ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: SizedBox(
          height: index.isEven ? 210.h : 250.h,
          child: const _KnowledgeImageShimmer(),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.accent});

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F0A05),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F4030),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(color: Color(0xFF72552B)))),
          const Text(': '),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label,
      required this.value,
      required this.valueColor,
      this.emphasized = false});

  final String label;
  final String value;
  final Color valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(color: valueColor.withValues(alpha: 0.82)))),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              fontSize: emphasized ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E0B7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8F1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFE6D7C2)),
      ),
      child: Text(label),
    );
  }
}

class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({
    required this.title,
    required this.maxQuantity,
    required this.ctaLabel,
    required this.onSubmit,
    this.successMessage,
    this.closeDepth = 1,
  }) : initialQuantity = 1;

  final String title;
  final int maxQuantity;
  final String ctaLabel;
  final Future<bool> Function(int quantity) onSubmit;
  final int initialQuantity;
  final String? successMessage;
  final int closeDepth;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final TextEditingController _controller;
  bool _submitting = false;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity.clamp(1, widget.maxQuantity);
    _controller = TextEditingController(text: '$_quantity');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safeBottom =
        max(mediaQuery.padding.bottom, mediaQuery.viewPadding.bottom);

    return Material(
      color: const Color(0xFFF7F1E6),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: mediaQuery.viewInsets.bottom + safeBottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            Text(widget.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Maksimal ${widget.maxQuantity} item.'),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _StepperButton(
                        icon: Icons.remove_rounded,
                        onTap: _submitting || _quantity <= 1
                            ? null
                            : () {
                                setState(() {
                                  _quantity -= 1;
                                  _controller.text = '$_quantity';
                                });
                              },
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$_quantity',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'item',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7C7269),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add_rounded,
                        onTap: _submitting || _quantity >= widget.maxQuantity
                            ? null
                            : () {
                                setState(() {
                                  _quantity += 1;
                                  _controller.text = '$_quantity';
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Quantity manual'),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed == null) {
                        return;
                      }
                      setState(() {
                        _quantity = parsed.clamp(1, widget.maxQuantity);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        final qty = int.tryParse(_controller.text) ?? 0;
                        if (qty < 1 || qty > widget.maxQuantity) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Quantity tidak valid.')),
                          );
                          return;
                        }
                        setState(() => _submitting = true);
                        final success = await widget.onSubmit(qty);
                        if (!context.mounted) return;
                        if (!success) {
                          setState(() => _submitting = false);
                          return;
                        }
                        if (widget.successMessage != null &&
                            widget.successMessage!.trim().isNotEmpty) {
                          await showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Berhasil'),
                              content: Text(widget.successMessage!),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                        if (!context.mounted) return;
                        for (var index = 0;
                            index < widget.closeDepth;
                            index++) {
                          if (!Navigator.of(context).canPop()) {
                            break;
                          }
                          Navigator.of(context).pop();
                        }
                      },
                child: Text(_submitting ? 'Memproses...' : widget.ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color:
              onTap == null ? const Color(0xFFF1ECE4) : const Color(0xFFEEE4D5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color:
              onTap == null ? const Color(0xFFB8AEA4) : const Color(0xFF4A3B2B),
        ),
      ),
    );
  }
}
