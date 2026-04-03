import 'dart:async';
import 'dart:developer' as developer;
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

const String kApiBaseUrl = String.fromEnvironment(
  'AVENOR_API_BASE_URL',
  defaultValue: 'https://avenorperfume.site/api/mobile',
);
const bool kUseMock =
    bool.fromEnvironment('AVENOR_USE_MOCK', defaultValue: false);
const String kAvenorBlackLogoAsset = 'assets/images/avenor_hitam.png';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      details.exceptionAsString(),
      name: 'AvenorMarketingApp',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  await initializeDateFormatting('id_ID');
  runApp(const AvenorMarketingApp());
  unawaited(_initializeStartupServices());
}

Future<void> _initializeStartupServices() async {
  try {
    await NotificationScheduler.instance.initialize();
  } catch (error, stackTrace) {
    developer.log(
      'Notification initialization failed',
      name: 'AvenorMarketingApp',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class AvenorMarketingApp extends StatelessWidget {
  const AvenorMarketingApp({super.key});

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
        title: 'Avenor Marketing',
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

  bool _loading = true;
  bool _loggingIn = false;
  bool _busy = false;
  bool _mockMode = kUseMock;
  bool _obscureLoginPassword = true;
  int _navigationIndex = 0;
  String? _token;
  String? _error;
  String? _locationLabel;
  Map<String, dynamic>? _me;
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _attendance;
  Map<String, dynamic>? _products;
  Map<String, dynamic>? _sales;
  Map<String, dynamic>? _knowledge;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('marketing_token');
    final useMock = prefs.getBool('marketing_mock_mode') ?? kUseMock;

    if (!mounted) return;
    setState(() => _mockMode = useMock);

    if (useMock && (token == null || token.isEmpty)) {
      await _bootstrapMockSession();
      return;
    }

    if (token == null || token.isEmpty) {
      setState(() => _loading = false);
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
  }

  Future<void> _bootstrapMockSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('marketing_mock_mode', true);
    _mockMode = true;
    _token = 'mock-token';
    _hydrateMockData();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _hydrateMockData() {
    final now = DateTime.now();
    _me = {
      'nama': 'Alya Pramesti',
      'role': 'marketing',
      'wilayah': 'Jakarta Barat',
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
          'nama_product': 'Avenor Velvet Bloom',
          'stock': 38,
          'harga': 289000.0,
          'deskripsi': 'Floral creamy untuk acara premium dan gifting.',
          'image_url': null,
          'option_label': 'Avenor Velvet Bloom | stock 38',
        },
        {
          'id_product': 2,
          'nama_product': 'Avenor Citrus Muse',
          'stock': 24,
          'harga': 259000.0,
          'deskripsi': 'Fresh citrus musk untuk daily wear dan booth sampling.',
          'image_url': null,
          'option_label': 'Avenor Citrus Muse | stock 24',
        },
        {
          'id_product': 3,
          'nama_product': 'Avenor Ember Oud',
          'stock': 16,
          'harga': 329000.0,
          'deskripsi': 'Warm woody untuk closing high-ticket customer.',
          'image_url': null,
          'option_label': 'Avenor Ember Oud | stock 16',
        },
      ],
      'onhands': [
        {
          'id_product_onhand': 91,
          'id_product': 1,
          'nama_product': 'Avenor Velvet Bloom',
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
          'nama_product': 'Avenor Citrus Muse',
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
          'approval_status': 'pending',
          'nama_customer': 'Nadia',
          'no_telp': '08123456789',
          'promo': 'Booth Launch',
          'created_at': _formatYmdHis(now.subtract(const Duration(hours: 1))),
          'total_quantity': 1,
          'total_harga': 264000.0,
          'items': [
            {
              'id_product': 1,
              'nama_product': 'Avenor Velvet Bloom',
              'quantity': 1,
              'harga': 264000.0,
            }
          ],
        }
      ],
      'products': [
        {
          'id_product': 1,
          'nama_product': 'Avenor Velvet Bloom',
          'harga': 289000.0,
          'remaining': 3,
          'option_label': 'Avenor Velvet Bloom | Sisa 3',
        },
        {
          'id_product': 3,
          'nama_product': 'Avenor Ember Oud',
          'harga': 329000.0,
          'remaining': 2,
          'option_label': 'Avenor Ember Oud | Sisa 2',
        },
      ],
      'promos': [
        {
          'id': 7,
          'kode_promo': 'BOOST25',
          'nama_promo': 'Booth Launch',
          'potongan': 25000.0,
          'masa_aktif': _formatYmd(now.add(const Duration(days: 5))),
          'minimal_quantity': 1,
          'minimal_belanja': 250000.0,
          'option_label': 'Booth Launch | BOOST25',
        },
        {
          'id': 8,
          'kode_promo': 'DUO40',
          'nama_promo': 'Bundle 2 Item',
          'potongan': 40000.0,
          'masa_aktif': _formatYmd(now.add(const Duration(days: 3))),
          'minimal_quantity': 2,
          'minimal_belanja': 500000.0,
          'option_label': 'Bundle 2 Item | DUO40',
        },
      ],
    };
    _knowledge = {
      'products': [
        {
          'id_product': 1,
          'nama_product': 'Avenor Velvet Bloom',
          'deskripsi': 'White peony, almond milk, dan soft vanilla.',
          'gambar': null,
          'fragrance_details': [
            {'jenis': 'top', 'detail': 'Floral', 'deskripsi': 'Bukaan lembut dan cerah.'},
            {'jenis': 'base', 'detail': 'Creamy', 'deskripsi': 'Akhir aroma hangat dan halus.'},
          ],
        },
        {
          'id_product': 2,
          'nama_product': 'Avenor Citrus Muse',
          'deskripsi': 'Bergamot, neroli, white musk untuk profile segar.',
          'gambar': null,
          'fragrance_details': [
            {'jenis': 'top', 'detail': 'Citrus', 'deskripsi': 'Segar, bright, dan lively.'},
            {'jenis': 'heart', 'detail': 'Fresh', 'deskripsi': 'Cocok untuk daily wear.'},
          ],
        },
        {
          'id_product': 3,
          'nama_product': 'Avenor Ember Oud',
          'deskripsi':
              'Saffron, cedar, dan oud smoke untuk signature malam hari.',
          'gambar': null,
          'fragrance_details': [
            {'jenis': 'heart', 'detail': 'Woody', 'deskripsi': 'Nuansa kayu elegan dan tegas.'},
            {'jenis': 'base', 'detail': 'Amber', 'deskripsi': 'Dry down hangat dan mewah.'},
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

    final approvedSalesCount =
        sales.where((item) => item['approval_status'] == 'approved').length;
    final pendingTake =
        onhands.where((item) => item['take_status'] == 'pending').length;
    final pendingReturn =
        onhands.where((item) => item['return_status'] == 'pending').length;
    final onHandCount =
        onhands.where(_isCountedAsOnHand).fold<int>(0, (sum, item) {
      return sum + ((item['remaining_quantity'] as num?)?.toInt() ?? 0);
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
    _products?['today_return_items'] = onhands
        .where(_isCountedAsOnHand)
        .toList();
  }

  static bool _isCountedAsOnHand(Map<String, dynamic> item) {
    final takeStatus = item['take_status']?.toString().toLowerCase() ?? '';
    final remainingQuantity =
        (item['remaining_quantity'] as num?)?.toInt() ?? 0;
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
    await prefs.remove('marketing_token');
    await prefs.remove('marketing_mock_mode');
    _token = null;
    _me = null;
    _dashboard = null;
    _attendance = null;
    _products = null;
    _sales = null;
    _knowledge = null;
    _dio.options.headers.remove('Authorization');
  }

  Future<void> _login() async {
    setState(() {
      _loggingIn = true;
      _error = null;
    });

    try {
      if (_mockMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('marketing_mock_mode', true);
        await prefs.setString('marketing_token', 'mock-token');
        _token = 'mock-token';
        _hydrateMockData();
        return;
      }

      final response = await _dio.post('/auth/login', data: {
        'nama': _usernameController.text.trim(),
        'password': _passwordController.text,
        'device_name': 'Flutter Marketing App',
      });

      final token =
          (response.data as Map<String, dynamic>)['token']?.toString() ?? '';
      if (token.isEmpty) {
        throw Exception('Token login tidak diterima.');
      }

      _setToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('marketing_mock_mode', false);
      await prefs.setString('marketing_token', token);
      await _refreshAll(showLoader: false);
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
      final results = await Future.wait([
        _dio.get('/auth/me'),
        _dio.get('/dashboard'),
        _dio.get('/attendance'),
        _dio.get('/products'),
        _dio.get('/offline-sales'),
        _dio.get('/product-knowledge'),
      ]);

      if (!mounted) return;
      setState(() {
        _me = (results[0].data as Map<String, dynamic>)['user']
                as Map<String, dynamic>? ??
            {};
        _dashboard = results[1].data as Map<String, dynamic>;
        _attendance = results[2].data as Map<String, dynamic>;
        _products = results[3].data as Map<String, dynamic>;
        _sales = results[4].data as Map<String, dynamic>;
        _knowledge = results[5].data as Map<String, dynamic>;
      });
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

  Future<void> _requestTake(
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
      _showMessage('Request pengambilan barang berhasil dikirim.');
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

  Future<void> _requestReturn(
      {required int onhandId, required int quantity}) async {
    setState(() => _busy = true);
    try {
      if (_mockMode) {
        final onhand = ((_products?['onhands'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .firstWhere((item) => item['id_product_onhand'] == onhandId);
        onhand['quantity_dikembalikan'] = quantity;
        onhand['return_status'] = 'pending';
        onhand['return_status_label'] = 'Pending retur';
        onhand['status_label'] = 'Menunggu approval retur';
        onhand['can_checkout'] = true;
        _syncMockDerivedState();
      } else {
        await _dio.post('/products/onhand/$onhandId/return', data: {
          'quantity_dikembalikan': quantity,
        });
        await _refreshAll();
      }
      _showMessage('Request pengembalian barang berhasil dikirim.');
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

  Future<void> _submitSale({
    required String customerName,
    required String customerPhone,
    required String customerSocial,
    required List<_SaleItemDraft> items,
    int? promoId,
    XFile? proof,
  }) async {
    setState(() => _busy = true);
    try {
      if (_mockMode) {
        final products =
            ((_sales?['products'] as List?) ?? []).cast<Map<String, dynamic>>();
        final promos =
            ((_sales?['promos'] as List?) ?? []).cast<Map<String, dynamic>>();
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
          final product = products
              .firstWhere((entry) => entry['id_product'] == item.productId);
          final line =
              ((product['harga'] as num?)?.toDouble() ?? 0) * item.quantity;
          subtotal += line;
          product['remaining'] =
              ((product['remaining'] as num?)?.toInt() ?? 0) - item.quantity;
          mappedItems.add({
            'id_product': item.productId,
            'nama_product': product['nama_product'],
            'quantity': item.quantity,
            'harga': line,
          });
        }

        final discount = (promo?['potongan'] as num?)?.toDouble() ?? 0;
        final total = (subtotal - discount).clamp(0, subtotal).toDouble();
        ((_sales?['sales'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .insert(0, {
          'transaction_code': 'TRX-${DateTime.now().millisecondsSinceEpoch}',
          'approval_status': 'pending',
          'nama_customer': customerName,
          'no_telp': customerPhone,
          'promo': promo?['nama_promo'],
          'created_at': _formatYmdHis(DateTime.now()),
          'total_quantity':
              items.fold<int>(0, (sum, item) => sum + item.quantity),
          'total_harga': total,
          'items': mappedItems,
          'proof_name': proof?.name ?? 'mock-proof.jpg',
        });

        final onhands = ((_products?['onhands'] as List?) ?? [])
            .cast<Map<String, dynamic>>();
        for (final item in items) {
          var remainingToDeduct = item.quantity;
          for (final onhand in onhands) {
            if (remainingToDeduct <= 0) {
              break;
            }
            if (onhand['id_product'] != item.productId ||
                !_isCountedAsOnHand(onhand)) {
              continue;
            }

            final available =
                (onhand['remaining_quantity'] as num?)?.toInt() ?? 0;
            final deducted = available >= remainingToDeduct
                ? remainingToDeduct
                : available;
            final remaining = available - deducted;

            onhand['remaining_quantity'] = remaining;
            onhand['sold_out'] = remaining == 0;
            onhand['status_label'] =
                remaining == 0 ? 'Sold out' : 'Masih dibawa';
            onhand['max_return'] = remaining;

            remainingToDeduct -= deducted;
          }
        }
        _syncMockDerivedState();
      } else {
        final form = FormData();
        form.fields
          ..add(MapEntry('customer_nama', customerName))
          ..add(MapEntry('customer_no_telp', customerPhone))
          ..add(MapEntry('customer_tiktok_instagram', customerSocial));
        if (promoId != null) {
          form.fields.add(MapEntry('promo_id', '$promoId'));
        }
        for (var index = 0; index < items.length; index++) {
          form.fields.add(MapEntry(
              'items[$index][id_product]', '${items[index].productId}'));
          form.fields.add(
              MapEntry('items[$index][quantity]', '${items[index].quantity}'));
        }
        if (proof == null) {
          throw Exception('Bukti pembelian wajib diunggah.');
        }
        form.files.add(MapEntry(
          'bukti_pembelian',
          await MultipartFile.fromFile(proof.path, filename: proof.name),
        ));
        await _dio.post('/offline-sales', data: form);
        await _refreshAll();
      }
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

  Future<Map<String, dynamic>?> _lookupCustomerByPhone(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (_mockMode) {
      final sales = ((_sales?['sales'] as List?) ?? []).cast<Map<String, dynamic>>();
      for (final sale in sales) {
        final salePhone = sale['no_telp']?.toString().trim();
        if (salePhone == normalized) {
          return {
            'nama': sale['nama_customer']?.toString(),
            'no_telp': salePhone,
            'tiktok_instagram': sale['tiktok_instagram']?.toString(),
          };
        }
      }
      return null;
    }

    final response = await _dio.get('/offline-sales/customer', queryParameters: {
      'phone': normalized,
    });

    final customer = response.data is Map<String, dynamic>
        ? response.data['customer']
        : null;

    return customer is Map<String, dynamic> ? customer : null;
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
    final activeOnhands = onhands.where(_isCountedAsOnHand).toList();
    final availableProducts =
        ((_products?['products'] as List?) ?? []).cast<Map<String, dynamic>>();
    final sales =
        ((_sales?['sales'] as List?) ?? []).cast<Map<String, dynamic>>();
    final salesProducts =
        ((_sales?['products'] as List?) ?? []).cast<Map<String, dynamic>>();
    final promos =
        ((_sales?['promos'] as List?) ?? []).cast<Map<String, dynamic>>();
    final knowledge =
        ((_knowledge?['products'] as List?) ?? []).cast<Map<String, dynamic>>();
    final recentAttendances =
        ((_attendance?['recent_attendances'] as List?) ?? [])
            .cast<Map<String, dynamic>>();

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
        onhands: activeOnhands,
        attendanceBlockedReason:
            _products?['attendance_blocked_reason']?.toString(),
        busy: _busy,
        currency: _currency,
        onTake: _requestTake,
        onReturn: _requestReturn,
      ),
      _SalesPage(
        sales: sales,
        products: salesProducts,
        promos: promos,
        busy: _busy,
        currency: _currency,
        dateTime: _dateTime,
        onPickProof: _pickProof,
        onSubmit: _submitSale,
        onLookupCustomer: _lookupCustomerByPhone,
        mockMode: _mockMode,
      ),
      _KnowledgePage(
        products: knowledge,
        loading: _knowledge == null && _busy,
      ),
    ];
    final destinations = const [
      NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard'),
      NavigationDestination(
          icon: Icon(Icons.fingerprint_outlined),
          selectedIcon: Icon(Icons.fingerprint),
          label: 'Absensi'),
      NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Inventory'),
      NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Sales'),
      NavigationDestination(
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
    switch (index) {
      case 1:
        return 'Absensi Lapangan';
      case 2:
        return 'Inventory Harian';
      case 3:
        return 'Penjualan Offline';
      case 4:
        return 'Product Knowledge';
      default:
        return 'Dashboard Marketing';
    }
  }

  String _pageSubtitle(int index) {
    switch (index) {
      case 1:
        return 'Check in, check out, dan kirim lokasi dengan cepat.';
      case 2:
        return 'Ambil barang, pantau on hand, lalu kirim retur tanpa pindah aplikasi.';
      case 3:
        return 'Input customer, item, promo, dan bukti pembelian dalam satu flow native.';
      case 4:
        return 'Bahan presentasi singkat untuk bantu closing di booth dan lapangan.';
      default:
        return 'Ringkasan target, aktivitas, dan performa lapangan hari ini.';
    }
  }

  Color _pageAccent(int index) {
    switch (index) {
      case 1:
        return const Color(0xFFC05D3B);
      case 2:
        return const Color(0xFF6E8B3D);
      case 3:
        return const Color(0xFF8E5BD9);
      case 4:
        return const Color(0xFF2C8C82);
      default:
        return const Color(0xFFC18B2F);
    }
  }

  IconData _pageIcon(int index) {
    switch (index) {
      case 1:
        return Icons.fingerprint_rounded;
      case 2:
        return Icons.inventory_2_rounded;
      case 3:
        return Icons.receipt_long_rounded;
      case 4:
        return Icons.auto_stories_rounded;
      default:
        return Icons.dashboard_rounded;
    }
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
                          kAvenorBlackLogoAsset,
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
                              'Avenor Sales App',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username marketing',
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
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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
                    child:
                        Image.asset(kAvenorBlackLogoAsset, fit: BoxFit.contain),
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
              Text('Halo, ${me['nama'] ?? 'Marketing'}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                  'Fokus hari ini: jaga ritme closing, stok tetap rapi, dan tutup shift tanpa retur tertinggal.',
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
          subtitle: 'Ringkasan performa marketing untuk periode berjalan.',
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
          subtitle: 'Capaian target penjualan marketing aktif.',
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
    final hasCheckedOut =
        checkOutValue != null && checkOutValue.isNotEmpty && checkOutValue != '-';
    final formEnabled = !hasCheckedIn;
    final statusColor = hasCheckedIn
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC05D3B);
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
                child: Image.asset(kAvenorBlackLogoAsset, fit: BoxFit.contain),
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
    required this.attendanceBlockedReason,
    required this.busy,
    required this.currency,
    required this.onTake,
    required this.onReturn,
  });

  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> onhands;
  final String? attendanceBlockedReason;
  final bool busy;
  final NumberFormat currency;
  final Future<void> Function({required int productId, required int quantity})
      onTake;
  final Future<void> Function({required int onhandId, required int quantity})
      onReturn;

  @override
  Widget build(BuildContext context) {
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
          onTap: busy
              ? null
              : () => _openTakeSheet(context),
        ),
        const SizedBox(height: 16),
        _InventoryLauncherCard(
          title: 'Barang On Hand',
          subtitle: onhands.isEmpty
              ? 'Belum ada barang on hand.'
              : 'Tap untuk melihat detail barang yang sedang dibawa dan retur.',
          icon: Icons.inventory_2_rounded,
          accent: const Color(0xFFC18B2F),
          heroTag: 'inventory-onhand',
          badgeLabel: '${onhands.length} item',
          onTap: busy
              ? null
              : () => _openOnhandSheet(context),
        ),
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
    return showMaterialModalBottomSheet<void>(
      context: context,
      expand: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _OnHandSheet(
        onhands: onhands,
        busy: busy,
        currency: currency,
        onReturn: onReturn,
      ),
    );
  }
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
  final Future<void> Function({required int productId, required int quantity})
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
      return query.isEmpty || name.contains(query) || description.contains(query);
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
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filteredProducts[index];
                            final stock = (item['stock'] as num?)?.toInt() ?? 0;
                            return OpenContainer<void>(
                              openBuilder: (context, _) => _TakeProductDetailSheet(
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
                              transitionDuration: const Duration(milliseconds: 360),
                              closedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              closedBuilder: (context, openContainer) => Container(
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
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE4EED7),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.shopping_bag_rounded,
                                          color: Color(0xFF6E8B3D)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['nama_product']?.toString() ?? '-',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16)),
                                          const SizedBox(height: 6),
                                          Text(item['deskripsi']?.toString() ?? '-'),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _MiniPill(label: 'Stock $stock'),
                                              _MiniPill(
                                                  label: widget.currency.format(
                                                      (item['harga'] as num?)
                                                              ?.toDouble() ??
                                                          0)),
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
  final Future<void> Function({required int productId, required int quantity})
      onTake;

  @override
  Widget build(BuildContext context) {
    final stock = (item['stock'] as num?)?.toInt() ?? 0;

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
              Hero(
                tag: 'inventory-take',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4EED7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded,
                        color: Color(0xFF6E8B3D), size: 34),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MiniPill(label: 'Stock $stock'),
                  _MiniPill(label: currency.format((item['harga'] as num?)?.toDouble() ?? 0)),
                ],
              ),
              const SizedBox(height: 16),
              _BlockCard(
                title: 'Deskripsi',
                child: Text(item['deskripsi']?.toString() ?? '-'),
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
                              onSubmit: (qty) => onTake(
                                productId: (item['id_product'] as num).toInt(),
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
  final Future<void> Function({required int onhandId, required int quantity})
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
      final returnStatus = item['return_status_label']?.toString().toLowerCase() ?? '';
      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          status.contains(query) ||
          returnStatus.contains(query);
      final matchesFilter = switch (_filter) {
        'active' => item['take_status'] == 'disetujui',
        'pending' => item['take_status'] == 'pending',
        'other' => item['take_status'] != 'disetujui' && item['take_status'] != 'pending',
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    final activeItems = filtered.where((item) => item['take_status'] == 'disetujui').toList();
    final pendingItems = filtered.where((item) => item['take_status'] == 'pending').toList();
    final otherItems = filtered.where((item) =>
        item['take_status'] != 'disetujui' && item['take_status'] != 'pending').toList();

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
                  subtitle: 'Cari dan filter stok yang sedang dibawa atau menunggu approval.',
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
                          child: Text('Tidak ada barang yang cocok dengan filter.'),
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
                              if (activeItems.isNotEmpty) const SizedBox(height: 14),
                              _OnHandSection(
                                title: 'Menunggu Approval',
                                subtitle: '${pendingItems.length} request pending',
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
                              if (activeItems.isNotEmpty || pendingItems.isNotEmpty)
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
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
  final Future<void> Function({required int onhandId, required int quantity})
      onReturn;

  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                  : () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => _QuantitySheet(
                          title: 'Retur ${item['nama_product']}',
                          maxQuantity:
                              (item['max_return'] as num?)?.toInt() ?? 1,
                          ctaLabel: 'Kirim Retur',
                          onSubmit: (qty) => onReturn(
                            onhandId: (item['id_product_onhand'] as num).toInt(),
                            quantity: qty,
                          ),
                        ),
                      ),
              icon: const Icon(Icons.assignment_return_rounded),
              label: Text(canReturn ? 'Request Retur' : 'Retur Tidak Tersedia'),
            ),
          ),
        ],
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
  final bool busy;
  final NumberFormat currency;
  final DateFormat dateTime;
  final Future<XFile?> Function() onPickProof;
  final Future<void> Function({
    required String customerName,
    required String customerPhone,
    required String customerSocial,
    required List<_SaleItemDraft> items,
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
  bool _lookingUpCustomer = false;
  String? _customerLookupHint;

  @override
  void initState() {
    super.initState();
    final firstProductId = widget.products.isEmpty
        ? null
        : (widget.products.first['id_product'] as num?)?.toInt();
    _items = [_SaleItemDraft(productId: firstProductId, quantity: 1)];
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

  bool get _hasInvalidItems {
    for (final item in _items) {
      if (item.productId == null || item.quantity < 1) {
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

    _customerLookupDebounce = Timer(const Duration(milliseconds: 450), () async {
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

  Future<void> _showSalesHistorySheet(BuildContext context) {
    return showMaterialModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SalesHistorySheet(
        sales: widget.sales,
        currency: widget.currency,
      ),
    );
  }

  Future<void> _pickProductForIndex(int index) async {
    if (widget.products.isEmpty) {
      return;
    }

    final selected = await showMaterialModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SalesOptionSheet(
        heroTag: 'sales-product-$index',
        accent: const Color(0xFF8E5BE8),
        icon: Icons.inventory_2_outlined,
        title: 'Pilih Produk',
        subtitle: 'Pilih barang yang akan dijual dari stok on hand Anda.',
        searchHint: 'Cari product',
        emptyMessage: 'Belum ada product yang bisa dipilih.',
        options: widget.products,
        selectedId: _items[index].productId,
        idResolver: (item) => (item['id_product'] as num?)?.toInt(),
        titleResolver: _productLabel,
        subtitleResolver: (item) {
          final price = widget.currency
              .format((item['harga'] as num?)?.toDouble() ?? 0);
          return 'Harga $price';
        },
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _items[index] = _items[index].copyWith(productId: selected);
    });
  }

  Future<void> _pickPromo() async {
    final selected = await showMaterialModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SalesOptionSheet(
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
          final discount = widget.currency
              .format((item['potongan'] as num?)?.toDouble() ?? 0);
          return 'Potongan $discount';
        },
      ),
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
            return;
          }
          setState(() {
            _items[index] = _items[index].copyWith(quantity: qty);
          });
        },
      ),
    );
  }

  double get _subtotal {
    double sum = 0;
    for (final item in _items) {
      final product = _productById(item.productId);
      if (product != null) {
        sum += ((product['harga'] as num?)?.toDouble() ?? 0) * item.quantity;
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
        names.add('${product['nama_product'] ?? 'Produk'} x${item.quantity}');
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
                    'Produk belum bisa dipilih karena backend hanya mengirim barang on hand yang sudah disetujui dan masih punya sisa stok hari ini.',
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
                onPressed: () => setState(() =>
                    _items.add(const _SaleItemDraft(productId: null, quantity: 1))),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tambah item'),
              ),
              const SizedBox(height: 8),
              _PickerField(
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
                        _proof == null ? 'Pilih bukti pembelian' : _proof!.name,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.mockMode) ...[
                const SizedBox(height: 10),
                const Text(
                  'Mode demo akan memakai placeholder proof jika Anda tidak memilih gambar.',
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
                        _MiniPill(
                          label: _selectedPromo == null
                              ? 'Tanpa promo'
                              : (_selectedPromo!['kode_promo']?.toString().trim().isNotEmpty == true
                                  ? _selectedPromo!['kode_promo'].toString()
                                  : (_selectedPromo!['nama_promo']?.toString() ?? 'Promo')),
                        ),
                        _MiniPill(
                          label: widget.currency
                              .format((_subtotal - _discount).clamp(0, _subtotal)),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.busy || widget.products.isEmpty || _hasInvalidItems
                      ? null
                      : () => widget.onSubmit(
                            customerName: _customerNameController.text.trim(),
                            customerPhone: _customerPhoneController.text.trim(),
                            customerSocial:
                                _customerSocialController.text.trim(),
                            items: List<_SaleItemDraft>.from(_items),
                            promoId: _promoId,
                            proof: _proof,
                          ),
                  child:
                      Text(widget.busy ? 'Menyimpan...' : 'Simpan penjualan'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
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
                subtitle: 'Semua transaksi marketing ditampilkan di sini.',
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
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
                                      child: Text(
                                        sale['transaction_code']?.toString() ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    _StatusChip(
                                      label: sale['approval_status']?.toString() ?? '-',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  sale['nama_customer']?.toString().trim().isNotEmpty == true
                                      ? sale['nama_customer'].toString()
                                      : 'Customer umum',
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w600),
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
                                      label: currency.format(
                                        (sale['total_harga'] as num?)?.toDouble() ?? 0,
                                      ),
                                    ),
                                    _MiniPill(
                                      label: sale['promo']?.toString().trim().isNotEmpty == true
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
                                        '${item['nama_product'] ?? '-'} x${item['quantity'] ?? 0}',
                                        style: const TextStyle(fontSize: 12),
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
                              onTap: () => Navigator.of(context).pop<int?>(null),
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
                                  onTap: id == null
                                      ? null
                                      : () => Navigator.of(context).pop<int?>(id),
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

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.heroTag,
    required this.accent,
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final String heroTag;
  final Color accent;
  final IconData icon;
  final String label;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? const Color(0xFF241B13) : const Color(0xFF9D948B);
    final background = enabled ? Colors.white : const Color(0xFFF3EEE7);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled ? accent.withValues(alpha: 0.18) : const Color(0xFFE5DED4),
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
            Icon(Icons.expand_more_rounded, color: foreground),
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
  });

  final bool selected;
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
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
            Icon(
              selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: selected ? accent : const Color(0xFF8F857A),
            ),
          ],
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
    final details =
        ((item['fragrance_details'] as List?) ?? []).cast<Map<String, dynamic>>();
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
    final details =
        ((item['fragrance_details'] as List?) ?? []).cast<Map<String, dynamic>>();

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
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28.r)),
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
                                            Colors.black.withValues(alpha: 0.03),
                                            Colors.black.withValues(alpha: 0.1),
                                            Colors.black.withValues(alpha: 0.42),
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
                            transitionBuilder:
                                (child, primary, secondary) => FadeScaleTransition(
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
                                    final title = detail['detail']?.toString() ??
                                        detail['jenis']?.toString() ??
                                        '-';
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 10.h),
                                      padding: EdgeInsets.all(14.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.76),
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
              'Avenor',
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
  });

  final String title;
  final int maxQuantity;
  final String ctaLabel;
  final Future<void> Function(int quantity) onSubmit;
  final int initialQuantity;

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
    return Material(
      color: const Color(0xFFF7F1E6),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                    decoration: const InputDecoration(labelText: 'Quantity manual'),
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
                        await widget.onSubmit(qty);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
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
          color: onTap == null ? const Color(0xFFF1ECE4) : const Color(0xFFEEE4D5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: onTap == null ? const Color(0xFFB8AEA4) : const Color(0xFF4A3B2B),
        ),
      ),
    );
  }
}

@immutable
class _SaleItemDraft {
  const _SaleItemDraft({required this.productId, required this.quantity});

  final int? productId;
  final int quantity;

  _SaleItemDraft copyWith({int? productId, int? quantity}) {
    return _SaleItemDraft(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
    );
  }
}
