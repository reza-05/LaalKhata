# LaalKhata Production Architecture

## Distribution Decision

LaalKhata is currently distributed as an IUT-internal Android APK.
Automatic financial SMS detection remains enabled. Raw SMS, sender values, and
ignored suggestions stay on the device.

## Behavior-Preserving Migration

The production migration uses a strangler approach:

1. Keep the existing secure JSON snapshot and `ledger_snapshots` cloud row.
2. Parse that same snapshot into typed domain records.
3. Mirror it into normalized Drift tables inside one SQLite transaction.
4. Keep the legacy snapshot as a fallback until local and cloud parity is
   verified.
5. Introduce normalized Supabase tables behind owner-only RLS.
6. Add outbox-based sync before switching production reads away from the
   compatibility snapshot.

This prevents an architecture refactor from changing visible app behavior.

## Current Data Ownership

- Supabase Auth owns identity and sessions.
- Secure Storage temporarily keeps the compatibility ledger snapshot.
- Drift owns the new normalized local ledger mirror.
- Supabase `ledger_snapshots` remains the cross-device compatibility copy.
- SMS suggestions remain local and user-specific.
- Raw SMS is never uploaded.

## Local Tables

- `local_ledger_states`
- `local_money_sources`
- `local_ledger_activities`
- `local_sync_outbox`

Every local ledger replacement is atomic. An interrupted save cannot leave
sources and activity history at different versions.

## Cloud Foundation

- `ledger_states`
- `money_sources`
- `ledger_activities`
- `ledger_snapshots` (temporary compatibility fallback)

All user-owned cloud tables use Row Level Security with `auth.uid() = user_id`.

## Non-Negotiable Behavior Contracts

- Automatic SMS scanning remains enabled for the internal APK.
- SMS never changes financial data without user confirmation.
- Opening-balance cutoff behavior remains unchanged.
- Source balances never become negative.
- Transfers do not count as income or expense.
- Local PIN and biometric behavior remains unchanged.
- Existing screens, labels, navigation, and visual behavior remain unchanged
  during the architecture migration.
