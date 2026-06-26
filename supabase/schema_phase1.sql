create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  display_name text not null default 'IUT Student',
  role text not null default 'Student',
  department text not null default '',
  student_id text,
  batch text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_iut_email_only check (lower(email) like '%@iut-dhaka.edu'),
  constraint profiles_valid_role check (role in ('Student', 'Faculty', 'Staff')),
  constraint profiles_student_details check (
    role <> 'Student' or (student_id is not null and batch is not null)
  )
);

alter table public.profiles enable row level security;

create policy "Profiles are readable by owner"
  on public.profiles
  for select
  using (auth.uid() = id);

create policy "Profiles are insertable by owner"
  on public.profiles
  for insert
  with check (auth.uid() = id);

create policy "Profiles are updatable by owner"
  on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if lower(new.email) not like '%@iut-dhaka.edu' then
    raise exception 'Only @iut-dhaka.edu emails are allowed';
  end if;

  insert into public.profiles (
    id,
    email,
    display_name,
    role,
    department,
    student_id,
    batch,
    avatar_url
  )
  values (
    new.id,
    lower(new.email),
    coalesce(new.raw_user_meta_data ->> 'display_name', 'IUT Student'),
    coalesce(new.raw_user_meta_data ->> 'role', 'Student'),
    coalesce(new.raw_user_meta_data ->> 'department', ''),
    nullif(new.raw_user_meta_data ->> 'student_id', ''),
    nullif(new.raw_user_meta_data ->> 'batch', ''),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update
  set
    email = excluded.email,
    display_name = excluded.display_name,
    role = excluded.role,
    department = excluded.department,
    student_id = excluded.student_id,
    batch = excluded.batch,
    avatar_url = excluded.avatar_url;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

create table if not exists public.ledger_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.ledger_snapshots enable row level security;

create policy "Ledger snapshots are readable by owner"
  on public.ledger_snapshots
  for select
  using (auth.uid() = user_id);

create policy "Ledger snapshots are insertable by owner"
  on public.ledger_snapshots
  for insert
  with check (auth.uid() = user_id);

create policy "Ledger snapshots are updatable by owner"
  on public.ledger_snapshots
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
