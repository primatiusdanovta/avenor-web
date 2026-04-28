part of 'main.dart';

class SmoothiesSalesPageModule extends StatelessWidget {
  const SmoothiesSalesPageModule({
    super.key,
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
  final Future<bool> Function({
    required String customerName,
    required String customerPhone,
    required String customerSocial,
    required List<dynamic> items,
    required String paymentMethod,
    required bool requireProof,
    int? promoId,
    XFile? proof,
  }) onSubmit;
  final Future<Map<String, dynamic>?> Function(String phone) onLookupCustomer;
  final bool mockMode;

  @override
  Widget build(BuildContext context) {
    return _SalesPage(
      sales: sales,
      products: products,
      promos: promos,
      extraToppings: extraToppings,
      sops: sops,
      isSmoothiesSweetie: isSmoothiesSweetie,
      qrisImageUrl: qrisImageUrl,
      busy: busy,
      currency: currency,
      dateTime: dateTime,
      onPickProof: onPickProof,
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
          onSubmit(
        customerName: customerName,
        customerPhone: customerPhone,
        customerSocial: customerSocial,
        items: items.cast<dynamic>(),
        paymentMethod: paymentMethod,
        requireProof: requireProof,
        promoId: promoId,
        proof: proof,
      ),
      onLookupCustomer: onLookupCustomer,
      mockMode: mockMode,
    );
  }
}

Widget buildSmoothiesSalesPageTestHarness({
  Key? key,
  Map<String, dynamic>? fixture,
  Future<bool> Function({
    required String customerName,
    required String customerPhone,
    required String customerSocial,
    required List<dynamic> items,
    required String paymentMethod,
    required bool requireProof,
    int? promoId,
    XFile? proof,
  })? onSubmit,
  Future<Map<String, dynamic>?> Function(String phone)? onLookupCustomer,
  Future<XFile?> Function()? onPickProof,
}) {
  final data = fixture ?? buildSmoothiesSalesTestFixture();

  return ScreenUtilInit(
    designSize: const Size(360, 800),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        body: SmoothiesSalesPageModule(
          key: key,
          sales: (data['sales'] as List).cast<Map<String, dynamic>>(),
          products: (data['products'] as List).cast<Map<String, dynamic>>(),
          promos: (data['promos'] as List).cast<Map<String, dynamic>>(),
          extraToppings:
              (data['extra_toppings'] as List).cast<Map<String, dynamic>>(),
          sops: (data['sops'] as List).cast<Map<String, dynamic>>(),
          isSmoothiesSweetie: true,
          qrisImageUrl: null,
          busy: false,
          currency: NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ),
          dateTime: DateFormat('dd MMM yyyy, HH:mm', 'id_ID'),
          onPickProof: onPickProof ??
              () async => XFile('mock-proof.jpg', name: 'mock-proof.jpg'),
          onSubmit: onSubmit ??
              ({
                required customerName,
                required customerPhone,
                required customerSocial,
                required items,
                required paymentMethod,
                required requireProof,
                promoId,
                proof,
              }) async =>
                  true,
          onLookupCustomer: onLookupCustomer ?? (_) async => null,
          mockMode: true,
        ),
      ),
    ),
  );
}

Widget buildSmoothiesQueuePageTestHarness({
  required List<Map<String, dynamic>> queueItems,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 800),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        body: _QueuePage(
          queueItems: queueItems,
          onCloseQueue: (_) async => true,
        ),
      ),
    ),
  );
}
