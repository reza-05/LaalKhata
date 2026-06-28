-- Normalized ledger foundation for the offline-first migration.
-- ledger_snapshots remains in place as a compatibility fallback.

create table if not exists public.ledger_states (
  user_id uuid primary key references auth.users(id) on delete cascade,
  sms_transaction_cutoff_at timestamptz,
  snapshot_updated_at timestamptz not null default now(),
  revision bigint not null default 1 check (revision > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.money_sources (
  user_id uuid not null references auth.users(id) on delete cascade,
  source_key text not null,
  name text not null,
  source_type text not null,
  balance numeric,
  color_value bigint not null default 0,
  icon_code_point integer not null default 0,
  archived boolean not null default false,
  sort_position integer not null default 0 check (sort_position >= 0),
  revision bigint not null default 1 check (revision > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, source_key),
  constraint money_sources_name_not_blank check (length(trim(name)) > 0),
  constraint money_sources_non_negative_balance
    check (balance is null or balance >= 0)
);

create table if not exists public.ledger_activities (
  user_id uuid not null references auth.users(id) on delete cascade,
  activity_key text not null,
  name text not null,
  source text not null,
  amount numeric not null,
  display_time text not null default '',
  icon_code_point integer not null default 0,
  occurred_at timestamptz not null,
  category text not null default 'Others',
  activity_type text not null,
  sort_position integer not null default 0 check (sort_position >= 0),
  revision bigint not null default 1 check (revision > 0),
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, activity_key),
  constraint ledger_activities_name_not_blank check (length(trim(name)) > 0),
  constraint ledger_activities_source_not_blank
    check (length(trim(source)) > 0)
);

create index if not exists ledger_activities_user_occurred_at_idx
  on public.ledger_activities (user_id, occurred_at desc);

create index if not exists ledger_activities_user_type_idx
  on public.ledger_activities (user_id, activity_type);

alter table public.ledger_states enable row level security;
alter table public.money_sources enable row level security;
alter table public.ledger_activities enable row level security;

grant select, insert, update, delete on public.ledger_states to authenticated;
grant select, insert, update, delete on public.money_sources to authenticated;
grant select, insert, update, delete on public.ledger_activities
  to authenticated;

drop policy if exists "Ledger states are readable by owner"
  on public.ledger_states;
create policy "Ledger states are readable by owner"
  on public.ledger_states for select
  using (auth.uid() = user_id);

drop policy if exists "Ledger states are insertable by owner"
  on public.ledger_states;
create policy "Ledger states are insertable by owner"
  on public.ledger_states for insert
  with check (auth.uid() = user_id);

drop policy if exists "Ledger states are updatable by owner"
  on public.ledger_states;
create policy "Ledger states are updatable by owner"
  on public.ledger_states for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Ledger states are deletable by owner"
  on public.ledger_states;
create policy "Ledger states are deletable by owner"
  on public.ledger_states for delete
  using (auth.uid() = user_id);

drop policy if exists "Money sources are readable by owner"
  on public.money_sources;
create policy "Money sources are readable by owner"
  on public.money_sources for select
  using (auth.uid() = user_id);

drop policy if exists "Money sources are insertable by owner"
  on public.money_sources;
create policy "Money sources are insertable by owner"
  on public.money_sources for insert
  with check (auth.uid() = user_id);

drop policy if exists "Money sources are updatable by owner"
  on public.money_sources;
create policy "Money sources are updatable by owner"
  on public.money_sources for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Money sources are deletable by owner"
  on public.money_sources;
create policy "Money sources are deletable by owner"
  on public.money_sources for delete
  using (auth.uid() = user_id);

drop policy if exists "Ledger activities are readable by owner"
  on public.ledger_activities;
create policy "Ledger activities are readable by owner"
  on public.ledger_activities for select
  using (auth.uid() = user_id);

drop policy if exists "Ledger activities are insertable by owner"
  on public.ledger_activities;
create policy "Ledger activities are insertable by owner"
  on public.ledger_activities for insert
  with check (auth.uid() = user_id);

drop policy if exists "Ledger activities are updatable by owner"
  on public.ledger_activities;
create policy "Ledger activities are updatable by owner"
  on public.ledger_activities for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Ledger activities are deletable by owner"
  on public.ledger_activities;
create policy "Ledger activities are deletable by owner"
  on public.ledger_activities for delete
  using (auth.uid() = user_id);

drop trigger if exists ledger_states_set_updated_at
  on public.ledger_states;
create trigger ledger_states_set_updated_at
  before update on public.ledger_states
  for each row execute function public.set_updated_at();

drop trigger if exists money_sources_set_updated_at
  on public.money_sources;
create trigger money_sources_set_updated_at
  before update on public.money_sources
  for each row execute function public.set_updated_at();

drop trigger if exists ledger_activities_set_updated_at
  on public.ledger_activities;
create trigger ledger_activities_set_updated_at
  before update on public.ledger_activities
  for each row execute function public.set_updated_at();
