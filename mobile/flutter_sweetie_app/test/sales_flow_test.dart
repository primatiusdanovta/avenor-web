import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_sweetie_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('sales flow supports size, topping, qris, submit, and history',
      (tester) async {
    Map<String, dynamic>? submitted;
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildSmoothiesSalesPageTestHarness(
        onSubmit: ({
          required customerName,
          required customerPhone,
          required customerSocial,
          required items,
          required paymentMethod,
          required requireProof,
          promoId,
          proof,
        }) async {
          submitted = {
            'customerName': customerName,
            'customerPhone': customerPhone,
            'customerSocial': customerSocial,
            'items': items,
            'paymentMethod': paymentMethod,
            'requireProof': requireProof,
            'promoId': promoId,
          };
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nama customer'),
      'Nadia',
    );

    await tester.tap(
      find.byKey(const ValueKey('sales-catalog-product-2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Large').last);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Boba').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gunakan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sales-payment-method-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qris').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sales-qris-panel')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sales-qris-confirm-button')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('sales-qris-confirm-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sales-sop-check-pre_blend')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('sales-sop-check-final_topping')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sales-sop-check-handover')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('sales-sop-check-payment_verification')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sales-submit-button')));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!['customerName'], 'Nadia');
    expect(submitted!['paymentMethod'], 'Qris');
    final items = (submitted!['items'] as List).cast<dynamic>();
    expect(items, hasLength(1));
    expect(items.first.productId, 2);
    expect(items.first.variantId, 14);
    expect(items.first.extraToppingIds, contains(21));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sales-history-trigger')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('sales-history-trigger')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Transaksi'), findsWidgets);
    expect(find.textContaining('TRX-1001'), findsWidgets);
  });

  testWidgets('queue groups same configuration and separates different ones',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildSmoothiesQueuePageTestHarness(
        queueItems: [
          {
            'sale_number': '27/04/26 - 1',
            'queue_number': 1,
            'transaction_code': 'TRX-QUEUE-1',
            'customer_name': 'Nadia',
            'payment_status': 'paid',
            'created_at': '2026-04-27 10:00:00',
            'details': [
              {
                'nama_product': 'Tropical Glow - Large',
                'product_variant_name': 'Large',
                'quantity': 2,
                'extra_toppings': ['Boba'],
              },
              {
                'nama_product': 'Tropical Glow - Reguler',
                'product_variant_name': 'Reguler',
                'quantity': 1,
                'extra_toppings': [],
              },
            ],
          },
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nadia'), findsOneWidget);
    expect(find.text('Tropical Glow'), findsNWidgets(2));
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
    expect(find.text('Large'), findsOneWidget);
    expect(find.text('Reguler'), findsOneWidget);
    expect(find.text('Boba'), findsOneWidget);
    expect(find.text('Tidak Pakai Topping'), findsOneWidget);
  });
}
