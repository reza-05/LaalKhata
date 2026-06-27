import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/services/ledger_snapshot_repository.dart';
import '../../../../core/services/local_pin_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../sms/data/sms_suggestion_manager.dart';
import '../../../sms/domain/balance_initializer.dart';
import '../../../sms/domain/sms_duplicate_detector.dart';
import '../../../sms/domain/sms_transaction_models.dart';
import '../controllers/auth_controller.dart';

class PhaseOneHomePage extends ConsumerStatefulWidget {
  const PhaseOneHomePage({super.key});

  @override
  ConsumerState<PhaseOneHomePage> createState() => _PhaseOneHomePageState();
}

class _PhaseOneHomePageState extends ConsumerState<PhaseOneHomePage>
    with WidgetsBindingObserver {
  final _ledgerRepository = LedgerSnapshotRepository();

  int _selectedIndex = 0;
  bool _balanceVisible = false;
  bool _isLedgerLoading = true;
  bool _hasAutoScannedBalance = false;
  bool _isAutoScanningTransactions = false;
  bool _hasHandledSmsPermission = false;
  bool _cloudSyncAvailable = true;
  DateTime? _smsTransactionCutoffAt;
  Future<void> _persistQueue = Future.value();
  Timer? _smsPollTimer;
  List<SmsBalanceSuggestion> _balanceSuggestions = [];

  final List<_MoneySource> _sources = [
    _MoneySource(
      name: 'Cash',
      type: _SourceType.cash,
      balance: null,
      color: const Color(0xFF166534),
      icon: Icons.payments_outlined,
    ),
    _MoneySource(
      name: 'bKash',
      type: _SourceType.mobileBanking,
      balance: null,
      color: const Color(0xFFC2185B),
      icon: Icons.account_balance_wallet_outlined,
    ),
    _MoneySource(
      name: 'AB Bank',
      type: _SourceType.bank,
      balance: null,
      color: const Color(0xFF1D4ED8),
      icon: Icons.account_balance_outlined,
    ),
  ];

  final List<_ActivityItem> _activities = [];

  double get _totalBalance {
    return _sources
        .where((source) => !source.archived)
        .fold(0.0, (total, source) => total + (source.balance ?? 0));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLedger();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsPollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoDetectTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final userName = _displayName(user?.userMetadata, user?.email);

    final pages = [
      _HomeTab(
        userName: userName,
        userEmail: user?.email ?? '',
        totalBalance: _totalBalance,
        balanceVisible: _balanceVisible,
        onBalanceTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _balanceVisible = !_balanceVisible;
          });
        },
        sources: _sources.where((source) => !source.archived).toList(),
        activities: _activities,
        balanceSuggestions: _balanceSuggestions,
        onViewSources: () => setState(() => _selectedIndex = 3),
        onSetBalance: _setSourceBalance,
        onUseSuggestedBalance: _useBalanceSuggestion,
        onEditSuggestedBalance: _editBalanceSuggestion,
        onIgnoreSuggestedBalance: _ignoreBalanceSuggestion,
      ),
      _SummaryTab(
        sources: _sources.where((source) => !source.archived).toList(),
        activities: _activities,
      ),
      _AddTab(
        sources: _sources.where((source) => !source.archived).toList(),
        onSave: _saveManualEntry,
      ),
      _SourcesTab(
        sources: _sources,
        onAddSource: _showAddSourceSheet,
        onSetBalance: _setSourceBalance,
        onTransfer: _showTransferDialog,
        onArchiveSource: (source) {
          setState(() {
            source.archived = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${source.name} archived.')),
          );
        },
      ),
      _MoreTab(
        sources: _sources,
        activities: _activities,
        onConfirmSuggestion: _confirmSmsSuggestion,
        onUseDetectedBalance: _useDetectedBalance,
        cloudSyncAvailable: _cloudSyncAvailable,
        onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _isLedgerLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Sources',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Future<void> _loadLedger() async {
    try {
      final user = ref.read(authControllerProvider).user;
      if (user == null) return;

      await ref.read(smsSuggestionManagerProvider.notifier).switchUser(user.id);
      final result = await _ledgerRepository.load(user.id);
      _cloudSyncAvailable = result.cloudAvailable;
      if (result.payload != null) {
        _applyLedgerJson(result.payload!);
      }

      if (_sources.any((source) => source.balance != null) &&
          _smsTransactionCutoffAt == null) {
        _smsTransactionCutoffAt = DateTime.now();
        await _persistLedger();
      }
      final cutoff = _smsTransactionCutoffAt;
      if (cutoff != null) {
        await ref
            .read(smsSuggestionManagerProvider.notifier)
            .discardBefore(cutoff);
      }
    } catch (_) {
      // Keep the default local structure if saved data is not readable.
    } finally {
      if (mounted) {
        setState(() => _isLedgerLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeSmsAssistant();
        });
      }
    }
  }

  Future<void> _initializeSmsAssistant() async {
    if (_hasHandledSmsPermission || !mounted) return;
    _hasHandledSmsPermission = true;

    final platform = ref.read(smsPlatformServiceProvider);
    var permission = await platform.permissionStatus();
    if (!permission.granted && permission.canAsk && mounted) {
      final shouldEnable = await showDialog<bool>(
        context: context,
        builder: (context) => const _SmsPermissionDialog(),
      );
      if (shouldEnable == true) {
        permission = await platform.requestPermission();
      }
    }

    if (!permission.granted || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SMS detection is disabled. You can continue using LaalKhata manually.',
            ),
          ),
        );
      }
      return;
    }

    await _autoDetectOpeningBalances();
    await _autoDetectTransactions();
    _smsPollTimer ??= Timer.periodic(
      const Duration(seconds: 20),
      (_) => _autoDetectTransactions(),
    );
  }

  Future<void> _showCloudSyncWarningIfNeeded() async {
    if (_cloudSyncAvailable || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Saved on this device. Cloud sync needs the latest database setup.',
        ),
      ),
    );
  }

  Future<void> _saveLedgerSnapshot(Map<String, dynamic> payload) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    _cloudSyncAvailable = await _ledgerRepository.save(user.id, payload);
  }

  Future<void> _persistLedger() async {
    final payload = _ledgerJson();
    _persistQueue = _persistQueue.then((_) => _saveLedgerSnapshot(payload));
    await _persistQueue;
  }

  Future<void> _autoDetectOpeningBalances() async {
    if (_hasAutoScannedBalance || !mounted) return;
    if (_sources.any((source) => source.balance != null)) return;

    _hasAutoScannedBalance = true;

    try {
      final platform = ref.read(smsPlatformServiceProvider);
      final permission = await platform.permissionStatus();
      if (!permission.granted) {
        _hasAutoScannedBalance = false;
        return;
      }

      final messages = await platform.readRecentSms(limit: 120);
      final suggestions = await ref
          .read(smsSuggestionManagerProvider.notifier)
          .detectLatestBalances(messages: messages);

      if (!mounted || suggestions.isEmpty) return;
      final unsetSuggestions = suggestions
          .where(
            (suggestion) =>
                _sourceByName(suggestion.sourceName)?.balance == null,
          )
          .toList();
      if (unsetSuggestions.isEmpty) return;
      setState(() {
        _balanceSuggestions = unsetSuggestions;
      });
    } catch (_) {
      // Auto scan must never interrupt the home page.
    }
  }

  Future<void> _autoDetectTransactions() async {
    if (_isLedgerLoading || _isAutoScanningTransactions || !mounted) return;
    if (!_sources.any((source) => source.balance != null) ||
        _smsTransactionCutoffAt == null) {
      await _autoDetectOpeningBalances();
      return;
    }

    _isAutoScanningTransactions = true;
    try {
      final platform = ref.read(smsPlatformServiceProvider);
      final permission = await platform.permissionStatus();
      if (!permission.granted) return;

      final messages = await platform.readRecentSms(limit: 80);
      final added =
          await ref.read(smsSuggestionManagerProvider.notifier).scanMessages(
                messages: messages,
                currentBalanceForSource: (sourceName) =>
                    _sourceByName(sourceName)?.balance,
                existingTransactions: _activities.map(
                  (activity) => ExistingTransactionSnapshot(
                    sourceName: activity.source,
                    amount: activity.amount.abs(),
                    direction: activity.amount >= 0
                        ? SmsTransactionDirection.credit
                        : SmsTransactionDirection.debit,
                    occurredAt: activity.occurredAt,
                  ),
                ),
                notBefore: _smsTransactionCutoffAt!,
              );

      if (!mounted || added == 0) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$added new SMS suggestion${added == 1 ? '' : 's'} found. Review from Detected Messages.',
          ),
          action: SnackBarAction(
            label: 'Review',
            onPressed: () => setState(() => _selectedIndex = 4),
          ),
        ),
      );
    } catch (_) {
      // Automatic detection stays silent on failure.
    } finally {
      _isAutoScanningTransactions = false;
    }
  }

  Future<bool> _saveManualEntry(_ManualEntry entry) async {
    final source = _sourceForName(entry.sourceName);
    if (entry.type == _EntryType.transfer) {
      final destinationName = entry.destinationSourceName;
      if (destinationName == null) return false;
      return _executeTransfer(
        from: source,
        to: _sourceForName(destinationName),
        amount: entry.amount,
        occurredAt: entry.date,
        reason: entry.reason,
      );
    }

    if (entry.type == _EntryType.balanceAdjustment) {
      final previous = source.balance;
      setState(() {
        source.balance = entry.amount;
        _activities.insert(
          0,
          _ActivityItem(
            name: entry.reason,
            source: source.name,
            amount: entry.amount - (previous ?? 0),
            time: _friendlyTime(entry.date),
            icon: Icons.tune_rounded,
            occurredAt: entry.date,
            category: entry.category,
            type: entry.type.name,
          ),
        );
        if (previous == null && _smsTransactionCutoffAt == null) {
          _smsTransactionCutoffAt = DateTime.now();
        }
      });
      await _persistLedger();
      return true;
    }

    final isCredit =
        entry.type == _EntryType.income || entry.type == _EntryType.borrowed;
    _ShortfallResolution? shortfall;
    if (!isCredit) {
      if (source.balance == null) {
        _showProfessionalMessage(
          'Set ${source.name} balance before recording an expense.',
        );
        return false;
      }
      if (entry.amount > source.balance!) {
        shortfall = await _resolveShortfall(
          source: source,
          requestedAmount: entry.amount,
        );
        if (shortfall == null || !mounted) return false;
      }
    }

    final signedAmount = isCredit ? entry.amount : -entry.amount;
    setState(() {
      if (isCredit) {
        source.balance = (source.balance ?? 0) + entry.amount;
      } else {
        final current = source.balance ?? 0;
        source.balance =
            (current - entry.amount).clamp(0, double.infinity).toDouble();
        final coverSource = shortfall?.coverSource;
        if (coverSource != null) {
          coverSource.balance = (coverSource.balance! - shortfall!.deficit)
              .clamp(0, double.infinity)
              .toDouble();
          _activities.insert(
            0,
            _ActivityItem(
              name: 'Covered ${source.name} shortfall',
              source: '${coverSource.name} → ${source.name}',
              amount: 0,
              time: _friendlyTime(entry.date),
              icon: Icons.swap_horiz_rounded,
              occurredAt: entry.date,
              category: 'Transfer',
              type: 'coverage',
            ),
          );
        } else if (shortfall != null) {
          _activities.insert(
            0,
            _ActivityItem(
              name: '${source.name} shortfall set to zero',
              source: source.name,
              amount: 0,
              time: _friendlyTime(entry.date),
              icon: Icons.info_outline_rounded,
              occurredAt: entry.date,
              category: 'Balance',
              type: 'shortfallIgnored',
            ),
          );
        }
      }
      _activities.insert(
        0,
        _ActivityItem(
          name: entry.reason,
          source: source.name,
          amount: signedAmount,
          time: _friendlyTime(entry.date),
          icon: source.icon,
          occurredAt: entry.date,
          category: entry.category,
          type: entry.type.name,
        ),
      );
    });
    await _persistLedger();
    await _showCloudSyncWarningIfNeeded();
    return true;
  }

  Future<bool> _confirmSmsSuggestion(
    SmsTransactionSuggestion suggestion,
  ) async {
    final source = _sourceForName(suggestion.sourceName);
    final signedAmount = suggestion.direction == SmsTransactionDirection.credit
        ? suggestion.amount
        : -suggestion.amount;
    _ShortfallResolution? shortfall;

    if (signedAmount < 0) {
      if (source.balance == null) {
        _showProfessionalMessage(
          'Set ${source.name} balance before confirming this transaction.',
        );
        return false;
      }
      if (suggestion.amount > source.balance!) {
        shortfall = await _resolveShortfall(
          source: source,
          requestedAmount: suggestion.amount,
        );
        if (shortfall == null || !mounted) return false;
      }
    }

    setState(() {
      source.balance = ((source.balance ?? 0) + signedAmount)
          .clamp(0, double.infinity)
          .toDouble();
      final coverSource = shortfall?.coverSource;
      if (coverSource != null) {
        coverSource.balance = (coverSource.balance! - shortfall!.deficit)
            .clamp(0, double.infinity)
            .toDouble();
        _activities.insert(
          0,
          _ActivityItem(
            name: 'Covered ${source.name} shortfall',
            source: '${coverSource.name} → ${source.name}',
            amount: 0,
            time: _friendlyTime(suggestion.occurredAt),
            icon: Icons.swap_horiz_rounded,
            occurredAt: suggestion.occurredAt,
            category: 'Transfer',
            type: 'coverage',
          ),
        );
      }
      _activities.insert(
        0,
        _ActivityItem(
          name: suggestion.reason,
          source: source.name,
          amount: signedAmount,
          time: _friendlyTime(suggestion.occurredAt),
          icon: source.icon,
          occurredAt: suggestion.occurredAt,
          category: 'SMS',
          type: suggestion.direction.name,
        ),
      );
    });
    await _persistLedger();
    await _showCloudSyncWarningIfNeeded();
    return true;
  }

  Future<_ShortfallResolution?> _resolveShortfall({
    required _MoneySource source,
    required double requestedAmount,
  }) async {
    final current = source.balance ?? 0;
    final deficit = requestedAmount - current;
    if (deficit <= 0) {
      return const _ShortfallResolution(deficit: 0);
    }
    final eligibleSources = _sources
        .where(
          (item) =>
              !item.archived &&
              item != source &&
              item.balance != null &&
              item.balance! >= deficit,
        )
        .toList();

    return showDialog<_ShortfallResolution>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ShortfallDialog(
        source: source,
        deficit: deficit,
        eligibleSources: eligibleSources,
      ),
    );
  }

  Future<void> _showTransferDialog() async {
    final active = _sources.where((source) => !source.archived).toList();
    if (active.length < 2) {
      _showProfessionalMessage('Add at least two sources to transfer money.');
      return;
    }
    final request = await showDialog<_TransferRequest>(
      context: context,
      builder: (context) => _TransferDialog(sources: active),
    );
    if (request == null || !mounted) return;
    final saved = await _executeTransfer(
      from: request.from,
      to: request.to,
      amount: request.amount,
      occurredAt: DateTime.now(),
      reason: 'Source transfer',
    );
    if (saved) {
      _showProfessionalMessage('Transfer completed.');
    }
  }

  Future<bool> _executeTransfer({
    required _MoneySource from,
    required _MoneySource to,
    required double amount,
    required DateTime occurredAt,
    required String reason,
  }) async {
    if (from == to || amount <= 0) return false;
    if (from.balance == null) {
      _showProfessionalMessage('Set ${from.name} balance before transferring.');
      return false;
    }
    if (from.balance! < amount) {
      _showProfessionalMessage(
        '${from.name} does not have enough balance for this transfer.',
      );
      return false;
    }

    setState(() {
      from.balance = from.balance! - amount;
      to.balance = (to.balance ?? 0) + amount;
      _activities.insert(
        0,
        _ActivityItem(
          name: reason,
          source: '${from.name} → ${to.name}',
          amount: amount,
          time: _friendlyTime(occurredAt),
          icon: Icons.swap_horiz_rounded,
          occurredAt: occurredAt,
          category: 'Transfer',
          type: 'transfer',
        ),
      );
    });
    await _persistLedger();
    await _showCloudSyncWarningIfNeeded();
    return true;
  }

  void _showProfessionalMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _useDetectedBalance({
    required String sourceName,
    required double balance,
    required bool wasUnset,
  }) {
    final source = _sourceForName(sourceName);
    final previous = source.balance;
    if (previous != null && (previous - balance).abs() < 0.005) {
      return;
    }
    final isFirstInitializedBalance =
        _sources.every((item) => item.balance == null);
    final now = DateTime.now();

    setState(() {
      source.balance = balance;
      if (isFirstInitializedBalance && _smsTransactionCutoffAt == null) {
        _smsTransactionCutoffAt = now;
      }
      _activities.insert(
        0,
        _ActivityItem(
          name: wasUnset ? 'Opening balance' : 'Balance adjustment',
          source: source.name,
          amount: previous == null ? balance : balance - previous,
          time: _friendlyTime(now),
          icon: Icons.tune_rounded,
          occurredAt: now,
          category: 'Balance',
          type: wasUnset ? 'openingBalance' : 'balanceAdjustment',
        ),
      );
    });
    _persistLedger();
    if (_smsTransactionCutoffAt != null) {
      ref
          .read(smsSuggestionManagerProvider.notifier)
          .discardBefore(_smsTransactionCutoffAt!);
    }
  }

  Future<void> _useBalanceSuggestion(SmsBalanceSuggestion suggestion) async {
    _useDetectedBalance(
      sourceName: suggestion.sourceName,
      balance: suggestion.balance,
      wasUnset: _sourceForName(suggestion.sourceName).balance == null,
    );
    setState(() {
      _balanceSuggestions = _balanceSuggestions
          .where((item) => item.sourceName != suggestion.sourceName)
          .toList();
    });
    await _persistLedger();
  }

  Future<void> _editBalanceSuggestion(SmsBalanceSuggestion suggestion) async {
    final source = _sourceForName(suggestion.sourceName);
    final edited = await showDialog<double>(
      context: context,
      builder: (context) => _BalanceEditorDialog(
        title: 'Edit ${source.name} Balance',
        initialBalance: suggestion.balance,
        confirmLabel: 'Use Balance',
      ),
    );

    if (edited == null || edited < 0) return;
    _useDetectedBalance(
      sourceName: suggestion.sourceName,
      balance: edited,
      wasUnset: source.balance == null,
    );
    setState(() {
      _balanceSuggestions = _balanceSuggestions
          .where((item) => item.sourceName != suggestion.sourceName)
          .toList();
    });
    await _persistLedger();
  }

  void _ignoreBalanceSuggestion(SmsBalanceSuggestion suggestion) {
    setState(() {
      _balanceSuggestions = _balanceSuggestions
          .where((item) => item.sourceName != suggestion.sourceName)
          .toList();
    });
  }

  _MoneySource _sourceForName(String sourceName) {
    final existing = _sourceByName(sourceName);
    if (existing != null) return existing;

    final source = _MoneySource(
      name: sourceName,
      type: _SourceType.mobileBanking,
      balance: null,
      color: AppColors.primary,
      icon: Icons.account_balance_wallet_outlined,
    );
    _sources.add(source);
    return source;
  }

  _MoneySource? _sourceByName(String sourceName) {
    final existing = _sources.where(
      (source) => source.name.toLowerCase() == sourceName.toLowerCase(),
    );
    if (existing.isEmpty) return null;
    return existing.first;
  }

  String _friendlyTime(DateTime value) {
    final now = DateTime.now();
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    if (value.year == now.year &&
        value.month == now.month &&
        value.day == now.day) {
      return 'Today, $time';
    }
    return '${value.day}/${value.month}/${value.year}, $time';
  }

  String _displayName(Map<String, dynamic>? metadata, String? email) {
    final name = metadata?['display_name'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    final emailName = email?.split('@').first.trim();
    if (emailName != null && emailName.isNotEmpty) return emailName;
    return 'LaalKhata User';
  }

  Future<void> _showAddSourceSheet() async {
    final source = await showModalBottomSheet<_MoneySource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddSourceSheet(),
    );

    if (source == null || !mounted) return;
    final isFirstInitializedBalance = source.balance != null &&
        _sources.every((item) => item.balance == null);
    setState(() {
      _sources.add(source);
      if (source.balance != null) {
        if (isFirstInitializedBalance && _smsTransactionCutoffAt == null) {
          _smsTransactionCutoffAt = DateTime.now();
        }
        _activities.insert(
          0,
          _ActivityItem(
            name: 'Opening balance',
            source: source.name,
            amount: source.balance!,
            time: _friendlyTime(DateTime.now()),
            icon: Icons.tune_rounded,
            occurredAt: DateTime.now(),
            category: 'Balance',
            type: 'openingBalance',
          ),
        );
      }
    });
    await _persistLedger();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${source.name} added to Sources.')),
    );
  }

  Future<void> _setSourceBalance(_MoneySource source) async {
    final balance = await showDialog<double>(
      context: context,
      builder: (context) => _BalanceEditorDialog(
        title: source.balance == null ? 'Set Balance' : 'Edit Balance',
        initialBalance: source.balance,
        confirmLabel: 'Save',
      ),
    );

    if (balance == null || balance < 0 || !mounted) return;
    _useDetectedBalance(
      sourceName: source.name,
      balance: balance,
      wasUnset: source.balance == null,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Balance updated.')),
    );
    await _showCloudSyncWarningIfNeeded();
  }

  Map<String, dynamic> _ledgerJson() {
    return {
      'sources': _sources.map((source) => source.toJson()).toList(),
      'activities': _activities.map((activity) => activity.toJson()).toList(),
      'smsTransactionCutoffAt': _smsTransactionCutoffAt?.toIso8601String(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  void _applyLedgerJson(Map<String, dynamic> json) {
    final sources = (json['sources'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map(_MoneySource.fromJson)
        .whereType<_MoneySource>()
        .toList();
    final activities = (json['activities'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map(_ActivityItem.fromJson)
        .whereType<_ActivityItem>()
        .toList();
    _smsTransactionCutoffAt =
        DateTime.tryParse('${json['smsTransactionCutoffAt']}');

    if (sources != null && sources.isNotEmpty) {
      _sources
        ..clear()
        ..addAll(sources);
    }
    if (activities != null) {
      _activities
        ..clear()
        ..addAll(activities);
    }
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.userName,
    required this.userEmail,
    required this.totalBalance,
    required this.balanceVisible,
    required this.onBalanceTap,
    required this.sources,
    required this.activities,
    required this.balanceSuggestions,
    required this.onViewSources,
    required this.onSetBalance,
    required this.onUseSuggestedBalance,
    required this.onEditSuggestedBalance,
    required this.onIgnoreSuggestedBalance,
  });

  final String userName;
  final String userEmail;
  final double totalBalance;
  final bool balanceVisible;
  final VoidCallback onBalanceTap;
  final List<_MoneySource> sources;
  final List<_ActivityItem> activities;
  final List<SmsBalanceSuggestion> balanceSuggestions;
  final VoidCallback onViewSources;
  final ValueChanged<_MoneySource> onSetBalance;
  final ValueChanged<SmsBalanceSuggestion> onUseSuggestedBalance;
  final ValueChanged<SmsBalanceSuggestion> onEditSuggestedBalance;
  final ValueChanged<SmsBalanceSuggestion> onIgnoreSuggestedBalance;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        _HomeHeader(
          userName: userName,
          userEmail: userEmail,
          totalBalance: totalBalance,
          balanceVisible: balanceVisible,
          onBalanceTap: onBalanceTap,
        ),
        const SizedBox(height: 18),
        if (balanceSuggestions.isNotEmpty) ...[
          _OpeningBalanceSuggestionsCard(
            suggestions: balanceSuggestions,
            onUse: onUseSuggestedBalance,
            onEdit: onEditSuggestedBalance,
            onIgnore: onIgnoreSuggestedBalance,
          ),
          const SizedBox(height: 18),
        ],
        _SectionHeader(
          title: 'Active Sources',
          actionLabel: 'View All',
          onAction: onViewSources,
        ),
        const SizedBox(height: 10),
        _ActiveSourcesCard(
          sources: sources.take(5).toList(),
          onSetBalance: onSetBalance,
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Recent Activity'),
        const SizedBox(height: 10),
        _RecentActivityCard(activities: activities),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userName,
    required this.userEmail,
    required this.totalBalance,
    required this.balanceVisible,
    required this.onBalanceTap,
  });

  final String userName;
  final String userEmail;
  final double totalBalance;
  final bool balanceVisible;
  final VoidCallback onBalanceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -70,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _GlassBalanceCard(
                    visible: balanceVisible,
                    amount: totalBalance,
                    onTap: onBalanceTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassBalanceCard extends StatelessWidget {
  const _GlassBalanceCard({
    required this.visible,
    required this.amount,
    required this.onTap,
  });

  final bool visible;
  final double amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: visible
                    ? Row(
                        key: const ValueKey('visible-balance'),
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Balance',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _money(amount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.visibility_off_outlined,
                            color: Colors.white,
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('hidden-balance'),
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tap for Balance',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: Colors.white,
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

class _OpeningBalanceSuggestionsCard extends StatelessWidget {
  const _OpeningBalanceSuggestionsCard({
    required this.suggestions,
    required this.onUse,
    required this.onEdit,
    required this.onIgnore,
  });

  final List<SmsBalanceSuggestion> suggestions;
  final ValueChanged<SmsBalanceSuggestion> onUse;
  final ValueChanged<SmsBalanceSuggestion> onEdit;
  final ValueChanged<SmsBalanceSuggestion> onIgnore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconBubble(
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Possible balances found',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review before adding. Nothing changes automatically.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedInk,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final suggestion in suggestions) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.altSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    _ProviderLogo(
                      sourceName: suggestion.sourceName,
                      fallbackIcon: Icons.account_balance_wallet_outlined,
                      fallbackColor: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.sourceName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _money(suggestion.balance),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit balance',
                      onPressed: () => onEdit(suggestion),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                    TextButton(
                      onPressed: () => onIgnore(suggestion),
                      child: const Text('Ignore'),
                    ),
                    FilledButton(
                      onPressed: () => onUse(suggestion),
                      child: const Text('Use'),
                    ),
                  ],
                ),
              ),
              if (suggestion != suggestions.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveSourcesCard extends StatelessWidget {
  const _ActiveSourcesCard({
    required this.sources,
    required this.onSetBalance,
  });

  final List<_MoneySource> sources;
  final ValueChanged<_MoneySource> onSetBalance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final source in sources) ...[
              _SourceListTile(
                source: source,
                trailing: IconButton(
                  tooltip: 'Edit balance',
                  onPressed: () => onSetBalance(source),
                  icon: const Icon(Icons.edit_rounded),
                ),
              ),
              if (source != sources.last) const Divider(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.activities});

  final List<_ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final activity in activities) ...[
              Row(
                children: [
                  _IconBubble(
                    icon: activity.icon,
                    color: activity.amount >= 0
                        ? AppColors.positive
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activity.source} • ${activity.time}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.mutedInk,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    activity.type == 'transfer'
                        ? _money(activity.amount)
                        : activity.amount == 0
                            ? 'Recorded'
                            : '${activity.amount >= 0 ? '+' : '-'}${_money(activity.amount.abs())}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: activity.type == 'transfer' ||
                                  activity.amount == 0
                              ? AppColors.mutedInk
                              : activity.amount >= 0
                                  ? AppColors.positive
                                  : AppColors.danger,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              if (activity != activities.last) const Divider(height: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.sources,
    required this.activities,
  });

  final List<_MoneySource> sources;
  final List<_ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        const _PageTitle(
          title: 'Summary',
          subtitle: 'Spending analysis and target progress',
        ),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          const _EmptyInsightCard()
        else ...[
          const _FilterPillRow(items: ['This Month', 'Daily', 'Sources']),
          const SizedBox(height: 16),
          _SummaryHeroCard(activities: activities),
          const SizedBox(height: 16),
          _BreakdownCard(
            title: 'Source Breakdown',
            items: sources
                .where((source) => source.balance != null)
                .map(
                  (source) => _BreakdownItem(
                    label: source.name,
                    value: source.balance ?? 0,
                    color: source.color,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _BreakdownCard(
            title: 'Category Breakdown',
            items: _categoryBreakdown(),
          ),
        ],
      ],
    );
  }

  List<_BreakdownItem> _categoryBreakdown() {
    final colors = [
      AppColors.primary,
      AppColors.warning,
      AppColors.accent,
      AppColors.positive,
      const Color(0xFF2563EB),
    ];
    final totals = <String, double>{};
    for (final activity in activities.where(_isExpenseActivity)) {
      totals.update(
        activity.category,
        (value) => value + activity.amount.abs(),
        ifAbsent: () => activity.amount.abs(),
      );
    }
    var index = 0;
    return totals.entries.map((entry) {
      final item = _BreakdownItem(
        label: entry.key,
        value: entry.value,
        color: colors[index % colors.length],
      );
      index++;
      return item;
    }).toList();
  }
}

class _AddTab extends StatefulWidget {
  const _AddTab({
    required this.sources,
    required this.onSave,
  });

  final List<_MoneySource> sources;
  final Future<bool> Function(_ManualEntry entry) onSave;

  @override
  State<_AddTab> createState() => _AddTabState();
}

class _AddTabState extends State<_AddTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  _EntryType _type = _EntryType.expense;
  String _sourceName = 'Cash';
  String? _destinationSourceName;
  String _category = 'Others';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceNames = widget.sources.map((source) => source.name).toList();
    if (!sourceNames.contains(_sourceName) && sourceNames.isNotEmpty) {
      _sourceName = sourceNames.first;
    }
    final destinationOptions =
        sourceNames.where((name) => name != _sourceName).toList();
    if (!destinationOptions.contains(_destinationSourceName)) {
      _destinationSourceName =
          destinationOptions.isEmpty ? null : destinationOptions.first;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        const _PageTitle(
          title: 'Add',
          subtitle: 'Record income, expense, transfer, dues, or adjustments',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EntryTypeSelector(
                    selected: _type,
                    onSelected: (value) => setState(() => _type = value),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Name / Reason',
                      prefixIcon: Icon(Icons.edit_note_outlined),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Name or reason is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue:
                        sourceNames.contains(_sourceName) ? _sourceName : null,
                    decoration: const InputDecoration(
                      labelText: 'Source',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: sourceNames
                        .map(
                          (source) => DropdownMenuItem(
                            value: source,
                            child: Text(source),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _sourceName = value;
                        if (_destinationSourceName == value) {
                          _destinationSourceName = sourceNames.firstWhere(
                            (name) => name != value,
                            orElse: () => value,
                          );
                        }
                      });
                    },
                  ),
                  if (_type == _EntryType.transfer) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue:
                          destinationOptions.contains(_destinationSourceName)
                              ? _destinationSourceName
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Transfer to',
                        prefixIcon: Icon(Icons.call_received_rounded),
                      ),
                      items: destinationOptions
                          .map(
                            (source) => DropdownMenuItem(
                              value: source,
                              child: Text(source),
                            ),
                          )
                          .toList(),
                      validator: (value) {
                        if (_type == _EntryType.transfer && value == null) {
                          return 'Select a destination source.';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() => _destinationSourceName = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.payments_outlined),
                      prefixText: '৳ ',
                    ),
                    validator: (value) {
                      final amount = double.tryParse((value ?? '').trim());
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          'Others',
                          'Food',
                          'Transport',
                          'Study',
                          'Hall',
                          'Treat/Party',
                        ]
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      _DateField(
                        date: _date,
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save Transaction'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());

    final saved = await widget.onSave(
      _ManualEntry(
        type: _type,
        reason: _nameController.text.trim(),
        sourceName: _sourceName,
        amount: amount,
        category: _category,
        note: _noteController.text.trim(),
        date: _date,
        destinationSourceName:
            _type == _EntryType.transfer ? _destinationSourceName : null,
      ),
    );
    if (!mounted || !saved) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction saved.')),
    );

    _nameController.clear();
    _amountController.clear();
    _noteController.clear();
  }
}

class _SourcesTab extends StatelessWidget {
  const _SourcesTab({
    required this.sources,
    required this.onAddSource,
    required this.onSetBalance,
    required this.onTransfer,
    required this.onArchiveSource,
  });

  final List<_MoneySource> sources;
  final VoidCallback onAddSource;
  final ValueChanged<_MoneySource> onSetBalance;
  final VoidCallback onTransfer;
  final ValueChanged<_MoneySource> onArchiveSource;

  @override
  Widget build(BuildContext context) {
    final activeSources = sources.where((source) => !source.archived).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        _PageTitle(
          title: 'Sources',
          subtitle: 'Manage wallets, banks, cards, savings, and custom sources',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                tooltip: 'Transfer between sources',
                onPressed: onTransfer,
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Add source',
                onPressed: onAddSource,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final source in activeSources) ...[
                  _SourceListTile(
                    source: source,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'balance') onSetBalance(source);
                        if (value == 'archive') onArchiveSource(source);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'balance',
                          child: Text(
                            source.balance == null
                                ? 'Set Balance'
                                : 'Edit Balance',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'archive',
                          child: Text('Archive'),
                        ),
                      ],
                    ),
                  ),
                  if (source != activeSources.last) const Divider(height: 18),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreTab extends ConsumerWidget {
  const _MoreTab({
    required this.sources,
    required this.activities,
    required this.onConfirmSuggestion,
    required this.onUseDetectedBalance,
    required this.cloudSyncAvailable,
    required this.onSignOut,
  });

  final List<_MoneySource> sources;
  final List<_ActivityItem> activities;
  final Future<bool> Function(SmsTransactionSuggestion suggestion)
      onConfirmSuggestion;
  final void Function({
    required String sourceName,
    required double balance,
    required bool wasUnset,
  }) onUseDetectedBalance;
  final bool cloudSyncAvailable;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        const _PageTitle(
          title: 'More',
          subtitle: 'Profile, settings, lists, security, and records',
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _MoreTile(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'Account and IUT identity',
                onTap: () => _showProfile(context, ref),
              ),
              _MoreTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Preferences and app behavior',
                onTap: () => _showComingSoon(context, 'Settings'),
              ),
              _MoreTile(
                icon: Icons.compare_arrows_rounded,
                title: 'Loans & Dues',
                subtitle: 'Due to Receive and Need to Pay',
                onTap: () => _showComingSoon(context, 'Loans & Dues'),
              ),
              _MoreTile(
                icon: Icons.checklist_rounded,
                title: 'Projects & Lists',
                subtitle: 'Milestones, bazar lists, hobbies, and notes',
                onTap: () => _showComingSoon(context, 'Projects & Lists'),
              ),
              _MoreTile(
                icon: Icons.receipt_long_outlined,
                title: 'Transaction History',
                subtitle: 'All expenses, income, transfers, and adjustments',
                onTap: () => _showTransactionHistory(context),
              ),
              _MoreTile(
                icon: Icons.sms_outlined,
                title: 'Detected Messages',
                subtitle: 'Pending SMS suggestions will appear here',
                onTap: () => _showDetectedMessages(context),
              ),
              _MoreTile(
                icon: cloudSyncAvailable
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                title: 'Cloud Sync',
                subtitle: cloudSyncAvailable
                    ? 'Your ledger is synced across devices'
                    : 'Database setup required for cross-device restore',
                onTap: () => _showCloudStatus(context),
              ),
              _MoreTile(
                icon: Icons.file_download_outlined,
                title: 'Export',
                subtitle: 'Download records and reports',
                onTap: () => _showComingSoon(context, 'Export'),
              ),
              _MoreTile(
                icon: Icons.delete_outline,
                title: 'Trash / Recently Deleted',
                subtitle: 'Restore archived or deleted records',
                onTap: () => _showComingSoon(context, 'Trash'),
              ),
              _MoreTile(
                icon: Icons.security_outlined,
                title: 'Security',
                subtitle: 'PIN, fingerprint, and device settings',
                onTap: () => _showSecuritySheet(context),
              ),
              _MoreTile(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'End this device session',
                onTap: onSignOut,
                isDanger: true,
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title will be connected in the next build.')),
    );
  }

  void _showProfile(BuildContext context, WidgetRef ref) {
    final user = ref.read(authControllerProvider).user;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ProfileSheet(
        email: user?.email ?? '',
        metadata: user?.userMetadata ?? const {},
      ),
    );
  }

  void _showDetectedMessages(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DetectedMessagesSheet(
        sources: sources,
        activities: activities,
        onConfirmSuggestion: onConfirmSuggestion,
        onUseDetectedBalance: onUseDetectedBalance,
      ),
    );
  }

  void _showTransactionHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _TransactionHistorySheet(
        activities: activities,
      ),
    );
  }

  void _showCloudStatus(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cloudSyncAvailable
              ? 'Your latest ledger is available for cross-device restore.'
              : 'Run the latest Supabase schema to enable cloud restore.',
        ),
      ),
    );
  }

  void _showSecuritySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _SecuritySheet(),
    );
  }
}

class _TransactionHistorySheet extends StatelessWidget {
  const _TransactionHistorySheet({required this.activities});

  final List<_ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(
              children: [
                const _IconBubble(
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Transaction History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const _DetectedMessagesEmptyState()
            else
              _RecentActivityCard(activities: activities),
          ],
        );
      },
    );
  }
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({
    required this.email,
    required this.metadata,
  });

  final String email;
  final Map<String, dynamic> metadata;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = '${widget.metadata['display_name'] ?? 'LaalKhata User'}';
    final role = '${widget.metadata['role'] ?? 'Student'}';
    final department = '${widget.metadata['department'] ?? ''}';
    final studentId = '${widget.metadata['student_id'] ?? ''}';
    final batch = '${widget.metadata['batch'] ?? ''}';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        name.trim().isEmpty
                            ? 'L'
                            : name.trim()[0].toUpperCase(),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 14,
                          color: Colors.white,
                          onPressed: () {
                            setState(() {
                              _message =
                                  'Profile photo upload will be connected with storage next.';
                            });
                          },
                          icon: const Icon(Icons.edit_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedInk,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              _SecurityMessage(message: _message!),
            ],
            const SizedBox(height: 18),
            _ReadonlyProfileRow(label: 'Role', value: role),
            if (department.trim().isNotEmpty)
              _ReadonlyProfileRow(label: 'Department', value: department),
            if (studentId.trim().isNotEmpty)
              _ReadonlyProfileRow(label: 'Student ID', value: studentId),
            if (batch.trim().isNotEmpty)
              _ReadonlyProfileRow(label: 'Batch', value: batch),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                setState(() => _message = 'Profile saved on this device.');
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadonlyProfileRow extends StatelessWidget {
  const _ReadonlyProfileRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetectedMessagesSheet extends ConsumerStatefulWidget {
  const _DetectedMessagesSheet({
    required this.sources,
    required this.activities,
    required this.onConfirmSuggestion,
    required this.onUseDetectedBalance,
  });

  final List<_MoneySource> sources;
  final List<_ActivityItem> activities;
  final Future<bool> Function(SmsTransactionSuggestion suggestion)
      onConfirmSuggestion;
  final void Function({
    required String sourceName,
    required double balance,
    required bool wasUnset,
  }) onUseDetectedBalance;

  @override
  ConsumerState<_DetectedMessagesSheet> createState() =>
      _DetectedMessagesSheetState();
}

class _DetectedMessagesSheetState
    extends ConsumerState<_DetectedMessagesSheet> {
  var _showIgnored = false;
  String? _message;
  bool _messageIsDanger = false;

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(smsSuggestionManagerProvider.notifier);
    final suggestions = ref.watch(smsSuggestionManagerProvider);
    final pending = suggestions
        .where((item) => item.status == SmsSuggestionStatus.pending)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final ignored = suggestions
        .where((item) => item.status == SmsSuggestionStatus.ignored)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final activeList = _showIgnored ? ignored : pending;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(
              children: [
                const _IconBubble(
                  icon: Icons.sms_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Detected Messages',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _SmsPrivacyNotice(),
            if (_message != null) ...[
              const SizedBox(height: 12),
              _SecurityMessage(
                message: _message!,
                isDanger: _messageIsDanger,
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text('Pending (${pending.length})'),
                  icon: const Icon(Icons.pending_actions_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Ignored (${ignored.length})'),
                  icon: const Icon(Icons.hide_source_outlined),
                ),
              ],
              selected: {_showIgnored},
              onSelectionChanged: (value) {
                setState(() => _showIgnored = value.first);
              },
            ),
            const SizedBox(height: 16),
            if (activeList.isEmpty)
              const _DetectedMessagesEmptyState()
            else
              for (final suggestion in activeList) ...[
                if (_showIgnored)
                  _IgnoredSuggestionTile(suggestion: suggestion)
                else
                  _SmsSuggestionCard(
                    suggestion: suggestion,
                    sources: widget.sources,
                    currentBalance: _balanceForSource(suggestion.sourceName),
                    onConfirm: (updatedSuggestion) =>
                        _confirmSuggestion(manager, updatedSuggestion),
                    onIgnore: () => _ignoreSuggestion(manager, suggestion.id),
                    onUseDetectedBalance: widget.onUseDetectedBalance,
                  ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }

  double? _balanceForSource(String sourceName) {
    final source = widget.sources.where(
      (item) => item.name.toLowerCase() == sourceName.toLowerCase(),
    );
    if (source.isEmpty) return null;
    return source.first.balance;
  }

  Future<void> _confirmSuggestion(
    SmsSuggestionManager manager,
    SmsTransactionSuggestion suggestion,
  ) async {
    final confirmed = await widget.onConfirmSuggestion(suggestion);
    if (!confirmed) {
      _showMessage(
        'Transaction was not confirmed. Review the selected source balance.',
        isDanger: true,
      );
      return;
    }
    await manager.removeSuggestion(suggestion.id);
    _showMessage('Transaction confirmed.');
  }

  Future<void> _ignoreSuggestion(
    SmsSuggestionManager manager,
    String id,
  ) async {
    await manager.ignoreSuggestion(id);
    _showMessage('Transaction ignored.');
  }

  void _showMessage(String message, {bool isDanger = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsDanger = isDanger;
    });
  }
}

class _SmsPrivacyNotice extends StatelessWidget {
  const _SmsPrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SMS is only used locally to suggest transactions. LaalKhata never uploads raw SMS messages.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectedMessagesEmptyState extends StatelessWidget {
  const _DetectedMessagesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const _IconBubble(
              icon: Icons.mark_chat_unread_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No detected transactions.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmsSuggestionCard extends StatefulWidget {
  const _SmsSuggestionCard({
    required this.suggestion,
    required this.sources,
    required this.currentBalance,
    required this.onConfirm,
    required this.onIgnore,
    required this.onUseDetectedBalance,
  });

  final SmsTransactionSuggestion suggestion;
  final List<_MoneySource> sources;
  final double? currentBalance;
  final Future<void> Function(SmsTransactionSuggestion suggestion) onConfirm;
  final VoidCallback onIgnore;
  final void Function({
    required String sourceName,
    required double balance,
    required bool wasUnset,
  }) onUseDetectedBalance;

  @override
  State<_SmsSuggestionCard> createState() => _SmsSuggestionCardState();
}

class _SmsSuggestionCardState extends State<_SmsSuggestionCard> {
  late final TextEditingController _reasonController;
  late final TextEditingController _amountController;
  late String _sourceName;
  late SmsTransactionDirection _direction;
  var _balancePromptDismissed = false;
  final _balanceInitializer = const SmsBalanceInitializer();

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.suggestion.reason);
    _amountController = TextEditingController(
      text: widget.suggestion.amount.toStringAsFixed(0),
    );
    _sourceName = widget.suggestion.sourceName;
    _direction = widget.suggestion.direction;
    _reasonController.addListener(_refresh);
    _amountController.addListener(_refresh);
  }

  @override
  void dispose() {
    _reasonController
      ..removeListener(_refresh)
      ..dispose();
    _amountController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final detectedBalance = widget.suggestion.detectedBalance;
    final currentBalance = _currentBalance;
    final canSuggestBalance = !_balancePromptDismissed &&
        _balanceInitializer.canSuggestOpeningBalance(
          suggestion: widget.suggestion,
          currentBalance: currentBalance,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _ProviderLogo(
                  sourceName: widget.suggestion.sourceName,
                  fallbackIcon: Icons.receipt_long_outlined,
                  fallbackColor: _direction == SmsTransactionDirection.credit
                      ? AppColors.positive
                      : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.suggestion.provider.label} Transaction Detected',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDetectedTime(widget.suggestion.occurredAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedInk,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.suggestion.duplicateWarning) ...[
              const SizedBox(height: 12),
              const _DuplicateWarningBanner(),
            ],
            if (canSuggestBalance && detectedBalance != null) ...[
              const SizedBox(height: 12),
              _DetectedBalancePrompt(
                sourceName: _sourceName,
                balance: detectedBalance,
                onUse: () => widget.onUseDetectedBalance(
                  sourceName: _sourceName,
                  balance: detectedBalance,
                  wasUnset: true,
                ),
                onEdit: () => _editDetectedBalance(detectedBalance),
                onIgnore: () => setState(() => _balancePromptDismissed = true),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sourceName,
              decoration: const InputDecoration(
                labelText: 'Source',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: _sourceOptions
                  .map(
                    (source) => DropdownMenuItem(
                      value: source,
                      child: Text(source),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sourceName = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '৳ ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SmsTransactionDirection>(
              initialValue: _direction,
              decoration: const InputDecoration(
                labelText: 'Transaction Type',
                prefixIcon: Icon(Icons.swap_vert_rounded),
              ),
              items: SmsTransactionDirection.values
                  .map(
                    (direction) => DropdownMenuItem(
                      value: direction,
                      child: Text(direction.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _direction = value);
              },
            ),
            if (detectedBalance != null) ...[
              const SizedBox(height: 12),
              _ReadonlyField(
                label: 'Detected Balance',
                value: _money(detectedBalance),
              ),
            ],
            const SizedBox(height: 12),
            _BalancePreview(
              currentBalance: currentBalance,
              sourceName: _sourceName,
              amount: amount,
              direction: _direction,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onIgnore,
                    child: const Text('Ignore'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: amount <= 0 ? null : _confirm,
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _sourceOptions {
    final names = widget.sources.map((source) => source.name).toList();
    if (!names.any((name) => name.toLowerCase() == _sourceName.toLowerCase())) {
      names.add(_sourceName);
    }
    return names;
  }

  double? get _currentBalance {
    final matches = widget.sources.where(
      (source) => source.name.toLowerCase() == _sourceName.toLowerCase(),
    );
    if (matches.isEmpty) return widget.currentBalance;
    return matches.first.balance;
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountController.text.trim());
    final reason = _reasonController.text.trim();
    if (amount == null || amount <= 0 || reason.isEmpty) return;

    final updated = widget.suggestion.copyWith(
      amount: amount,
      direction: _direction,
      reason: reason,
      sourceName: _sourceName,
    );

    if (widget.suggestion.duplicateWarning) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Possible Duplicate'),
          content: const Text(
            'Similar transaction already exists.\n\nConfirming may create a duplicate.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );
      if (shouldContinue != true) return;
    }

    await widget.onConfirm(updated);
  }

  Future<void> _editDetectedBalance(double detectedBalance) async {
    final edited = await showDialog<double>(
      context: context,
      builder: (context) => _BalanceEditorDialog(
        title: 'Edit Detected Balance',
        initialBalance: detectedBalance,
        confirmLabel: 'Use Balance',
      ),
    );

    if (edited == null || edited < 0) return;
    widget.onUseDetectedBalance(
      sourceName: _sourceName,
      balance: edited,
      wasUnset: _currentBalance == null,
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _formatDetectedTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year}, $hour:$minute';
  }
}

class _DuplicateWarningBanner extends StatelessWidget {
  const _DuplicateWarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Text(
        'Similar transaction already exists. Confirming may create a duplicate.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _DetectedBalancePrompt extends StatelessWidget {
  const _DetectedBalancePrompt({
    required this.sourceName,
    required this.balance,
    required this.onUse,
    required this.onEdit,
    required this.onIgnore,
  });

  final String sourceName;
  final double balance;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.positive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.positive.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Possible balance found',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$sourceName detected balance: ${_money(balance)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onUse,
                child: const Text('Use Balance'),
              ),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: onIgnore,
                child: const Text('Ignore'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _BalancePreview extends StatelessWidget {
  const _BalancePreview({
    required this.currentBalance,
    required this.sourceName,
    required this.amount,
    required this.direction,
  });

  final double? currentBalance;
  final String sourceName;
  final double amount;
  final SmsTransactionDirection direction;

  @override
  Widget build(BuildContext context) {
    final preview = currentBalance == null
        ? null
        : direction == SmsTransactionDirection.credit
            ? currentBalance! + amount
            : currentBalance! - amount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        preview == null
            ? '$sourceName balance preview: Balance not set'
            : '$sourceName balance preview: ${_money(preview)}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _IgnoredSuggestionTile extends StatelessWidget {
  const _IgnoredSuggestionTile({required this.suggestion});

  final SmsTransactionSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.hide_source_outlined),
        title:
            Text('${suggestion.provider.label} ${_money(suggestion.amount)}'),
        subtitle: Text(suggestion.reason),
      ),
    );
  }
}

class _SecuritySheet extends ConsumerStatefulWidget {
  const _SecuritySheet();

  @override
  ConsumerState<_SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends ConsumerState<_SecuritySheet> {
  bool _isBusy = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final biometricService = ref.read(biometricAuthServiceProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: FutureBuilder<(bool, FingerprintAvailability)>(
        future: _loadSecurityState(),
        builder: (context, snapshot) {
          final fingerprintEnabled = snapshot.data?.$1 ?? false;
          final availability = snapshot.data?.$2;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Security',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your PIN stays local on this phone. Keep at least one unlock method active.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedInk,
                      height: 1.4,
                    ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 14),
                _SecurityMessage(message: _message!),
              ],
              const SizedBox(height: 18),
              _SecurityActionTile(
                icon: Icons.pin_outlined,
                title: 'Local PIN',
                subtitle: 'Enabled. Change your 5-digit PIN.',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _isBusy ? null : _openChangePinSheet,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: SwitchListTile(
                  value: fingerprintEnabled,
                  onChanged: _isBusy
                      ? null
                      : (value) {
                          if (value) {
                            _enableFingerprint(
                              biometricService,
                              availability,
                            );
                          } else {
                            _disableFingerprint(biometricService);
                          }
                        },
                  title: const Text('Fingerprint unlock'),
                  subtitle: Text(
                    fingerprintEnabled
                        ? 'Enabled on this device.'
                        : availability == null
                            ? 'Checking fingerprint availability...'
                            : availability.isAvailable
                                ? 'Off. Turn on after fingerprint confirmation.'
                                : availability.message,
                  ),
                  secondary: const Icon(Icons.fingerprint_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'PIN cannot be removed because LaalKhata needs at least one local unlock method.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                      height: 1.35,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<(bool, FingerprintAvailability)> _loadSecurityState() async {
    final biometricService = ref.read(biometricAuthServiceProvider);
    final enabled = await biometricService.isFingerprintEnabled();
    final availability = await biometricService.fingerprintAvailability();
    return (enabled, availability);
  }

  Future<void> _openChangePinSheet() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _ChangePinSheet(),
    );

    if (!mounted || changed != true) return;
    setState(() {
      _message = 'PIN changed successfully.';
    });
  }

  Future<void> _enableFingerprint(
    BiometricAuthService service,
    FingerprintAvailability? availability,
  ) async {
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final ready = availability ?? await service.fingerprintAvailability();
      if (!ready.isAvailable) {
        setState(() {
          _message = ready.message;
        });
        return;
      }

      final result = await service.authenticate(
        reason: 'Confirm fingerprint to enable LaalKhata unlock',
      );

      if (result.status == BiometricAuthStatus.success) {
        await service.enableFingerprint();
        if (!mounted) return;
        setState(() {
          _message = 'Fingerprint unlock enabled.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _message = result.message ?? 'Fingerprint setup was not completed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _disableFingerprint(BiometricAuthService service) async {
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      await service.disableFingerprint();
      if (!mounted) return;
      setState(() {
        _message = 'Fingerprint unlock disabled. PIN unlock remains active.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }
}

class _ChangePinSheet extends ConsumerStatefulWidget {
  const _ChangePinSheet();

  @override
  ConsumerState<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends ConsumerState<_ChangePinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isSaving = false;
  String? _message;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change PIN',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verify your current PIN before setting a new 5-digit PIN.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.4,
                  ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              _SecurityMessage(message: _message!, isDanger: true),
            ],
            const SizedBox(height: 18),
            _SecurityPinField(
              controller: _currentPinController,
              label: 'Current PIN',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _SecurityPinField(
              controller: _newPinController,
              label: 'New PIN',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _SecurityPinField(
              controller: _confirmPinController,
              label: 'Confirm new PIN',
              textInputAction: TextInputAction.done,
              validator: (value) {
                final pin = value ?? '';
                if (!RegExp(r'^\d{5}$').hasMatch(pin)) {
                  return 'Enter a 5-digit PIN.';
                }
                if (pin != _newPinController.text) {
                  return 'PINs do not match.';
                }
                return null;
              },
              onSubmitted: (_) => _changePin(),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _changePin,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save New PIN'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    final service = ref.read(localPinServiceProvider);
    final result = await service.verifyPin(_currentPinController.text);
    if (!mounted) return;

    if (result.status != PinVerifyStatus.success) {
      setState(() {
        _isSaving = false;
        _message = result.status == PinVerifyStatus.locked
            ? 'Too many failed attempts. Try again in ${_formatDuration(result.lockedFor)}.'
            : result.message ?? 'Current PIN did not match.';
      });
      return;
    }

    try {
      await service.setPin(_newPinController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'PIN could not be changed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatDuration(Duration? duration) {
    final value = duration ?? Duration.zero;
    if (value.inMinutes >= 1) return '${value.inMinutes} min';
    return '${value.inSeconds} sec';
  }
}

class _SecurityPinField extends StatelessWidget {
  const _SecurityPinField({
    required this.controller,
    required this.label,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      maxLength: 5,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: const Icon(Icons.pin_outlined),
      ),
      validator: validator ??
          (value) {
            if (!RegExp(r'^\d{5}$').hasMatch(value ?? '')) {
              return 'Enter a 5-digit PIN.';
            }
            return null;
          },
      onFieldSubmitted: onSubmitted,
    );
  }
}

class _SecurityActionTile extends StatelessWidget {
  const _SecurityActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedInk,
                          ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityMessage extends StatelessWidget {
  const _SecurityMessage({
    required this.message,
    this.isDanger = false,
  });

  final String message;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _AddSourceSheet extends StatefulWidget {
  const _AddSourceSheet();

  @override
  State<_AddSourceSheet> createState() => _AddSourceSheetState();
}

class _AddSourceSheetState extends State<_AddSourceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  _SourceType _type = _SourceType.cash;
  Color _color = AppColors.primary;

  static const _colors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.positive,
    AppColors.warning,
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Source',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Source name',
                  prefixIcon: Icon(Icons.wallet_outlined),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Source name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<_SourceType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _SourceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (type) {
                  if (type == null) return;
                  setState(() => _type = type);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _balanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Opening balance (optional)',
                  prefixText: '৳ ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) return null;
                  final amount = double.tryParse(trimmed);
                  if (amount == null || amount < 0) {
                    return 'Enter a valid opening balance.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Text(
                'Custom color',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _colors
                    .map(
                      (color) => InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => setState(() => _color = color),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == color
                                  ? AppColors.ink
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.add),
                label: const Text('Add Source'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final balanceText = _balanceController.text.trim();

    Navigator.of(context).pop(
      _MoneySource(
        name: _nameController.text.trim(),
        type: _type,
        balance: balanceText.isEmpty ? null : double.parse(balanceText),
        color: _color,
        icon: _type.icon,
      ),
    );
  }
}

class _SourceListTile extends StatelessWidget {
  const _SourceListTile({
    required this.source,
    this.trailing,
  });

  final _MoneySource source;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProviderLogo(
          sourceName: source.name,
          fallbackIcon: source.icon,
          fallbackColor: source.color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                source.type.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              source.balance == null
                  ? 'Balance not set'
                  : _money(source.balance!),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: source.balance == null
                        ? AppColors.mutedInk
                        : AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (source.balance == null)
              Text(
                'Set Manually',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
          ],
        ),
        if (trailing != null) ...[
          const SizedBox(width: 4),
          trailing!,
        ],
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedInk,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _BalanceEditorDialog extends StatefulWidget {
  const _BalanceEditorDialog({
    required this.title,
    required this.confirmLabel,
    this.initialBalance,
  });

  final String title;
  final String confirmLabel;
  final double? initialBalance;

  @override
  State<_BalanceEditorDialog> createState() => _BalanceEditorDialogState();
}

class _BalanceEditorDialogState extends State<_BalanceEditorDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialBalance?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Balance',
          prefixText: '৳ ',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value < 0) {
      setState(() => _error = 'Enter a valid balance.');
      return;
    }
    Navigator.of(context).pop(value);
  }
}

class _SmsPermissionDialog extends StatelessWidget {
  const _SmsPermissionDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.mark_chat_unread_outlined,
        color: AppColors.primary,
      ),
      title: const Text('Enable smart SMS detection?'),
      content: const Text(
        'LaalKhata reads financial SMS locally to find opening balances and suggest new transactions.\n\nRaw messages are never uploaded.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not Now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _ShortfallDialog extends StatefulWidget {
  const _ShortfallDialog({
    required this.source,
    required this.deficit,
    required this.eligibleSources,
  });

  final _MoneySource source;
  final double deficit;
  final List<_MoneySource> eligibleSources;

  @override
  State<_ShortfallDialog> createState() => _ShortfallDialogState();
}

class _ShortfallDialogState extends State<_ShortfallDialog> {
  _MoneySource? _coverSource;

  @override
  void initState() {
    super.initState();
    if (widget.eligibleSources.isNotEmpty) {
      _coverSource = widget.eligibleSources.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.account_balance_wallet_outlined),
      title: const Text('Balance would fall below zero'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.source.name} would be -${_money(widget.deficit)}. Was this amount covered from another source?',
          ),
          if (widget.eligibleSources.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<_MoneySource>(
              initialValue: _coverSource,
              decoration: const InputDecoration(
                labelText: 'Cover from',
                prefixIcon: Icon(Icons.swap_horiz_rounded),
              ),
              items: widget.eligibleSources
                  .map(
                    (source) => DropdownMenuItem(
                      value: source,
                      child: Text(
                        '${source.name} (${_money(source.balance ?? 0)})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _coverSource = value),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'No other source has enough balance. You can set this source to zero and keep the expense in history.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            _ShortfallResolution(deficit: widget.deficit),
          ),
          child: const Text('Set to Zero'),
        ),
        if (_coverSource != null)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              _ShortfallResolution(
                deficit: widget.deficit,
                coverSource: _coverSource,
              ),
            ),
            child: const Text('Cover Amount'),
          ),
      ],
    );
  }
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({required this.sources});

  final List<_MoneySource> sources;

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  late _MoneySource _from;
  late _MoneySource _to;
  final _amountController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _from = widget.sources.first;
    _to = widget.sources[1];
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer Between Sources'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<_MoneySource>(
            initialValue: _from,
            decoration: const InputDecoration(
              labelText: 'From',
              prefixIcon: Icon(Icons.call_made_rounded),
            ),
            items: widget.sources
                .where((source) => source != _to)
                .map(
                  (source) => DropdownMenuItem(
                    value: source,
                    child: Text(source.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _from = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<_MoneySource>(
            initialValue: _to,
            decoration: const InputDecoration(
              labelText: 'To',
              prefixIcon: Icon(Icons.call_received_rounded),
            ),
            items: widget.sources
                .where((source) => source != _from)
                .map(
                  (source) => DropdownMenuItem(
                    value: source,
                    child: Text(source.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _to = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '৳ ',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Transfer'),
        ),
      ],
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    Navigator.of(context).pop(
      _TransferRequest(from: _from, to: _to, amount: amount),
    );
  }
}

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo({
    required this.sourceName,
    required this.fallbackIcon,
    required this.fallbackColor,
  });

  final String sourceName;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final asset = _providerAsset(sourceName);
    if (asset == null) {
      return _IconBubble(icon: fallbackIcon, color: fallbackColor);
    }

    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(fallbackIcon, color: fallbackColor, size: 22);
        },
      ),
    );
  }

  String? _providerAsset(String name) {
    final normalized = name.toLowerCase().replaceAll(' ', '');
    if (normalized.contains('bkash')) return 'assets/providers/bkash.png';
    if (normalized.contains('nagad')) return 'assets/providers/nagad.png';
    if (normalized.contains('rocket')) return 'assets/providers/rocket.webp';
    if (normalized.contains('abbank') || normalized == 'ab') {
      return 'assets/providers/ab_bank.png';
    }
    return null;
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({required this.activities});

  final List<_ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final expense = activities
        .where(_isExpenseActivity)
        .fold(0.0, (sum, activity) => sum + activity.amount.abs());
    final income = activities
        .where(_isIncomeActivity)
        .fold(0.0, (sum, activity) => sum + activity.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: _MetricText(
                label: 'Monthly Expense',
                value: _money(expense),
              ),
            ),
            Container(width: 1, height: 48, color: AppColors.line),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricText(
                label: 'Income vs Expense',
                value: _money(income - expense),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInsightCard extends StatelessWidget {
  const _EmptyInsightCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const _IconBubble(
              icon: Icons.query_stats_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No summary yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your charts and breakdowns will appear after you add real transactions.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_BreakdownItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0.0, (sum, item) => sum + item.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 16),
            for (final item in items) ...[
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    total == 0
                        ? '0%'
                        : '${((item.value / total) * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _money(item.value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : item.value / total,
                  minHeight: 8,
                  color: item.color,
                  backgroundColor: AppColors.line,
                ),
              ),
              if (item != items.last) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterPillRow extends StatelessWidget {
  const _FilterPillRow({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          Chip(
            label: Text(items[i]),
            backgroundColor: i == 0 ? AppColors.primary : AppColors.card,
            labelStyle: TextStyle(
              color: i == 0 ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: i == 0 ? AppColors.primary : AppColors.line,
            ),
          ),
      ],
    );
  }
}

class _EntryTypeSelector extends StatelessWidget {
  const _EntryTypeSelector({
    required this.selected,
    required this.onSelected,
  });

  final _EntryType selected;
  final ValueChanged<_EntryType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in _EntryType.values)
          ChoiceChip(
            selected: selected == value,
            label: Text(value.label),
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.onTap,
  });

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.primary;

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: _IconBubble(icon: icon, color: color),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 72),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}

enum _SourceType {
  cash('Cash', Icons.payments_outlined),
  mobileBanking('Mobile Banking', Icons.account_balance_wallet_outlined),
  bank('Bank', Icons.account_balance_outlined),
  card('Card', Icons.credit_card_outlined),
  crypto('Crypto', Icons.currency_bitcoin_outlined),
  savings('Savings', Icons.savings_outlined),
  investment('Investment', Icons.trending_up_rounded),
  other('Other', Icons.wallet_outlined);

  const _SourceType(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _EntryType {
  expense('Expense'),
  income('Income'),
  transfer('Transfer'),
  lent('Lent'),
  borrowed('Borrowed'),
  project('Project/List Item'),
  balanceAdjustment('Balance Adjustment');

  const _EntryType(this.label);

  final String label;
}

class _ManualEntry {
  const _ManualEntry({
    required this.type,
    required this.reason,
    required this.sourceName,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    this.destinationSourceName,
  });

  final _EntryType type;
  final String reason;
  final String sourceName;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String? destinationSourceName;
}

class _ShortfallResolution {
  const _ShortfallResolution({
    required this.deficit,
    this.coverSource,
  });

  final double deficit;
  final _MoneySource? coverSource;
}

class _TransferRequest {
  const _TransferRequest({
    required this.from,
    required this.to,
    required this.amount,
  });

  final _MoneySource from;
  final _MoneySource to;
  final double amount;
}

class _MoneySource {
  _MoneySource({
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    required this.icon,
  });

  final String name;
  final _SourceType type;
  double? balance;
  final Color color;
  final IconData icon;
  bool archived = false;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'balance': balance,
      'color': color.toARGB32(),
      'icon': icon.codePoint,
      'archived': archived,
    };
  }

  static _MoneySource? fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.trim().isEmpty) return null;

    final type = _SourceType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => _SourceType.other,
    );
    final source = _MoneySource(
      name: name,
      type: type,
      balance: (json['balance'] as num?)?.toDouble(),
      color: Color(
          (json['color'] as num?)?.toInt() ?? AppColors.primary.toARGB32()),
      icon: type.icon,
    );
    source.archived = json['archived'] == true;
    return source;
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.name,
    required this.source,
    required this.amount,
    required this.time,
    required this.icon,
    required this.occurredAt,
    required this.category,
    required this.type,
  });

  final String name;
  final String source;
  final double amount;
  final String time;
  final IconData icon;
  final DateTime occurredAt;
  final String category;
  final String type;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'source': source,
      'amount': amount,
      'time': time,
      'icon': icon.codePoint,
      'occurredAt': occurredAt.toIso8601String(),
      'category': category,
      'type': type,
    };
  }

  static _ActivityItem? fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final source = json['source'] as String?;
    final amount = (json['amount'] as num?)?.toDouble();
    final occurredAt = DateTime.tryParse('${json['occurredAt']}');
    if (name == null ||
        source == null ||
        amount == null ||
        occurredAt == null) {
      return null;
    }

    return _ActivityItem(
      name: name,
      source: source,
      amount: amount,
      time: json['time'] as String? ?? '',
      icon: Icons.receipt_long_outlined,
      occurredAt: occurredAt,
      category: json['category'] as String? ?? 'Others',
      type: json['type'] as String? ?? 'expense',
    );
  }
}

class _BreakdownItem {
  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

bool _isExpenseActivity(_ActivityItem activity) {
  return const {
    'expense',
    'lent',
    'project',
    'debit',
  }.contains(activity.type);
}

bool _isIncomeActivity(_ActivityItem activity) {
  return const {
    'income',
    'borrowed',
    'credit',
  }.contains(activity.type);
}

String _money(double value) {
  final isNegative = value < 0;
  final rounded = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final reverseIndex = rounded.length - i;
    buffer.write(rounded[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write(',');
  }
  return '${isNegative ? '-' : ''}৳${buffer.toString()}';
}
