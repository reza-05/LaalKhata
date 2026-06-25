# LaalKhata Phase 1 Setup

## What is included

- Flutter app shell with LaalKhata theme.
- Supabase auth repository.
- Strict app-side `@iut-dhaka.edu` email validation.
- Supabase `profiles` table SQL with RLS and a new-user trigger.
- Placeholder signed-in screen for Phase 2 wallet setup.

## Supabase setup

1. Create a Supabase project.
2. Open SQL Editor.
3. Run `supabase/schema_phase1.sql`.
4. In Authentication settings, enable email signups.
5. In Authentication email templates/settings, keep email confirmation enabled for real users. For quick local testing you may temporarily disable confirm email, then enable it again.
6. Add your site/app redirect URLs later when deep links are added.

## Local Android test with Supabase

Get these from Supabase Project Settings -> API:

- Project URL
- anon public key

Run:

```bash
flutter run \
  --dart-define=SUPABASE_URL=your-project-url \
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
```

The app only accepts `@iut-dhaka.edu` emails. For quick testing, use a real IUT email or temporarily change the allowed domain in `lib/features/auth/domain/auth_validator.dart`.

## Run locally

Install Flutter, then run:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=your-project-url \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Without those `--dart-define` values, the UI still opens but sign-in is disabled with a setup notice.

## Phase 2 handoff

After auth is verified, build wallet initialization:

- `wallets`: Cash, bKash, Nagad, AB Bank.
- `transactions`: confirmed income/expense/transfer records.
- `pending_sms_logs`: Android SMS parse buffer that does not alter balance.
