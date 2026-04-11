import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
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
  runApp(const SmoothiesSweetieApp());
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
      seedColor: const Color(0xFFC18B2F),
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
          scaffoldBackgroundColor: const Color(0xFFF7F1E8),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            Typography.blackMountainView,
          ).apply(
            bodyColor: const Color(0xFF2B2117),
            displayColor: const Color(0xFF2B2117),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            shadowColor: const Color(0x1A7A4E19),
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
                    ? const Color(0xFF2B2117)
                    : const Color(0xFF7C6751),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              return IconThemeData(
                size: 24,
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFF2B2117)
                    : const Color(0xFF7C6751),
              );
            }),
            indicatorColor: const Color(0xFFF0D7A1),
            indicatorShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF9F5EE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE8DCCB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: Color(0xFFC18B2F), width: 1.4),
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
      'onhands': [
        {
          'id_product_onhand': 91,
          'id_product': 1,
          'nama_product': 'Berry Bliss Smoothie',
          'quantity': 4,
          'quantity_dikembalikan': 0,
          'remaining_quantity': 3,
          'take_status': 'disetujui',
          'take_status_label': 'Disetujui',
          'return_status': 'belum',
          'return_status_label': 'Belum retur',
          'status_label': 'Masih dibawa',
          'assignment_date': _formatYmd(now),
          'sold_out': false,
          'can_checkout': false,
          'max_return': 3,
        },
        {
          'id_product_onhand': 92,
          'id_product': 2,
          'nama_product': 'Mango Sunshine Smoothie',
          'quantity': 3,
          'quantity_dikembalikan': 0,
          'remaining_quantity': 2,
          'take_status': 'pending',
          'take_status_label': 'Pending',
          'return_status': 'belum',
          'return_status_label': 'Belum retur',
          'status_label': 'Menunggu approval',
          'assignment_date': _formatYmd(now),
          'sold_out': false,
          'can_checkout': false,
          'max_return': 2,
        },
      ],
      'today_return_items': [],
    };
    _sales = {
      'sales': [
        {
          'transaction_code': 'TRX-20260402-AVN001',
          'sale_number':
              '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} - 1',
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
      'qris_image_url': null,
      'is_smoothies_sweetie': true,
    };
    _consignments = {
      'products': [
        {
          'id_product_onhand': 91,
          'id_product': 1,
          'nama_product': 'Berry Bliss Smoothie',
          'pickup_batch_code': 'PICK-20260408-U4-O91',
          'available_quantity': 3,
          'option_label':
              'Berry Bliss Smoothie | batch PICK-20260408-U4-O91 | sisa 3',
        },
      ],
      'consignments': [
        {
          'id': 11,
          'place_name': 'Toko Melati',
          'address': 'Jl. Melati No. 8, Jakarta Barat',
          'consignment_date': _formatYmd(now),
          'submitted_at':
              _formatYmdHis(now.subtract(const Duration(minutes: 20))),
          'handover_proof_photo_url': null,
          'items': [
            {
              'id': 91,
              'product_onhand_id': 91,
              'product_name': 'Berry Bliss Smoothie',
              'pickup_batch_code': 'PICK-20260408-U4-O91',
              'quantity': 2,
              'sold_quantity': 0,
              'returned_quantity': 0,
              'status': 'dititipkan',
              'status_notes': null,
            }
          ],
        }
      ],
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
    final onHandCount =
        onhands.where(_isCountedAsOnHand).fold<int>(0, (sum, item) {
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
        'remaining': remaining,
        'image_url': product['image_url'],
        'badge_labels': product['badge_labels'],
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
      final me = (meResponse.data as Map<String, dynamic>)['user']
              as Map<String, dynamic>? ??
          {};
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
      ];
      final results = await Future.wait(futures);

      if (!mounted) return;
      setState(() {
        _me = me;
        _dashboard = results[0].data as Map<String, dynamic>;
        _attendance = results[1].data as Map<String, dynamic>;
        _products = results[2].data as Map<String, dynamic>;
        _sales = results[3].data as Map<String, dynamic>;
        _consignments = results[4].data as Map<String, dynamic>;
        _knowledge = results[5].data as Map<String, dynamic>;
        _notifications = results[6].data as Map<String, dynamic>;
        _syncDerivedConsignmentInventoryState();
      });
      await NotificationScheduler.instance.syncServerNotifications(
        ((_notifications?['notifications'] as List?) ?? [])
            .cast<Map<String, dynamic>>(),
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
      await _SalesSubmitService.submit(
        dio: _dio,
        mockMode: _mockMode,
        salesPayload: _sales,
        productsPayload: _products,
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
      _showMessage('Penjualan offline berhasil disimpan.');
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

  Future<XFile?> _pickProof() async {
    if (_mockMode) {
      return XFile('mock-proof.jpg', name: 'mock-proof.jpg');
    }
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
  }

  Future<XFile?> _pickConsignmentProof() async {
    if (_mockMode) {
      return XFile('mock-consignment-proof.jpg',
          name: 'mock-consignment-proof.jpg');
    }
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 82);
  }

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

  Future<void> _showSalesQrSheet() async {
    final qrUrl = _me?['sales_qr_url']?.toString().trim() ?? '';

    if (!mounted) {
      return;
    }

    return showMaterialModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SalesQrSheet(
        qrUrl: qrUrl,
        qrName: _me?['sales_qr_name']?.toString(),
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

    final stats = _dashboard?['stats'] as Map<String, dynamic>? ?? {};
    final todayAttendance =
        _attendance?['today_attendance'] as Map<String, dynamic>? ?? {};
    final onhands =
        ((_products?['onhands'] as List?) ?? []).cast<Map<String, dynamic>>();
    final historyOnhands = ((_products?['history_onhands'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final availableProducts =
        ((_products?['products'] as List?) ?? []).cast<Map<String, dynamic>>();
    final sales =
        ((_sales?['sales'] as List?) ?? []).cast<Map<String, dynamic>>();
    final salesProducts =
        ((_sales?['products'] as List?) ?? []).cast<Map<String, dynamic>>();
    final promos =
        ((_sales?['promos'] as List?) ?? []).cast<Map<String, dynamic>>();
    final salesExtraToppings = ((_sales?['extra_toppings'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final salesSops =
        ((_sales?['sops'] as List?) ?? []).cast<Map<String, dynamic>>();
    final isSmoothiesSweetie =
        (_sales?['is_smoothies_sweetie'] as bool?) ?? false;
    final salesQrisImageUrl = _sales?['qris_image_url']?.toString();
    final knowledge =
        ((_knowledge?['products'] as List?) ?? []).cast<Map<String, dynamic>>();
    final consignProducts = ((_consignments?['products'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final consignments = ((_consignments?['consignments'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final notifications = ((_notifications?['notifications'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final recentAttendances =
        ((_attendance?['recent_attendances'] as List?) ?? [])
            .cast<Map<String, dynamic>>();

    final isSalesFieldExecutive =
        (_me?['role']?.toString() ?? '') == 'sales_field_executive';

    final pages = <Widget>[
      _DashboardPage(
        me: _me ?? const {},
        dashboard: _dashboard ?? const {},
        stats: stats,
        todayAttendance: todayAttendance,
        recentAttendances: recentAttendances,
        sales: sales,
        currency: _currency,
        onNavigate: (index) => setState(() => _navigationIndex = index),
      ),
      _AttendancePage(
        todayAttendance: todayAttendance,
        recentAttendances: recentAttendances,
        latestLocation:
            _attendance?['latest_location'] as Map<String, dynamic>?,
        manualLocationLabel: _locationLabel,
        busy: _busy,
        onSubmitAttendance: _submitAttendance,
      ),
      _InventoryPage(
        products: availableProducts,
        onhands: onhands,
        historyOnhands: historyOnhands,
        consignmentProducts: isSalesFieldExecutive ? consignProducts : null,
        consignments: isSalesFieldExecutive ? consignments : null,
        attendanceBlockedReason:
            _products?['attendance_blocked_reason']?.toString(),
        busy: _busy,
        currency: _currency,
        dateTime: _dateTime,
        onTake: _requestTake,
        onReturn: _requestReturn,
        onPickConsignmentProof:
            isSalesFieldExecutive ? _pickConsignmentProof : null,
        onSubmitConsignment: isSalesFieldExecutive ? _submitConsignment : null,
        onUpdateConsignmentItem:
            isSalesFieldExecutive ? _updateConsignmentItem : null,
      ),
      SmoothiesSalesPageModule(
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
      ),
      _KnowledgePage(
        products: knowledge,
        loading: _knowledge == null && _busy,
      ),
    ];
    final destinations = <NavigationDestination>[
      const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard'),
      const NavigationDestination(
          icon: Icon(Icons.fingerprint_outlined),
          selectedIcon: Icon(Icons.fingerprint),
          label: 'Absensi'),
      const NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Inventory'),
      const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Sales'),
      const NavigationDestination(
          icon: Icon(Icons.auto_stories_outlined),
          selectedIcon: Icon(Icons.auto_stories),
          label: 'Knowledge'),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4E3C6), Color(0xFFF7F1E8), Color(0xFFF6EFE6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBanner(
                title: _pageTitle(_navigationIndex),
                subtitle: _pageSubtitle(_navigationIndex),
                me: _me ?? const {},
                mockMode: _mockMode,
                busy: _busy,
                accent: _pageAccent(_navigationIndex),
                icon: _pageIcon(_navigationIndex),
                compact: true,
                onRefresh: () => _refreshAll(showLoader: true),
                onSalesQr: _showSalesQrSheet,
                onNotifications: () => _showNotificationsSheet(notifications),
                notificationCount: _unreadNotificationCount,
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
                    key: ValueKey(_navigationIndex),
                    child: pages[_navigationIndex],
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
                selectedIndex: _navigationIndex,
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
    if (index == 1) return 'Absensi Shift';
    if (index == 2) return 'Katalog Produk';
    if (index == 3) return 'Penjualan Offline';
    if (index == 4) {
      return 'Menu Knowledge';
    }
    return 'Dashboard Sweetie';
  }

  String _pageSubtitle(int index) {
    if (index == 1) {
      return 'Check in, check out, dan kirim lokasi operasional dengan cepat.';
    }
    if (index == 2) {
      return 'Lihat katalog menu dan pantau data produk Smoothies Sweetie dari satu menu.';
    }
    if (index == 3) {
      return 'Input customer, smoothie, size, topping, dan QRIS dalam satu flow native.';
    }
    if (index == 4) {
      return 'Ringkasan menu, bahan, dan selling points untuk bantu pelayanan di booth.';
    }
    return 'Ringkasan target, aktivitas, dan performa toko hari ini.';
  }

  Color _pageAccent(int index) {
    if (index == 1) return const Color(0xFFC05D3B);
    if (index == 2) return const Color(0xFF6E8B3D);
    if (index == 3) return const Color(0xFF8E5BD9);
    if (index == 4) {
      return const Color(0xFF2C8C82);
    }
    return const Color(0xFFC18B2F);
  }

  IconData _pageIcon(int index) {
    if (index == 1) return Icons.fingerprint_rounded;
    if (index == 2) return Icons.inventory_2_rounded;
    if (index == 3) return Icons.receipt_long_rounded;
    if (index == 4) {
      return Icons.auto_stories_rounded;
    }
    return Icons.dashboard_rounded;
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A2712), Color(0xFF8A6324), Color(0xFFF0D3A4)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                                  backgroundColor: const Color(0xFF2B2117),
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
      ),
    );
  }
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
    required this.onSalesQr,
    required this.onNotifications,
    required this.notificationCount,
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
  final VoidCallback onSalesQr;
  final VoidCallback onNotifications;
  final int notificationCount;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
        child: Row(
          children: [
            _TopActionButton(
              tooltip: 'Lihat QR Code',
              onPressed: onSalesQr,
              child: const Icon(Icons.qr_code_2_rounded),
            ),
            const SizedBox(width: 10),
            badges.Badge(
              position: badges.BadgePosition.topEnd(top: -8, end: -8),
              showBadge: notificationCount > 0,
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Color(0xFFC05D3B),
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
            const Spacer(),
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
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: busy ? null : onRefresh,
                icon: busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync),
                label: Text(busy ? 'Memuat...' : 'Sync Data'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    required this.onNavigate,
  });

  final Map<String, dynamic> me;
  final Map<String, dynamic> dashboard;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> todayAttendance;
  final List<Map<String, dynamic>> recentAttendances;
  final List<Map<String, dynamic>> sales;
  final NumberFormat currency;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
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
    required this.todayAttendance,
    required this.recentAttendances,
    required this.latestLocation,
    required this.manualLocationLabel,
    required this.busy,
    required this.onSubmitAttendance,
  });

  final Map<String, dynamic> todayAttendance;
  final List<Map<String, dynamic>> recentAttendances;
  final Map<String, dynamic>? latestLocation;
  final String? manualLocationLabel;
  final bool busy;
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
}

class _InventoryPage extends StatelessWidget {
  const _InventoryPage({
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
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerSocialController =
      TextEditingController();
  late final List<_SaleItemDraft> _items;
  Timer? _customerLookupDebounce;
  int? _promoId;
  XFile? _proof;
  String _paymentMethod = 'Cash';
  bool _lookingUpCustomer = false;
  String? _customerLookupHint;
  final Set<String> _completedSopChecklist = <String>{};

  @override
  void initState() {
    super.initState();
    final firstProductId = widget.products.isEmpty
        ? null
        : (widget.products.first['id_product'] as num?)?.toInt();
    final firstProduct =
        firstProductId == null ? null : _productById(firstProductId);
    _items = [
      _SaleItemDraft(
        productId: firstProductId,
        variantId: _defaultVariantId(firstProduct),
        extraToppingIds: const [],
        quantity: 1,
      )
    ];
  }

  @override
  void dispose() {
    _customerLookupDebounce?.cancel();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerSocialController.dispose();
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
    final seen = <int>{};

    for (final item in _items) {
      if (item.productId == null || item.quantity < 1) {
        return true;
      }

      if (_variantsForProduct(item.productId).isNotEmpty &&
          item.variantId == null) {
        return true;
      }

      if (!widget.isSmoothiesSweetie && !seen.add(item.productId!)) {
        return true;
      }
    }

    return false;
  }

  bool get _hasDuplicateProducts {
    if (widget.isSmoothiesSweetie) {
      return false;
    }

    final seen = <int>{};

    for (final item in _items) {
      final productId = item.productId;
      if (productId == null) {
        continue;
      }

      if (!seen.add(productId)) {
        return true;
      }
    }

    return false;
  }

  String _productLabel(Map<String, dynamic> product) {
    final label = product['option_label']?.toString().trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }

    final name = product['nama_product']?.toString() ?? 'Produk';
    final remaining = (product['remaining'] as num?)?.toInt() ?? 0;
    return '$name | Sisa $remaining';
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

  String _promoLabel(Map<String, dynamic> promo) {
    final label = promo['option_label']?.toString().trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }

    final name = promo['nama_promo']?.toString() ?? 'Promo';
    final code = promo['kode_promo']?.toString().trim();
    return code == null || code.isEmpty ? name : '$name | $code';
  }

  void _scheduleCustomerLookup(String value) {
    _customerLookupDebounce?.cancel();
    final normalized = value.replaceAll(RegExp(r'[^0-9+]'), '').trim();

    if (normalized.length < 8) {
      setState(() {
        _lookingUpCustomer = false;
        _customerLookupHint = null;
      });
      return;
    }

    _customerLookupDebounce =
        Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;

      setState(() {
        _lookingUpCustomer = true;
        _customerLookupHint = 'Mencari data customer...';
      });

      try {
        final customer = await widget.onLookupCustomer(normalized);
        if (!mounted) return;

        if (customer == null) {
          setState(() {
            _lookingUpCustomer = false;
            _customerLookupHint =
                'Customer belum terdaftar. Silakan isi data baru.';
          });
          return;
        }

        final foundPhone = customer['no_telp']?.toString().trim();
        if (foundPhone != null && foundPhone.isNotEmpty) {
          _customerPhoneController.text = foundPhone;
          _customerPhoneController.selection = TextSelection.fromPosition(
            TextPosition(offset: _customerPhoneController.text.length),
          );
        }

        final foundName = customer['nama']?.toString().trim();
        if (foundName != null && foundName.isNotEmpty) {
          _customerNameController.text = foundName;
          _customerNameController.selection = TextSelection.fromPosition(
            TextPosition(offset: _customerNameController.text.length),
          );
        }

        final social = customer['tiktok_instagram']?.toString().trim();
        if (social != null && social.isNotEmpty) {
          _customerSocialController.text = social;
          _customerSocialController.selection = TextSelection.fromPosition(
            TextPosition(offset: _customerSocialController.text.length),
          );
        }

        setState(() {
          _lookingUpCustomer = false;
          _customerLookupHint =
              'Customer ditemukan. Nama dan sosial terisi otomatis.';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _lookingUpCustomer = false;
          _customerLookupHint = 'Gagal mengambil data customer.';
        });
      }
    });
  }

  Future<void> _showSalesHistorySheet(BuildContext context) =>
      showSmoothiesSalesHistorySheet(
        context,
        sales: widget.sales,
        currency: widget.currency,
      );

  Future<void> _pickProductForIndex(int index) async {
    if (widget.products.isEmpty) {
      return;
    }

    final selectableProducts = widget.isSmoothiesSweetie
        ? widget.products
        : widget.products.where((item) {
            final selectedByOthers = _items
                .asMap()
                .entries
                .where((entry) => entry.key != index)
                .map((entry) => entry.value.productId)
                .whereType<int>()
                .toSet();
            final productId = (item['id_product'] as num?)?.toInt();
            return productId == null || !selectedByOthers.contains(productId);
          }).toList();

    if (selectableProducts.isEmpty) {
      return;
    }

    final selected = await _showSmoothiesSalesOptionSheet(
      context: context,
      heroTag: 'sales-product-$index',
      accent: const Color(0xFF8E5BE8),
      icon: Icons.inventory_2_outlined,
      title: 'Pilih Produk',
      subtitle: 'Pilih barang yang akan dijual dari stok on hand Anda.',
      searchHint: 'Cari product',
      emptyMessage: 'Belum ada product yang bisa dipilih.',
      options: selectableProducts,
      selectedId: _items[index].productId,
      idResolver: (item) => (item['id_product'] as num?)?.toInt(),
      titleResolver: _productLabel,
      subtitleResolver: (item) {
        final price =
            widget.currency.format((item['harga'] as num?)?.toDouble() ?? 0);
        return 'Harga $price';
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      final product = _productById(selected);
      _items[index] = _items[index].copyWith(
        productId: selected,
        variantId: _defaultVariantId(product),
        extraToppingIds: const [],
      );
    });
  }

  Future<void> _pickVariantForIndex(int index) async {
    final variants = _variantsForProduct(_items[index].productId);
    if (variants.isEmpty) {
      return;
    }

    final selected = await _showSmoothiesSalesOptionSheet(
      context: context,
      heroTag: 'sales-variant-$index',
      accent: const Color(0xFF4A8F74),
      icon: Icons.local_drink_outlined,
      title: 'Pilih Size',
      subtitle: 'Pilih varian gelas yang akan dipakai di transaksi ini.',
      searchHint: 'Cari size',
      emptyMessage: 'Belum ada size untuk produk ini.',
      options: variants,
      selectedId: _items[index].variantId,
      idResolver: (item) => (item['id'] as num?)?.toInt(),
      titleResolver: _variantLabel,
      subtitleResolver: (item) {
        final ml = (item['total_satuan_ml'] as num?)?.toDouble();
        return ml == null ? null : '${ml.toStringAsFixed(0)} ml';
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _items[index] = _items[index].copyWith(variantId: selected);
    });
  }

  Future<void> _pickExtraToppingsForIndex(int index) async {
    if (widget.extraToppings.isEmpty) {
      return;
    }

    final selected = await _showSmoothiesSalesMultiSelectSheet(
      context: context,
      heroTag: 'sales-toppings-$index',
      accent: const Color(0xFFC05D3B),
      icon: Icons.bubble_chart_outlined,
      title: 'Pilih Extra Topping',
      subtitle: 'Tentukan topping tambahan untuk item ini.',
      options: widget.extraToppings,
      selectedIds: _items[index].extraToppingIds,
      idResolver: (item) => (item['id'] as num?)?.toInt(),
      titleResolver: (item) => item['name']?.toString() ?? 'Extra topping',
      subtitleResolver: (item) =>
          widget.currency.format((item['price'] as num?)?.toDouble() ?? 0),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _items[index] = _items[index].copyWith(extraToppingIds: selected);
    });
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

  Future<void> _pickQuantityForIndex(int index) async {
    final selectedProduct = _productById(_items[index].productId);
    final maxQuantity = selectedProduct == null
        ? 99
        : ((selectedProduct['remaining'] as num?)?.toInt() ?? 0);

    if (selectedProduct != null && maxQuantity < 1) {
      return;
    }

    await showMaterialModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuantitySheet(
        title: selectedProduct == null
            ? 'Atur quantity'
            : 'Qty ${selectedProduct['nama_product']}',
        maxQuantity: maxQuantity < 1 ? 99 : maxQuantity,
        initialQuantity: _items[index].quantity,
        ctaLabel: 'Gunakan quantity ini',
        onSubmit: (qty) async {
          if (!mounted) {
            return false;
          }
          setState(() {
            _items[index] = _items[index].copyWith(quantity: qty);
          });
          return true;
        },
      ),
    );
  }

  double get _subtotal {
    double sum = 0;
    for (final item in _items) {
      final product = _productById(item.productId);
      if (product != null) {
        final variant = _variantById(item.productId, item.variantId);
        final unitPrice = ((variant?['price'] as num?)?.toDouble() ??
                (product['harga'] as num?)?.toDouble() ??
                0)
            .toDouble();
        final toppingTotal = item.extraToppingIds.fold<double>(
          0,
          (sum, id) =>
              sum +
              ((_extraToppingById(id)?['price'] as num?)?.toDouble() ?? 0),
        );
        sum += (unitPrice + toppingTotal) * item.quantity;
      }
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
        final variant = _variantById(item.productId, item.variantId);
        final toppingLabel = item.extraToppingIds.isEmpty
            ? ''
            : ' + ${_toppingSummary(item.extraToppingIds)}';
        names.add(
          '${product['nama_product'] ?? 'Produk'}${variant?['name'] != null ? ' ${variant?['name']}' : ''}$toppingLabel x${item.quantity}',
        );
      }
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _BlockCard(
          title: 'Penjualan',
          subtitle:
              'Input customer, item, promo, dan bukti pembelian dalam satu flow yang ringkas.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _customerPhoneController,
                keyboardType: TextInputType.phone,
                onChanged: _scheduleCustomerLookup,
                decoration: InputDecoration(
                  labelText: 'Nomor telepon',
                  suffixIcon: _lookingUpCustomer
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'Nama customer'),
              ),
              if (_customerLookupHint != null) ...[
                const SizedBox(height: 8),
                PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, primary, secondary) {
                    return SharedAxisTransition(
                      animation: primary,
                      secondaryAnimation: secondary,
                      transitionType: SharedAxisTransitionType.vertical,
                      fillColor: Colors.transparent,
                      child: child,
                    );
                  },
                  child: Container(
                    key: ValueKey(_customerLookupHint),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F1E6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _customerLookupHint!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _customerSocialController,
                decoration:
                    const InputDecoration(labelText: 'TikTok / Instagram'),
              ),
              if (widget.products.isEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F1E6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Produk belum bisa dipilih karena belum ada barang on hand yang disetujui dan masih punya sisa stok untuk dijual.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...List.generate(_items.length, (index) {
                final selectedProduct = _productById(_items[index].productId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCF8F1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PickerField(
                          fieldKey: ValueKey('sales-product-picker-$index'),
                          heroTag: 'sales-product-$index',
                          accent: const Color(0xFF8E5BE8),
                          icon: Icons.inventory_2_outlined,
                          label: 'Produk ${index + 1}',
                          title: selectedProduct == null
                              ? 'Pilih produk'
                              : selectedProduct['nama_product']?.toString() ??
                                  'Produk',
                          subtitle: selectedProduct == null
                              ? 'Tap untuk membuka daftar product'
                              : _productLabel(selectedProduct),
                          enabled: widget.products.isNotEmpty,
                          onTap: () => _pickProductForIndex(index),
                        ),
                        const SizedBox(height: 12),
                        if (_variantsForProduct(_items[index].productId)
                            .isNotEmpty) ...[
                          _PickerField(
                            fieldKey: ValueKey('sales-variant-picker-$index'),
                            heroTag: 'sales-variant-$index',
                            accent: const Color(0xFF4A8F74),
                            icon: Icons.local_drink_outlined,
                            label: 'Size',
                            title: _variantById(
                                  _items[index].productId,
                                  _items[index].variantId,
                                )?['name']
                                    ?.toString() ??
                                'Pilih size',
                            subtitle: _variantById(
                                      _items[index].productId,
                                      _items[index].variantId,
                                    ) ==
                                    null
                                ? 'Tap untuk memilih size'
                                : _variantLabel(
                                    _variantById(
                                      _items[index].productId,
                                      _items[index].variantId,
                                    )!,
                                  ),
                            enabled: selectedProduct != null,
                            onTap: () => _pickVariantForIndex(index),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (widget.isSmoothiesSweetie) ...[
                          _PickerField(
                            fieldKey: ValueKey('sales-toppings-picker-$index'),
                            heroTag: 'sales-toppings-$index',
                            accent: const Color(0xFFC05D3B),
                            icon: Icons.bubble_chart_outlined,
                            label: 'Extra topping',
                            title: _items[index].extraToppingIds.isEmpty
                                ? 'Tanpa extra topping'
                                : '${_items[index].extraToppingIds.length} topping',
                            subtitle:
                                _toppingSummary(_items[index].extraToppingIds),
                            enabled: widget.extraToppings.isNotEmpty &&
                                selectedProduct != null,
                            onTap: () => _pickExtraToppingsForIndex(index),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedProduct == null
                                    ? 'Pilih produk terlebih dahulu.'
                                    : _productLabel(selectedProduct),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6F665F),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_items[index].extraToppingIds.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _toppingSummary(
                                      _items[index].extraToppingIds),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6F665F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                            if (_items.length > 1) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () =>
                                    setState(() => _items.removeAt(index)),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Hapus item',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        _PickerField(
                          fieldKey: ValueKey('sales-quantity-picker-$index'),
                          heroTag: 'sales-qty-$index',
                          accent: const Color(0xFF4A8F74),
                          icon: Icons.exposure_plus_1_rounded,
                          label: 'Quantity',
                          title: '${_items[index].quantity} item',
                          subtitle: selectedProduct == null
                              ? 'Tap untuk mengatur quantity'
                              : 'Maks. ${((selectedProduct['remaining'] as num?)?.toInt() ?? 0)} item',
                          enabled: selectedProduct != null,
                          onTap: () => _pickQuantityForIndex(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                key: const ValueKey('sales-add-item-button'),
                onPressed: (!widget.isSmoothiesSweetie &&
                        _items.length >= widget.products.length)
                    ? null
                    : () => setState(() => _items.add(
                          const _SaleItemDraft(
                            productId: null,
                            variantId: null,
                            extraToppingIds: [],
                            quantity: 1,
                          ),
                        )),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tambah item'),
              ),
              if (_hasDuplicateProducts) ...[
                const SizedBox(height: 8),
                const Text(
                  'Setiap product hanya boleh dipilih satu kali dalam satu transaksi.',
                  style: TextStyle(
                    color: Color(0xFFC05D3B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
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
                  setState(() => _paymentMethod = selected);
                },
              ),
              if (_paymentMethod == 'Qris') ...[
                const SizedBox(height: 10),
                Container(
                  key: const ValueKey('sales-qris-panel'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCEE6DD)),
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
                      if ((widget.qrisImageUrl ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CachedNetworkImage(
                            imageUrl: widget.qrisImageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
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
                    color: const Color(0xFFF7F1E6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Syarat promo: min ${(_selectedPromo!['minimal_quantity'] as num?)?.toInt() ?? 0} item, min belanja ${widget.currency.format((_selectedPromo!['minimal_belanja'] as num?)?.toDouble() ?? 0)}.',
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: widget.busy
                          ? null
                          : () async {
                              final file = await widget.onPickProof();
                              if (!mounted) return;
                              setState(() => _proof = file);
                            },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _proof == null
                            ? (widget.isSmoothiesSweetie
                                ? 'Bukti pembelian opsional'
                                : 'Pilih bukti pembelian')
                            : _proof!.name,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.mockMode || widget.isSmoothiesSweetie) ...[
                const SizedBox(height: 10),
                Text(
                  widget.isSmoothiesSweetie
                      ? 'Mode Smoothies memperbolehkan transaksi tanpa upload bukti pembelian.'
                      : 'Mode demo akan memakai placeholder proof jika Anda tidak memilih gambar.',
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2117),
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
                  color: const Color(0xFFF7F1E6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7DDD0)),
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
                        color: Color(0xFF6F665F),
                      ),
                    ),
                    if (_selectedItemNames.length > 3) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${_selectedItemNames.length - 3} item lainnya',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6F665F),
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
                    color: const Color(0xFFF7F1E6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7DDD0)),
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
                          (!widget.mockMode &&
                              !widget.isSmoothiesSweetie &&
                              _proof == null)
                      ? null
                      : () => widget.onSubmit(
                            customerName: _customerNameController.text.trim(),
                            customerPhone: _customerPhoneController.text.trim(),
                            customerSocial:
                                _customerSocialController.text.trim(),
                            items: List<_SaleItemDraft>.from(_items),
                            paymentMethod: _paymentMethod,
                            requireProof: !widget.isSmoothiesSweetie,
                            promoId: _promoId,
                            proof: _proof,
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
        const SizedBox(height: 16),
        InkWell(
          key: const ValueKey('sales-history-trigger'),
          borderRadius: BorderRadius.circular(30),
          onTap: () => _showSalesHistorySheet(context),
          child: _BlockCard(
            title: 'Riwayat Transaksi',
            subtitle: 'Tap untuk melihat semua transaksi dalam modal sheet.',
            child: PageTransitionSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, primary, secondary) {
                return SharedAxisTransition(
                  animation: primary,
                  secondaryAnimation: secondary,
                  transitionType: SharedAxisTransitionType.scaled,
                  fillColor: Colors.transparent,
                  child: child,
                );
              },
              child: widget.sales.isEmpty
                  ? const Text(
                      'Belum ada transaksi. Riwayat akan muncul di sini saat penjualan pertama masuk.',
                      key: ValueKey('sales-history-empty'),
                    )
                  : Container(
                      key: ValueKey('sales-history-preview'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCF8F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1E4C7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.receipt_long_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.sales.length} transaksi tersimpan',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Terbaru: ${widget.sales.first['transaction_code']?.toString() ?? '-'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_up_rounded),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
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
                                            '${item['nama_product'] ?? '-'} x${item['quantity'] ?? 0}${(((item['extra_toppings'] as List?) ?? []).isEmpty) ? '' : ' • ${((item['extra_toppings'] as List?) ?? []).cast<Map<String, dynamic>>().map((topping) => topping['name']).whereType<String>().join(', ')}'}',
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
    this.initialQuantity = 1,
    this.successMessage,
    this.closeDepth = 1,
  });

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
