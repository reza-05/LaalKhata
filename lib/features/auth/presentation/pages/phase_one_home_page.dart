import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ledger_snapshot_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ledger/domain/ledger_document.dart';
import '../../../ledger/domain/source_identity.dart';
import '../../../sms/data/sms_suggestion_manager.dart';
import '../../../sms/domain/sms_transaction_models.dart';
import '../../../sms/domain/sms_duplicate_detector.dart';
import '../controllers/auth_controller.dart';

// Import refactored models and widgets
import '../../presentation/widgets/security_sheet.dart';
import '../../../ledger/presentation/models/ledger_presentation_models.dart';
import '../../../ledger/presentation/widgets/provider_logo.dart';
import '../../../ledger/presentation/widgets/ledger_dialogs.dart';
import '../../../ledger/presentation/widgets/ledger_layout_widgets.dart';
import '../../../ledger/presentation/widgets/home_tab.dart';
import '../../../ledger/presentation/widgets/summary_tab.dart';
import '../../../ledger/presentation/widgets/add_transaction_tab.dart';
import '../../../ledger/presentation/widgets/sources_tab.dart';
import '../../../sms/presentation/widgets/detected_messages_sheet.dart';

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

  final List<MoneySource> _sources = [
    MoneySource(
      name: 'Cash',
      type: SourceType.cash,
      balance: null,
      color: const Color(0xFF166534),
      icon: Icons.payments_outlined,
    ),
    MoneySource(
      name: 'bKash',
      type: SourceType.mobileBanking,
      balance: null,
      color: const Color(0xFFC2185B),
      icon: Icons.account_balance_wallet_outlined,
    ),
    MoneySource(
      name: 'AB Bank',
      type: SourceType.bank,
      balance: null,
      color: const Color(0xFF1D4ED8),
      icon: Icons.account_balance_outlined,
    ),
  ];

  final List<ActivityItem> _activities = [];

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
      HomeTab(
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
      SummaryTab(
        sources: _sources.where((source) => !source.archived).toList(),
        activities: _activities,
      ),
      AddTransactionTab(
        sources: _sources.where((source) => !source.archived).toList(),
        onSave: _saveManualEntry,
      ),
      SourcesTab(
        sources: _sources,
        onAddSource: _showAddSourceSheet,
        onSetBalance: _setSourceBalance,
        onTransfer: _showTransferDialog,
        onArchiveSource: (source) {
          setState(() {
            source.archived = true;
          });
          _persistLedger();
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
      var shouldPersistCleanup = false;
      if (result.document != null) {
        shouldPersistCleanup = _applyLedgerJson(result.document!.toJson());
      }

      if (_sources.any((source) => source.balance != null) &&
          _smsTransactionCutoffAt == null) {
        _smsTransactionCutoffAt = DateTime.now();
        shouldPersistCleanup = true;
      }
      if (shouldPersistCleanup) {
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
    _cloudSyncAvailable = await _ledgerRepository.save(
      user.id,
      LedgerDocument.fromJson(payload),
    );
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

  Future<bool> _saveManualEntry(ManualEntry entry) async {
    final source = _sourceForName(entry.sourceName);
    if (entry.type == EntryType.transfer) {
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

    if (entry.type == EntryType.balanceAdjustment) {
      final previous = source.balance;
      setState(() {
        source.balance = entry.amount;
        _activities.insert(
          0,
          ActivityItem(
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
        entry.type == EntryType.income || entry.type == EntryType.borrowed;
    ShortfallResolution? shortfall;
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
            ActivityItem(
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
            ActivityItem(
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
        ActivityItem(
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
    ShortfallResolution? shortfall;

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
          ActivityItem(
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
        ActivityItem(
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

  Future<ShortfallResolution?> _resolveShortfall({
    required MoneySource source,
    required double requestedAmount,
  }) async {
    final current = source.balance ?? 0;
    final deficit = requestedAmount - current;
    if (deficit <= 0) {
      return const ShortfallResolution(deficit: 0);
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

    return showDialog<ShortfallResolution>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShortfallDialog(
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
    final request = await showDialog<TransferRequest>(
      context: context,
      builder: (context) => TransferDialog(sources: active),
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
    required MoneySource from,
    required MoneySource to,
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
        ActivityItem(
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
        ActivityItem(
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
      builder: (context) => BalanceEditorDialog(
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

  MoneySource _sourceForName(String sourceName) {
    final existing = _sourceByName(sourceName);
    if (existing != null) return existing;

    final source = MoneySource(
      name: sourceName,
      type: SourceType.mobileBanking,
      balance: null,
      color: AppColors.primary,
      icon: Icons.account_balance_wallet_outlined,
    );
    _sources.add(source);
    return source;
  }

  MoneySource? _sourceByName(String sourceName) {
    final identity = sourceIdentityKey(sourceName);
    final existing = _sources.where(
      (source) => sourceIdentityKey(source.name) == identity,
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
    final source = await showModalBottomSheet<MoneySource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSourceSheet(
        existingSourceKeys: _sources
            .where((s) => !s.archived)
            .map((source) => sourceIdentityKey(source.name))
            .toSet(),
      ),
    );

    if (source == null || !mounted) return;

    final identity = sourceIdentityKey(source.name);
    var index = -1;
    for (var i = 0; i < _sources.length; i++) {
      if (sourceIdentityKey(_sources[i].name) == identity) {
        index = i;
        break;
      }
    }

    if (index != -1 && !_sources[index].archived) {
      _showProfessionalMessage(
        '${source.name} already exists in your Sources.',
      );
      return;
    }

    final isFirstInitializedBalance = source.balance != null &&
        _sources.every((item) => item.balance == null);
    setState(() {
      if (index != -1) {
        _sources[index] = source..archived = false;
      } else {
        _sources.add(source);
      }
      if (source.balance != null) {
        if (isFirstInitializedBalance && _smsTransactionCutoffAt == null) {
          _smsTransactionCutoffAt = DateTime.now();
        }
        _activities.insert(
          0,
          ActivityItem(
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

  Future<void> _setSourceBalance(MoneySource source) async {
    final balance = await showDialog<double>(
      context: context,
      builder: (context) => BalanceEditorDialog(
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

  bool _applyLedgerJson(Map<String, dynamic> json) {
    final sources = (json['sources'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map(MoneySource.fromJson)
        .whereType<MoneySource>()
        .toList();
    final activities = (json['activities'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map(ActivityItem.fromJson)
        .whereType<ActivityItem>()
        .toList();
    _smsTransactionCutoffAt =
        DateTime.tryParse('${json['smsTransactionCutoffAt']}');

    var removedDuplicates = false;
    if (sources != null && sources.isNotEmpty) {
      final uniqueSources = <MoneySource>[];
      final byIdentity = <String, MoneySource>{};
      for (final source in sources) {
        final identity = sourceIdentityKey(source.name);
        final existing = byIdentity[identity];
        if (existing == null) {
          byIdentity[identity] = source;
          uniqueSources.add(source);
          continue;
        }

        removedDuplicates = true;
        if (existing.balance == null && source.balance != null) {
          existing.balance = source.balance;
        }
        if (existing.archived && !source.archived) {
          existing.archived = false;
        }
      }
      _sources
        ..clear()
        ..addAll(uniqueSources);
    }
    if (activities != null) {
      _activities
        ..clear()
        ..addAll(activities);
    }
    return removedDuplicates;
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

  final List<MoneySource> sources;
  final List<ActivityItem> activities;
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
        const PageTitle(
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
                subtitle: 'Milestones, Bazar lists, hobbies, and notes',
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
      builder: (context) => DetectedMessagesSheet(
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
      builder: (context) => const SecuritySheet(),
    );
  }
}

class _TransactionHistorySheet extends StatelessWidget {
  const _TransactionHistorySheet({required this.activities});

  final List<ActivityItem> activities;

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
            const Row(
              children: [
                IconBubble(
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
                SizedBox(width: 12),
                Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const DetectedMessagesEmptyState()
            else
              RecentActivityCard(activities: activities),
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
          leading: IconBubble(icon: icon, color: color),
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
