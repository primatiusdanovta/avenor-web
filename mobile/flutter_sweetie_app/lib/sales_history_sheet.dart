part of 'main.dart';

Future<void> showSmoothiesSalesHistorySheet(
  BuildContext context, {
  required List<Map<String, dynamic>> sales,
  required NumberFormat currency,
}) {
  return showMaterialModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SalesHistorySheet(
      sales: sales,
      currency: currency,
    ),
  );
}
