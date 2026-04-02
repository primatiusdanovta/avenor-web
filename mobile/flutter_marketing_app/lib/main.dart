import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  await initializeDateFormatting('id_ID');
  await NotificationScheduler.instance.initialize();
  runApp(const AvenorMarketingApp());
}

class AvenorMarketingApp extends StatelessWidget {
  const AvenorMarketingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFC18B2F),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Avenor Marketing',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF7F1E8),
        textTheme: Typography.blackMountainView.apply(
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
            borderSide: const BorderSide(color: Color(0xFFC18B2F), width: 1.4),
          ),
        ),
      ),
      home: const MarketingRoot(),
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
          'option_label': 'Avenor Velvet Bloom | sisa 3',
        },
        {
          'id_product': 3,
          'nama_product': 'Avenor Ember Oud',
          'harga': 329000.0,
          'remaining': 2,
          'option_label': 'Avenor Ember Oud | sisa 2',
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
        },
        {
          'id_product': 2,
          'nama_product': 'Avenor Citrus Muse',
          'deskripsi': 'Bergamot, neroli, white musk untuk profile segar.',
        },
        {
          'id_product': 3,
          'nama_product': 'Avenor Ember Oud',
          'deskripsi':
              'Saffron, cedar, dan oud smoke untuk signature malam hari.',
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
    final onHandCount = onhands
        .where((item) => item['take_status'] == 'disetujui')
        .fold<int>(
            0,
            (sum, item) =>
                sum + ((item['remaining_quantity'] as num?)?.toInt() ?? 0));

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
        onhands.where((item) => item['take_status'] == 'disetujui').toList();
    _products?['today_return_items'] = onhands
        .where((item) =>
            item['take_status'] == 'disetujui' &&
            (item['remaining_quantity'] as num? ?? 0) > 0)
        .toList();
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
        await _dio.post('/attendance/location', data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'source': checkIn ? 'check_in' : 'check_out',
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
          Map<String, dynamic>? onhand;
          for (final entry in onhands) {
            if (entry['id_product'] == item.productId &&
                entry['take_status'] == 'disetujui') {
              onhand = entry;
              break;
            }
          }
          if (onhand != null) {
            onhand['remaining_quantity'] =
                ((onhand['remaining_quantity'] as num?)?.toInt() ?? 0) -
                    item.quantity;
            final remaining =
                (onhand['remaining_quantity'] as num?)?.toInt() ?? 0;
            onhand['sold_out'] = remaining == 0;
            onhand['status_label'] =
                remaining == 0 ? 'Sold out' : 'Masih dibawa';
            onhand['max_return'] = remaining;
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

  Future<void> _toggleMockMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('marketing_mock_mode', value);
    setState(() => _mockMode = value);
    if (value) {
      await prefs.setString('marketing_token', 'mock-token');
      _token = 'mock-token';
      _hydrateMockData();
      setState(() {});
      return;
    }
    await _clearSession();
    if (mounted) {
      setState(() => _loading = false);
    }
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
        mockMode: _mockMode,
        error: _error,
        onLogin: _login,
        onToggleMockMode: _toggleMockMode,
      );
    }

    final stats = _dashboard?['stats'] as Map<String, dynamic>? ?? {};
    final todayAttendance =
        _attendance?['today_attendance'] as Map<String, dynamic>? ?? {};
    final onhands =
        ((_products?['onhands'] as List?) ?? []).cast<Map<String, dynamic>>();
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
        stats: stats,
        todayAttendance: todayAttendance,
        recentSales: sales,
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
        mockMode: _mockMode,
      ),
      _KnowledgePage(products: knowledge),
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
    required this.mockMode,
    required this.error,
    required this.onLogin,
    required this.onToggleMockMode,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool loggingIn;
  final bool mockMode;
  final String? error;
  final Future<void> Function() onLogin;
  final ValueChanged<bool> onToggleMockMode;

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
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x140F0A05),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(kAvenorBlackLogoAsset,
                              fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 18),
                        Text('Avenor Marketing App',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        const Text(
                            'Versi native untuk aktivitas lapangan: absensi, inventory harian, sales offline, dan product knowledge.'),
                        const SizedBox(height: 22),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: mockMode,
                          onChanged: onToggleMockMode,
                          title: const Text('Mode demo / mock data'),
                          subtitle: const Text(
                              'Aktifkan untuk cek flow UI tanpa backend lokal.'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                              labelText: 'Username marketing'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2B2117),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: loggingIn ? null : onLogin,
                            child: loggingIn
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(mockMode ? 'Masuk ke demo' : 'Masuk'),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ],
                      ],
                    ),
                  ),
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
  final VoidCallback onRefresh;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
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

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.me,
    required this.stats,
    required this.todayAttendance,
    required this.recentSales,
    required this.currency,
    required this.onNavigate,
  });

  final Map<String, dynamic> me;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> todayAttendance;
  final List<Map<String, dynamic>> recentSales;
  final NumberFormat currency;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
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
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MetricCard(
                label: 'On Hand',
                value: '${stats['onhand_count'] ?? 0}',
                icon: Icons.inventory_2_rounded,
                accent: const Color(0xFFC18B2F)),
            _MetricCard(
                label: 'Pending Return',
                value: '${stats['pending_return_count'] ?? 0}',
                icon: Icons.assignment_return_rounded,
                accent: const Color(0xFFC05D3B)),
            _MetricCard(
                label: 'Pending Take',
                value: '${stats['pending_take_count'] ?? 0}',
                icon: Icons.shopping_bag_rounded,
                accent: const Color(0xFF6E8B3D)),
            _MetricCard(
                label: 'Sales Approved',
                value: '${stats['approved_sales_count'] ?? 0}',
                icon: Icons.verified_rounded,
                accent: const Color(0xFF2C8C82)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _BlockCard(
                title: 'Snapshot Hari Ini',
                subtitle: 'Absensi dan ritme penjualan dalam sekali lihat.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                        label: 'Status',
                        value: todayAttendance['status']?.toString() ?? '-'),
                    _InfoRow(
                        label: 'Check in',
                        value: todayAttendance['check_in']?.toString() ?? '-'),
                    _InfoRow(
                        label: 'Check out',
                        value: todayAttendance['check_out']?.toString() ?? '-'),
                    _InfoRow(
                        label: 'Catatan',
                        value: todayAttendance['notes']?.toString() ??
                            'Belum ada catatan'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 6,
              child: _BlockCard(
                title: 'Recent Sales',
                subtitle: '3 transaksi terbaru marketing.',
                child: recentSales.isEmpty
                    ? const Text('Belum ada penjualan hari ini.')
                    : Column(
                        children: recentSales.take(3).map((sale) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCF8F1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9D8B7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded),
                                ),
                                const SizedBox(width: 12),
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
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${sale['nama_customer'] ?? 'Customer umum'} ÃƒÂ¯Ã‚Â¿Ã‚Â½ ${sale['approval_status'] ?? '-'}'),
                                    ],
                                  ),
                                ),
                                Text(currency.format(
                                    (sale['total_harga'] as num?)?.toDouble() ??
                                        0)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
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
    final latest = widget.latestLocation;
    final locationLabel = widget.manualLocationLabel ??
        (latest == null
            ? '-'
            : '${latest['latitude']}, ${latest['longitude']}');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _BlockCard(
          title: 'Form Absensi Native',
          subtitle:
              'Pilih status, tambahkan catatan, lalu kirim dengan GPS perangkat.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                  DropdownMenuItem(
                      value: 'terlambat', child: Text('Terlambat')),
                  DropdownMenuItem(value: 'izin', child: Text('Izin')),
                  DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'hadir'),
                decoration:
                    const InputDecoration(labelText: 'Status kehadiran'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                minLines: 3,
                maxLines: 4,
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
                    onPressed: widget.busy
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
                    onPressed: widget.busy
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
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BlockCard(
                title: 'Status Hari Ini',
                subtitle: 'Progress shift yang sedang berjalan.',
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'Status',
                        value: widget.todayAttendance['status']?.toString() ??
                            '-'),
                    _InfoRow(
                        label: 'Check in',
                        value: widget.todayAttendance['check_in']?.toString() ??
                            '-'),
                    _InfoRow(
                        label: 'Check out',
                        value:
                            widget.todayAttendance['check_out']?.toString() ??
                                '-'),
                    _InfoRow(label: 'Lokasi terakhir', value: locationLabel),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _BlockCard(
                title: 'Riwayat Singkat',
                subtitle: '2-3 absensi terakhir untuk cross-check cepat.',
                child: Column(
                  children: widget.recentAttendances.take(3).map((item) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['attendance_date']?.toString() ?? '-'),
                      subtitle: Text(
                          '${item['check_in'] ?? '-'} - ${item['check_out'] ?? '-'} ÃƒÂ¯Ã‚Â¿Ã‚Â½ ${item['status'] ?? '-'}'),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InventoryPage extends StatelessWidget {
  const _InventoryPage({
    required this.products,
    required this.onhands,
    required this.busy,
    required this.currency,
    required this.onTake,
    required this.onReturn,
  });

  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> onhands;
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
        _BlockCard(
          title: 'Ambil Barang',
          subtitle: 'Request stok langsung dari daftar produk yang tersedia.',
          child: Column(
            children: products.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF8F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAD8B5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.shopping_bag_rounded),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['nama_product']?.toString() ?? '-',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(item['deskripsi']?.toString() ?? '-'),
                          const SizedBox(height: 8),
                          Text(
                              'Harga ${currency.format((item['harga'] as num?)?.toDouble() ?? 0)} ÃƒÂ¯Ã‚Â¿Ã‚Â½ Stock ${item['stock'] ?? 0}'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => _QuantitySheet(
                                  title: 'Request ${item['nama_product']}',
                                  maxQuantity:
                                      (item['stock'] as num?)?.toInt() ?? 1,
                                  ctaLabel: 'Kirim Request',
                                  onSubmit: (qty) => onTake(
                                    productId:
                                        (item['id_product'] as num).toInt(),
                                    quantity: qty,
                                  ),
                                ),
                              ),
                      child: const Text('Request'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _BlockCard(
          title: 'Barang On Hand',
          subtitle:
              'Pantau item yang sedang dibawa dan kirim retur jika perlu.',
          child: onhands.isEmpty
              ? const Text('Belum ada barang on hand.')
              : Column(
                  children: onhands.map((item) {
                    final canReturn = item['take_status'] == 'disetujui' &&
                        ((item['max_return'] as num?)?.toInt() ?? 0) > 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE7DBC8)),
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
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                              ),
                              _StatusChip(
                                  label:
                                      item['take_status_label']?.toString() ??
                                          '-'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MiniPill(label: 'Qty ${item['quantity'] ?? 0}'),
                              _MiniPill(
                                  label:
                                      'Sisa ${item['remaining_quantity'] ?? 0}'),
                              _MiniPill(
                                  label:
                                      item['return_status_label']?.toString() ??
                                          '-'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(item['status_label']?.toString() ?? '-'),
                          const SizedBox(height: 12),
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
                                              (item['max_return'] as num?)
                                                      ?.toInt() ??
                                                  1,
                                          ctaLabel: 'Kirim Retur',
                                          onSubmit: (qty) => onReturn(
                                            onhandId: (item['id_product_onhand']
                                                    as num)
                                                .toInt(),
                                            quantity: qty,
                                          ),
                                        ),
                                      ),
                              icon: const Icon(Icons.assignment_return_rounded),
                              label: const Text('Request Retur'),
                            ),
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
  int? _promoId;
  XFile? _proof;

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
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerSocialController.dispose();
    super.dispose();
  }

  double get _subtotal {
    double sum = 0;
    for (final item in _items) {
      Map<String, dynamic>? product;
      for (final entry in widget.products) {
        if (entry['id_product'] == item.productId) {
          product = entry;
          break;
        }
      }
      if (product != null) {
        sum += ((product['harga'] as num?)?.toDouble() ?? 0) * item.quantity;
      }
    }
    return sum;
  }

  double get _discount {
    Map<String, dynamic>? promo;
    for (final entry in widget.promos) {
      if (entry['id'] == _promoId) {
        promo = entry;
        break;
      }
    }
    return (promo?['potongan'] as num?)?.toDouble() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _BlockCard(
          title: 'Form Penjualan Offline',
          subtitle:
              'Input customer, item, promo, dan bukti pembelian dalam satu layar.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customerNameController,
                      decoration:
                          const InputDecoration(labelText: 'Nama customer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _customerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'Nomor telepon'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerSocialController,
                decoration:
                    const InputDecoration(labelText: 'TikTok / Instagram'),
              ),
              const SizedBox(height: 16),
              ...List.generate(_items.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCF8F1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _items[index].productId,
                            items: widget.products.map((product) {
                              return DropdownMenuItem<int>(
                                value: (product['id_product'] as num).toInt(),
                                child: Text(
                                    '${product['nama_product']} ÃƒÂ¯Ã‚Â¿Ã‚Â½ sisa ${product['remaining']}'),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _items[index] =
                                _items[index].copyWith(productId: value)),
                            decoration: InputDecoration(
                                labelText: 'Produk ${index + 1}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty'),
                            controller: TextEditingController(
                                text: '${_items[index].quantity}')
                              ..selection = TextSelection.fromPosition(
                                  TextPosition(
                                      offset:
                                          '${_items[index].quantity}'.length)),
                            onChanged: (value) {
                              final parsed = int.tryParse(value) ?? 1;
                              _items[index] = _items[index]
                                  .copyWith(quantity: parsed < 1 ? 1 : parsed);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (_items.length > 1)
                          IconButton(
                            onPressed: () =>
                                setState(() => _items.removeAt(index)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _items
                    .add(const _SaleItemDraft(productId: null, quantity: 1))),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tambah item'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _promoId,
                items: [
                  const DropdownMenuItem<int>(
                      value: null, child: Text('Tanpa promo')),
                  ...widget.promos.map((promo) => DropdownMenuItem<int>(
                        value: (promo['id'] as num).toInt(),
                        child: Text(
                            '${promo['nama_promo']} ÃƒÂ¯Ã‚Â¿Ã‚Â½ ${widget.currency.format((promo['potongan'] as num?)?.toDouble() ?? 0)}'),
                      )),
                ],
                onChanged: (value) => setState(() => _promoId = value),
                decoration: const InputDecoration(labelText: 'Promo aktif'),
              ),
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
                      label: Text(_proof == null
                          ? 'Pilih bukti pembelian'
                          : _proof!.name),
                    ),
                  ),
                ],
              ),
              if (widget.mockMode) ...[
                const SizedBox(height: 10),
                const Text(
                    'Mode demo akan memakai placeholder proof jika Anda tidak memilih gambar.'),
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
                        valueColor: Colors.white),
                    _SummaryRow(
                        label: 'Diskon',
                        value: widget.currency.format(_discount),
                        valueColor: Colors.white),
                    _SummaryRow(
                        label: 'Total estimasi',
                        value: widget.currency.format(
                            (_subtotal - _discount).clamp(0, _subtotal)),
                        valueColor: Colors.white,
                        emphasized: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.busy
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
        _BlockCard(
          title: 'Riwayat Transaksi',
          subtitle: 'Semua transaksi terbaru marketing.',
          child: widget.sales.isEmpty
              ? const Text('Belum ada transaksi.')
              : Column(
                  children: widget.sales.map((sale) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
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
                                    sale['transaction_code']?.toString() ?? '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                              _StatusChip(
                                  label: sale['approval_status']?.toString() ??
                                      '-'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              '${sale['nama_customer'] ?? 'Customer umum'} ÃƒÂ¯Ã‚Â¿Ã‚Â½ ${sale['promo'] ?? 'Tanpa promo'}'),
                          const SizedBox(height: 8),
                          Text(
                              widget.currency.format(
                                  (sale['total_harga'] as num?)?.toDouble() ??
                                      0),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(sale['created_at']?.toString() ?? '-'),
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

class _KnowledgePage extends StatefulWidget {
  const _KnowledgePage({required this.products});

  final List<Map<String, dynamic>> products;

  @override
  State<_KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<_KnowledgePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.products.where((item) {
      final name = item['nama_product']?.toString().toLowerCase() ?? '';
      final description = item['deskripsi']?.toString().toLowerCase() ?? '';
      return query.isEmpty ||
          name.contains(query) ||
          description.contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Cari product knowledge',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        ...filtered.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF3E7D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAD8B5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.spa_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item['nama_product']?.toString() ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 17)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(item['deskripsi']?.toString() ?? '-'),
                ],
              ),
            ),
          );
        }),
      ],
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
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label),
                    const SizedBox(height: 6),
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
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
  });

  final String title;
  final int maxQuantity;
  final String ctaLabel;
  final Future<void> Function(int quantity) onSubmit;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text(widget.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Maksimal ${widget.maxQuantity} item.'),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity'),
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
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
              child: Text(_submitting ? 'Memproses...' : widget.ctaLabel),
            ),
          ),
        ],
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
