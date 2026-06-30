String sourceIdentityKey(String name) {
  var compact = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  compact = compact.replaceFirst(RegExp(r'\d+$'), '');
  if (compact.isEmpty) return '';

  const knownSources = ['cash', 'bkash', 'nagad', 'rocket', 'abbank'];
  const knownSuffixes = {
    '',
    'account',
    'wallet',
    'personal',
    'business',
    'savings',
  };

  for (final source in knownSources) {
    if (!compact.startsWith(source)) continue;
    final suffix = compact.substring(source.length);
    if (knownSuffixes.contains(suffix)) return source;
  }
  return compact;
}

String normalizeSourceDisplayName(
  String name, {
  String? typeName,
}) {
  final trimmed = name.trim();
  final identity = sourceIdentityKey(trimmed);
  if (identity.isEmpty) return trimmed;

  if (typeName == 'cash' || identity == 'cash') {
    return 'Cash';
  }

  return switch (identity) {
    'bkash' => 'bKash',
    'nagad' => 'Nagad',
    'rocket' => 'Rocket',
    'abbank' => 'AB Bank',
    _ => _toTitleCase(trimmed),
  };
}

String _toTitleCase(String value) {
  return value
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
      )
      .join(' ');
}
