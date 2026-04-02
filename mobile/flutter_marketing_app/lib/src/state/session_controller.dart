import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required SessionStore sessionStore,
    required ApiClient apiClient,
  })  : _sessionStore = sessionStore,
        _apiClient = apiClient;

  final SessionStore _sessionStore;
  final ApiClient _apiClient;

  bool isRestoring = true;
  bool isBusy = false;
  String? errorMessage;
  String? token;
  AppUser? user;

  Map<String, dynamic>? dashboard;
  Map<String, dynamic>? attendance;
  Map<String, dynamic>? products;
  Map<String, dynamic>? sales;
  Map<String, dynamic>? knowledge;

  bool get isAuthenticated => token != null && user != null;

  Future<void> restoreSession() async {
    try {
      token = await _sessionStore.readToken();
      _apiClient.setToken(token);
      if (token != null) {
        await fetchMe();
        await refreshAll();
      }
    } catch (_) {
      await logout(localOnly: true);
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String nama,
    required String password,
    required String deviceName,
  }) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'nama': nama,
        'password': password,
        'device_name': deviceName,
      });

      final payload = LoginPayload.fromJson(response.data as Map<String, dynamic>);
      token = payload.token;
      user = payload.user;
      _apiClient.setToken(token);
      await _sessionStore.saveToken(token!);
      await refreshAll();
    } on DioException catch (error) {
      errorMessage = _readError(error);
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> fetchMe() async {
    final response = await _apiClient.dio.get('/auth/me');
    user = AppUser.fromJson((response.data as Map<String, dynamic>)['user'] as Map<String, dynamic>? ?? {});
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshDashboard(),
      refreshAttendance(),
      refreshProducts(),
      refreshSales(),
      refreshKnowledge(),
    ]);
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    final response = await _apiClient.dio.get('/dashboard');
    dashboard = response.data as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> refreshAttendance() async {
    final response = await _apiClient.dio.get('/attendance');
    attendance = response.data as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    final response = await _apiClient.dio.get('/products');
    products = response.data as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> refreshSales() async {
    final response = await _apiClient.dio.get('/offline-sales');
    sales = response.data as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> refreshKnowledge() async {
    final response = await _apiClient.dio.get('/product-knowledge');
    knowledge = response.data as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> checkIn({
    required String status,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    await _apiClient.dio.post('/attendance/check-in', data: {
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    });
    await refreshAttendance();
    await refreshDashboard();
    await refreshProducts();
  }

  Future<void> checkOut({
    required String status,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    await _apiClient.dio.post('/attendance/check-out', data: {
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    });
    await refreshAttendance();
    await refreshDashboard();
    await refreshProducts();
  }

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    required String source,
  }) async {
    await _apiClient.dio.post('/attendance/location', data: {
      'latitude': latitude,
      'longitude': longitude,
      'source': source,
    });
    await refreshAttendance();
  }

  Future<void> takeProduct({
    required int productId,
    required int quantity,
  }) async {
    await _apiClient.dio.post('/products/take', data: {
      'id_product': productId,
      'quantity': quantity,
    });
    await refreshProducts();
    await refreshDashboard();
    await refreshAttendance();
  }

  Future<void> requestReturn({
    required int onhandId,
    required int quantity,
  }) async {
    await _apiClient.dio.post('/products/onhand/$onhandId/return', data: {
      'quantity_dikembalikan': quantity,
    });
    await refreshProducts();
    await refreshDashboard();
    await refreshAttendance();
  }

  Future<void> submitSale({
    required List<Map<String, dynamic>> items,
    String? customerName,
    String? customerPhone,
    String? customerSocial,
    int? promoId,
    required File proofFile,
  }) async {
    final formPayload = <String, dynamic>{
      'customer_nama': customerName,
      'customer_no_telp': customerPhone,
      'customer_tiktok_instagram': customerSocial,
      'promo_id': promoId,
      'bukti_pembelian': await MultipartFile.fromFile(
        proofFile.path,
        filename: proofFile.uri.pathSegments.last,
      ),
    };

    for (var index = 0; index < items.length; index++) {
      formPayload['items[$index][id_product]'] = items[index]['id_product'];
      formPayload['items[$index][quantity]'] = items[index]['quantity'];
    }

    await _apiClient.dio.post('/offline-sales', data: FormData.fromMap(formPayload));
    await refreshSales();
    await refreshDashboard();
    await refreshProducts();
  }

  Future<void> logout({bool localOnly = false}) async {
    try {
      if (!localOnly && token != null) {
        await _apiClient.dio.post('/auth/logout');
      }
    } catch (_) {
      // Ignore logout API failure and clear session locally.
    }

    token = null;
    user = null;
    dashboard = null;
    attendance = null;
    products = null;
    sales = null;
    knowledge = null;
    _apiClient.setToken(null);
    await _sessionStore.clear();
    notifyListeners();
  }

  String readError(Object error) {
    if (error is DioException) {
      return _readError(error);
    }
    return error.toString();
  }

  String _readError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final directMessage = data['message'];
      if (directMessage is String && directMessage.isNotEmpty) {
        return directMessage;
      }
      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }
    }

    return error.message ?? 'Terjadi kesalahan pada server.';
  }
}
