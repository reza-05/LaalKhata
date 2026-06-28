create or replace function public.get_ledger_document()
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select jsonb_build_object(
    'revision', state.revision,
    'updatedAt', state.snapshot_updated_at,
    'smsTransactionCutoffAt', state.sms_transaction_cutoff_at,
    'sources', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'name', source.name,
            'type', source.source_type,
            'balance', source.balance,
            'color', source.color_value,
            'icon', source.icon_code_point,
            'archived', source.archived
          )
          order by source.sort_position
        )
        from public.money_sources as source
        where source.user_id = state.user_id
      ),
      '[]'::jsonb
    ),
    'activities', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'name', activity.name,
            'source', activity.source,
            'amount', activity.amount,
            'time', activity.display_time,
            'icon', activity.icon_code_point,
            'occurredAt', activity.occurred_at,
            'category', activity.category,
            'type', activity.activity_type
          )
          order by activity.sort_position
        )
        from public.ledger_activities as activity
        where activity.user_id = state.user_id
          and activity.deleted_at is null
      ),
      '[]'::jsonb
    )
  )
  from public.ledger_states as state
  where state.user_id = auth.uid();
$$;

revoke all on function public.get_ledger_document() from public;
grant execute on function public.get_ledger_document() to authenticated;

create or replace function public.sync_ledger_document_v2(
  p_document jsonb,
  p_expected_revision bigint default null
)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  owner_id uuid := auth.uid();
  current_revision bigint;
  next_revision bigint;
begin
  if owner_id is null then
    raise exception 'Authentication required';
  end if;

  select state.revision
  into current_revision
  from public.ledger_states as state
  where state.user_id = owner_id
  for update;

  if p_expected_revision is not null
     and coalesce(current_revision, 0) <> p_expected_revision then
    return jsonb_build_object(
      'accepted', false,
      'revision', coalesce(current_revision, 0),
      'currentDocument', public.get_ledger_document()
    );
  end if;

  perform public.sync_ledger_document(p_document);

  select state.revision
  into next_revision
  from public.ledger_states as state
  where state.user_id = owner_id;

  return jsonb_build_object(
    'accepted', true,
    'revision', next_revision,
    'currentDocument', null
  );
end;
$$;

revoke all on function public.sync_ledger_document_v2(jsonb, bigint)
  from public;
grant execute on function public.sync_ledger_document_v2(jsonb, bigint)
  to authenticated;
