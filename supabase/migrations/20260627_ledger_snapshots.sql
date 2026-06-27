create table if not exists public.ledger_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.ledger_snapshots enable row level security;

grant select, insert, update on public.ledger_snapshots to authenticated;

drop policy if exists "Ledger snapshots are readable by owner"
  on public.ledger_snapshots;
create policy "Ledger snapshots are readable by owner"
  on public.ledger_snapshots
  for select
  using (auth.uid() = user_id);

drop policy if exists "Ledger snapshots are insertable by owner"
  on public.ledger_snapshots;
create policy "Ledger snapshots are insertable by owner"
  on public.ledger_snapshots
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Ledger snapshots are updatable by owner"
  on public.ledger_snapshots;
create policy "Ledger snapshots are updatable by owner"
  on public.ledger_snapshots
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
