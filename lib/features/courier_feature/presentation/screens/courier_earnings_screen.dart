import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_sweet_shop_app_ui/core/gen/assets.gen.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/formatters.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_svg_viewer.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/data/models/courier_order_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/courier_feature/presentation/bloc/courier_orders_cubit.dart';

enum _EarningsFilter { all, today, thisWeek, thisMonth, customMonth }

class CourierEarningsScreen extends StatefulWidget {
  const CourierEarningsScreen({super.key});

  @override
  State<CourierEarningsScreen> createState() => _CourierEarningsScreenState();
}

class _CourierEarningsScreenState extends State<CourierEarningsScreen> {
  _EarningsFilter _filter = _EarningsFilter.all;
  DateTime? _selectedMonth;

  static const _monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static DateTime? _parseOrderDate(CourierOrderModel order) {
    if (order.date.isNotEmpty) {
      try {
        final parts = order.date.split('.');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      } catch (_) {}
    }

    final utc = order.createdAtUtc;
    if (utc != null) {
      final local = utc.toLocal();
      return DateTime(local.year, local.month, local.day);
    }
    return null;
  }

  static bool _isToday(DateTime? d) {
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static bool _isThisWeek(DateTime? d) {
    if (d == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));
    return !d.isBefore(start) && d.isBefore(end);
  }

  static bool _isThisMonth(DateTime? d) {
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  bool _matchesFilter(CourierOrderModel order) {
    final d = _parseOrderDate(order);
    switch (_filter) {
      case _EarningsFilter.all:
        return true;
      case _EarningsFilter.today:
        return _isToday(d);
      case _EarningsFilter.thisWeek:
        return _isThisWeek(d);
      case _EarningsFilter.thisMonth:
        return _isThisMonth(d);
      case _EarningsFilter.customMonth:
        if (d == null || _selectedMonth == null) return false;
        return d.year == _selectedMonth!.year && d.month == _selectedMonth!.month;
    }
  }

  String _filterLabel() {
    switch (_filter) {
      case _EarningsFilter.all:
        return 'Tüm zamanlar';
      case _EarningsFilter.today:
        return 'Bugün';
      case _EarningsFilter.thisWeek:
        return 'Bu hafta';
      case _EarningsFilter.thisMonth:
        return 'Bu ay';
      case _EarningsFilter.customMonth:
        if (_selectedMonth == null) return 'Seçili ay';
        return '${_monthNames[_selectedMonth!.month - 1]} ${_selectedMonth!.year}';
    }
  }

  String _totalCardTitle() {
    switch (_filter) {
      case _EarningsFilter.all:
        return 'Toplam Kazanç';
      case _EarningsFilter.today:
        return 'Bugünkü Kazanç';
      case _EarningsFilter.thisWeek:
        return 'Bu Hafta Kazancı';
      case _EarningsFilter.thisMonth:
        return 'Bu Ay Kazancı';
      case _EarningsFilter.customMonth:
        if (_selectedMonth == null) return 'Seçili Ay Kazancı';
        return '${_monthNames[_selectedMonth!.month - 1]} ${_selectedMonth!.year} Kazancı';
    }
  }

  void _setFilter(_EarningsFilter filter) {
    if (_filter == filter && filter != _EarningsFilter.customMonth) return;
    setState(() {
      _filter = filter;
      if (filter != _EarningsFilter.customMonth) {
        _selectedMonth = null;
      }
    });
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final initial = _selectedMonth ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: now,
      helpText: 'Ay seçin',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _filter = _EarningsFilter.customMonth;
      _selectedMonth = DateTime(picked.year, picked.month);
    });
  }

  Future<void> _showFilterSheet() async {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Widget option({
          required _EarningsFilter filter,
          required String label,
          VoidCallback? onTap,
        }) {
          final selected = _filter == filter;
          return ListTile(
            leading: Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? colors.primary : colors.gray4,
            ),
            title: Text(
              label,
              style: typography.bodyLarge.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? colors.primary : null,
              ),
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              if (onTap != null) {
                onTap();
              } else {
                _setFilter(filter);
              }
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimens.largePadding,
                  Dimens.largePadding,
                  Dimens.largePadding,
                  Dimens.padding,
                ),
                child: Text(
                  'Kazanç filtresi',
                  style: typography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              option(filter: _EarningsFilter.all, label: 'Tüm zamanlar'),
              option(filter: _EarningsFilter.today, label: 'Bugün'),
              option(filter: _EarningsFilter.thisWeek, label: 'Bu hafta'),
              option(filter: _EarningsFilter.thisMonth, label: 'Bu ay'),
              option(
                filter: _EarningsFilter.customMonth,
                label: _filter == _EarningsFilter.customMonth && _selectedMonth != null
                    ? 'Ay seç: ${_filterLabel()}'
                    : 'Ay seç...',
                onTap: _pickMonth,
              ),
              const SizedBox(height: Dimens.padding),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;

    return AppScaffold(
      appBar: GeneralAppBar(
        title: 'Kazançlarım',
        actions: [
          IconButton(
            tooltip: 'Filtrele',
            onPressed: _showFilterSheet,
            icon: Icon(
              _filter == _EarningsFilter.all
                  ? Icons.filter_list_rounded
                  : Icons.filter_list_off_rounded,
              color: colors.primary,
            ),
          ),
        ],
      ),
      body: BlocBuilder<CourierOrdersCubit, List<CourierOrderModel>>(
        builder: (context, orders) {
          final delivered = orders
              .where((o) => o.status == CourierOrderStatus.delivered)
              .toList();

          if (delivered.isEmpty) {
            return _EmptyEarnings();
          }

          final filtered = delivered.where(_matchesFilter).toList()
            ..sort((a, b) {
              final da = _parseOrderDate(a);
              final db = _parseOrderDate(b);
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return db.compareTo(da);
            });

          final filteredEarnings =
              filtered.fold<int>(0, (sum, o) => sum + o.total);

          final todayOrders =
              delivered.where((o) => _isToday(_parseOrderDate(o))).toList();
          final weekOrders =
              delivered.where((o) => _isThisWeek(_parseOrderDate(o))).toList();
          final monthOrders =
              delivered.where((o) => _isThisMonth(_parseOrderDate(o))).toList();

          final todayEarnings =
              todayOrders.fold<int>(0, (sum, o) => sum + o.total);
          final weekEarnings =
              weekOrders.fold<int>(0, (sum, o) => sum + o.total);
          final monthEarnings =
              monthOrders.fold<int>(0, (sum, o) => sum + o.total);

          if (filtered.isEmpty) {
            return _EmptyFilteredEarnings(
              filterLabel: _filterLabel(),
              onChangeFilter: _showFilterSheet,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimens.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_filter != _EarningsFilter.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Dimens.largePadding),
                    child: _ActiveFilterChip(
                      label: _filterLabel(),
                      onClear: () => _setFilter(_EarningsFilter.all),
                      onTap: _showFilterSheet,
                    ),
                  ),
                _TotalEarningsCard(
                  title: _totalCardTitle(),
                  amount: filteredEarnings,
                ),
                if (_filter == _EarningsFilter.all) ...[
                  const SizedBox(height: Dimens.extraLargePadding),
                  _PeriodSummary(
                    today: todayEarnings,
                    week: weekEarnings,
                    month: monthEarnings,
                    onTodayTap: () => _setFilter(_EarningsFilter.today),
                    onWeekTap: () => _setFilter(_EarningsFilter.thisWeek),
                    onMonthTap: () => _setFilter(_EarningsFilter.thisMonth),
                  ),
                ],
                const SizedBox(height: Dimens.extraLargePadding),
                Text(
                  'Teslim Edilen Siparişler',
                  style: typography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_filter != _EarningsFilter.all)
                  Padding(
                    padding: const EdgeInsets.only(top: Dimens.smallPadding),
                    child: Text(
                      '${filtered.length} sipariş',
                      style: typography.bodySmall.copyWith(color: colors.gray4),
                    ),
                  ),
                const SizedBox(height: Dimens.largePadding),
                ...filtered.map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: Dimens.largePadding),
                    child: _EarningsOrderCard(order: o),
                  ),
                ),
                const SizedBox(height: Dimens.extraLargePadding),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.onClear,
    required this.onTap,
  });

  final String label;
  final VoidCallback onClear;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.largePadding,
          vertical: Dimens.padding,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_alt_rounded, size: 18, color: colors.primary),
            const SizedBox(width: Dimens.padding),
            Expanded(
              child: Text(
                label,
                style: typography.bodyMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 18, color: colors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalEarningsCard extends StatelessWidget {
  const _TotalEarningsCard({
    required this.title,
    required this.amount,
  });

  final String title;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimens.extraLargePadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colors.success.withValues(alpha: 0.25),
            colors.success.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colors.success.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AppSvgViewer(
                  Assets.icons.moneyTick,
                  width: 28,
                  color: colors.success,
                ),
              ),
              const SizedBox(width: Dimens.largePadding),
              Expanded(
                child: Text(
                  title,
                  style: typography.titleMedium.copyWith(
                    color: colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.largePadding),
          Text(
            formatPrice(amount),
            style: typography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({
    required this.today,
    required this.week,
    required this.month,
    required this.onTodayTap,
    required this.onWeekTap,
    required this.onMonthTap,
  });

  final int today;
  final int week;
  final int month;
  final VoidCallback onTodayTap;
  final VoidCallback onWeekTap;
  final VoidCallback onMonthTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return Row(
      children: [
        Expanded(
          child: _PeriodChip(
            label: 'Bugün',
            value: formatPrice(today),
            color: colors.primary,
            typography: typography,
            onTap: onTodayTap,
          ),
        ),
        const SizedBox(width: Dimens.largePadding),
        Expanded(
          child: _PeriodChip(
            label: 'Bu Hafta',
            value: formatPrice(week),
            color: colors.secondary,
            typography: typography,
            onTap: onWeekTap,
          ),
        ),
        const SizedBox(width: Dimens.largePadding),
        Expanded(
          child: _PeriodChip(
            label: 'Bu Ay',
            value: formatPrice(month),
            color: colors.success,
            typography: typography,
            onTap: onMonthTap,
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.value,
    required this.color,
    required this.typography,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final dynamic typography;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimens.corners),
        child: Container(
          padding: const EdgeInsets.all(Dimens.largePadding),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Dimens.corners),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: typography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Dimens.smallPadding),
              Text(
                value,
                style: typography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningsOrderCard extends StatelessWidget {
  const _EarningsOrderCard({required this.order});

  final CourierOrderModel order;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return Container(
      padding: const EdgeInsets.all(Dimens.largePadding),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(Dimens.corners),
        border: Border.all(color: colors.success.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colors.success.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimens.corners),
            child: order.imagePath.isNotEmpty
                ? Image.network(
                    order.imagePath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  )
                : Assets.images.logo.image(
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: Dimens.largePadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.items,
                  style: typography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.date} • ${order.time}',
                  style: typography.bodySmall.copyWith(color: colors.gray4),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.largePadding,
              vertical: Dimens.padding,
            ),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              formatPrice(order.total),
              style: typography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEarnings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.extraLargePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(Dimens.extraLargePadding),
              decoration: BoxDecoration(
                color: colors.gray.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: colors.gray4,
              ),
            ),
            const SizedBox(height: Dimens.extraLargePadding),
            Text(
              'Henüz kazanç yok',
              style: typography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimens.padding),
            Text(
              'Teslim ettiğiniz siparişler burada görünecek',
              style: typography.bodyMedium.copyWith(color: colors.gray4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilteredEarnings extends StatelessWidget {
  const _EmptyFilteredEarnings({
    required this.filterLabel,
    required this.onChangeFilter,
  });

  final String filterLabel;
  final VoidCallback onChangeFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.extraLargePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 64,
              color: colors.gray4,
            ),
            const SizedBox(height: Dimens.extraLargePadding),
            Text(
              '$filterLabel için kazanç yok',
              style: typography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimens.padding),
            Text(
              'Farklı bir dönem seçerek tekrar deneyin',
              style: typography.bodyMedium.copyWith(color: colors.gray4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimens.extraLargePadding),
            OutlinedButton.icon(
              onPressed: onChangeFilter,
              icon: const Icon(Icons.filter_list_rounded),
              label: const Text('Filtreyi değiştir'),
            ),
          ],
        ),
      ),
    );
  }
}
