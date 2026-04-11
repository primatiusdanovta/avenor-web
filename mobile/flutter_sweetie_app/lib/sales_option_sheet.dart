part of 'main.dart';

Future<int?> _showSmoothiesSalesOptionSheet({
  required BuildContext context,
  required String heroTag,
  required Color accent,
  required IconData icon,
  required String title,
  required String subtitle,
  required String searchHint,
  required String emptyMessage,
  required List<Map<String, dynamic>> options,
  required int? selectedId,
  required int? Function(Map<String, dynamic>) idResolver,
  required String Function(Map<String, dynamic>) titleResolver,
  String? Function(Map<String, dynamic>)? subtitleResolver,
  String? Function(Map<String, dynamic>)? trailingBadgeResolver,
  bool includeNoneOption = false,
  String noneLabel = 'Tidak ada',
}) {
  return showMaterialModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SalesOptionSheet(
      heroTag: heroTag,
      accent: accent,
      icon: icon,
      title: title,
      subtitle: subtitle,
      searchHint: searchHint,
      emptyMessage: emptyMessage,
      options: options,
      selectedId: selectedId,
      idResolver: idResolver,
      titleResolver: titleResolver,
      subtitleResolver: subtitleResolver,
      trailingBadgeResolver: trailingBadgeResolver,
      includeNoneOption: includeNoneOption,
      noneLabel: noneLabel,
    ),
  );
}

Future<List<int>?> _showSmoothiesSalesMultiSelectSheet({
  required BuildContext context,
  required String heroTag,
  required Color accent,
  required IconData icon,
  required String title,
  required String subtitle,
  required List<Map<String, dynamic>> options,
  required List<int> selectedIds,
  required int? Function(Map<String, dynamic>) idResolver,
  required String Function(Map<String, dynamic>) titleResolver,
  String? Function(Map<String, dynamic>)? subtitleResolver,
}) {
  return showMaterialModalBottomSheet<List<int>>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SalesMultiSelectSheet(
      heroTag: heroTag,
      accent: accent,
      icon: icon,
      title: title,
      subtitle: subtitle,
      options: options,
      selectedIds: selectedIds,
      idResolver: idResolver,
      titleResolver: titleResolver,
      subtitleResolver: subtitleResolver,
    ),
  );
}

Future<T?> _showSmoothiesSalesStaticOptionsSheet<T>({
  required BuildContext context,
  required String heroTag,
  required Color accent,
  required IconData icon,
  required String title,
  required String subtitle,
  required List<_StaticOption<T>> options,
  required T selectedValue,
}) {
  return showMaterialModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _StaticOptionsSheet<T>(
      heroTag: heroTag,
      accent: accent,
      icon: icon,
      title: title,
      subtitle: subtitle,
      options: options,
      selectedValue: selectedValue,
    ),
  );
}
