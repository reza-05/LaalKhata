create or replace function public.sync_ledger_document(p_document jsonb)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  owner_id uuid := auth.uid();
begin
  if owner_id is null then
    raise exception 'Authentication required';
  end if;

  insert into public.ledger_states (
    user_id,
    sms_transaction_cutoff_at,
    snapshot_updated_at
  )
  values (
    owner_id,
    nullif(p_document ->> 'smsTransactionCutoffAt', '')::timestamptz,
    coalesce(
      nullif(p_document ->> 'updatedAt', '')::timestamptz,
      now()
    )
  )
  on conflict (user_id) do update
  set
    sms_transaction_cutoff_at =
      excluded.sms_transaction_cutoff_at,
    snapshot_updated_at = excluded.snapshot_updated_at,
    revision = public.ledger_states.revision + 1;

  delete from public.money_sources
  where user_id = owner_id;

  insert into public.money_sources (
    user_id,
    source_key,
    name,
    source_type,
    balance,
    color_value,
    icon_code_point,
    archived,
    sort_position
  )
  select
    owner_id,
    source_item ->> 'sourceKey',
    source_item ->> 'name',
    source_item ->> 'type',
    (source_item ->> 'balance')::numeric,
    coalesce((source_item ->> 'color')::bigint, 0),
    coalesce((source_item ->> 'icon')::integer, 0),
    coalesce((source_item ->> 'archived')::boolean, false),
    coalesce((source_item ->> 'sortPosition')::integer, 0)
  from jsonb_array_elements(
    coalesce(p_document -> 'sources', '[]'::jsonb)
  ) as source_item;

  delete from public.ledger_activities
  where user_id = owner_id;

  insert into public.ledger_activities (
    user_id,
    activity_key,
    name,
    source,
    amount,
    display_time,
    icon_code_point,
    occurred_at,
    category,
    activity_type,
    sort_position
  )
  select
    owner_id,
    activity_item ->> 'activityKey',
    activity_item ->> 'name',
    activity_item ->> 'source',
    (activity_item ->> 'amount')::numeric,
    coalesce(activity_item ->> 'time', ''),
    coalesce((activity_item ->> 'icon')::integer, 0),
    (activity_item ->> 'occurredAt')::timestamptz,
    coalesce(activity_item ->> 'category', 'Others'),
    activity_item ->> 'type',
    coalesce((activity_item ->> 'sortPosition')::integer, 0)
  from jsonb_array_elements(
    coalesce(p_document -> 'activities', '[]'::jsonb)
  ) as activity_item;
end;
$$;

revoke all on function public.sync_ledger_document(jsonb) from public;
grant execute on function public.sync_ledger_document(jsonb)
  to authenticated;
