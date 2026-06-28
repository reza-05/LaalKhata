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
