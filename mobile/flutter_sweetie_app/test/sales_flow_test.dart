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

    await tester.tap(find.byKey(const ValueKey('sales-product-picker-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tropical Glow').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sales-variant-picker-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Large').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sales-toppings-picker-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boba').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gunakan topping ini'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sales-payment-method-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qris').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sales-qris-panel')), findsOneWidget);

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
}
