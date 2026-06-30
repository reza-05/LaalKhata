import 'package:flutter/material.dart';
import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/features/ledger/presentation/models/ledger_presentation_models.dart';

class ProviderLogo extends StatelessWidget {
  const ProviderLogo({
    super.key,
    required this.sourceName,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.sourceType,
  });

  final String sourceName;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final SourceType? sourceType;

  _LogoStyle _logoStyle(String name, SourceType? type) {
    if (_isSpecificProvider(name)) {
      return const _LogoStyle(size: 42, padding: 7, borderRadius: 14);
    }

    if (type == SourceType.cash) {
      return const _LogoStyle(size: 48, padding: 7, borderRadius: 16);
    }

    if (type == SourceType.mobileBanking) {
      return const _LogoStyle(size: 46, padding: 5, borderRadius: 15);
    }

    return const _LogoStyle(size: 48, padding: 6, borderRadius: 16);
  }

  bool _isSpecificProvider(String name) {
    final normalized = name.toLowerCase().replaceAll(' ', '');
    return normalized.contains('nagad') ||
        normalized.contains('rocket') ||
        normalized.contains('abbank') ||
        normalized == 'ab';
  }

  @override
  Widget build(BuildContext context) {
    final asset = _assetForSource(sourceName, sourceType);
    if (asset == null) {
      return IconBubble(icon: fallbackIcon, color: fallbackColor);
    }

    final isSpecific = _isSpecificProvider(sourceName);
    final style = _logoStyle(sourceName, sourceType);

    return Container(
      width: style.size,
      height: style.size,
      padding: EdgeInsets.all(style.padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(fallbackIcon,
              color: fallbackColor, size: isSpecific ? 22 : 26);
        },
      ),
    );
  }

  String? _assetForSource(String name, SourceType? type) {
    final provider = _providerAsset(name);
    if (provider != null) return provider;

    if (type == null) return null;

    if (type == SourceType.mobileBanking) {
      return _mobileBankingAsset(name) ??
          'assets/source_types/mobile_banking.png';
    }

    return switch (type) {
      SourceType.cash => 'assets/source_types/cash.png',
      SourceType.bank => 'assets/source_types/bank.png',
      SourceType.card => 'assets/source_types/card.png',
      SourceType.crypto => 'assets/source_types/crypto.png',
      SourceType.savings => 'assets/source_types/savings.png',
      SourceType.investment => 'assets/source_types/investment.png',
      SourceType.mobileBanking => 'assets/source_types/mobile_banking.png',
      SourceType.other => null,
    };
  }

  String? _providerAsset(String name) {
    return _mobileBankingAsset(name) ?? _bankProviderAsset(name);
  }

  String? _mobileBankingAsset(String name) {
    final normalized = name.toLowerCase().replaceAll(' ', '');
    if (normalized.contains('bkash')) return 'assets/providers/bkash.png';
    if (normalized.contains('nagad')) return 'assets/providers/nagad.png';
    if (normalized.contains('rocket')) return 'assets/providers/rocket.webp';
    return null;
  }

  String? _bankProviderAsset(String name) {
    final normalized = name.toLowerCase().replaceAll(' ', '');
    if (normalized.contains('abbank') || normalized == 'ab') {
      return 'assets/providers/ab_bank.png';
    }
    return null;
  }
}

class _LogoStyle {
  const _LogoStyle({
    required this.size,
    required this.padding,
    required this.borderRadius,
  });

  final double size;
  final double padding;
  final double borderRadius;
}

class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}
