-- ============================================================================
-- Migration: 20261019000002_dispatcher_functions.sql
-- Description: Dispatcher Order Creation & Staff Delivery Controls
-- Reference: Master Build Document Section B1, B2, B7, B8
-- ============================================================================

-- Function: dispatcher_create_order
-- Atomically creates guest contact, quote, delivery, handover code, and event in one transaction
create or replace function public.dispatcher_create_order(
  p_caller_name text,
  p_caller_phone text,
  p_pickup_text text,
  p_dropoff_text text,
  p_vehicle vehicle_type,
  p_distance_km numeric,
  p_fare numeric,
  p_receiver_name text,
  p_receiver_phone text,
  p_payer text
)
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp as $$
declare
  v_guest_id uuid;
  v_quote_id uuid;
  v_delivery_id uuid := gen_random_uuid();
  v_code text;
  v_comm_rate numeric(5,4);
  v_settings public.settings;
  -- Default central Tamale coordinates
  v_pickup_geo geography := ST_SetSRID(ST_MakePoint(-0.8393, 9.4008), 4326);
  v_dropoff_geo geography := ST_SetSRID(ST_MakePoint(-0.8300, 9.4100), 4326);
begin
  -- 1. Authorization check
  if not public.is_staff() then
    raise exception 'Unauthorized: Only dispatchers and staff can create manual orders';
  end if;

  select * into v_settings from public.settings limit 1;
  v_comm_rate := coalesce(v_settings.commission_rate, 0.15);

  -- 2. Validate inputs
  if coalesce(length(trim(p_caller_phone)), 0) < 9 then
    raise exception 'Valid caller phone number is required';
  end if;
  if coalesce(length(trim(p_receiver_phone)), 0) < 9 then
    raise exception 'Valid receiver phone number is required';
  end if;
  if p_fare <= 0 then
    raise exception 'Fare must be greater than zero';
  end if;

  -- 3. Create or reuse Guest Contact
  insert into public.guest_contacts (full_name, phone, created_by)
  values (coalesce(trim(p_caller_name), 'Phone Caller'), trim(p_caller_phone), auth.uid())
  returning id into v_guest_id;

  -- 4. Create Immutable Quote
  insert into public.delivery_quotes (
    requested_by,
    vehicle,
    pickup,
    dropoff,
    distance_km,
    fare,
    commission_rate,
    route_source,
    override_by,
    override_reason,
    expires_at
  )
  values (
    auth.uid(),
    p_vehicle,
    v_pickup_geo,
    v_dropoff_geo,
    p_distance_km,
    p_fare,
    v_comm_rate,
    'staff_override',
    auth.uid(),
    'Dispatcher phone order booking',
    now() + interval '30 minutes'
  )
  returning id into v_quote_id;

  -- 5. Create Delivery row
  insert into public.deliveries (
    id,
    quote_id,
    guest_contact_id,
    created_by,
    status,
    vehicle,
    pickup,
    pickup_text,
    dropoff,
    dropoff_text,
    receiver_name,
    receiver_phone,
    distance_km,
    fare,
    commission_rate,
    payer
  )
  values (
    v_delivery_id,
    v_quote_id,
    v_guest_id,
    auth.uid(),
    'searching',
    p_vehicle,
    v_pickup_geo,
    p_pickup_text,
    v_dropoff_geo,
    p_dropoff_text,
    p_receiver_name,
    p_receiver_phone,
    p_distance_km,
    p_fare,
    v_comm_rate,
    p_payer
  );

  -- 6. Generate 4-digit Handover Code
  v_code := lpad((floor(random() * 9000 + 1000)::int)::text, 4, '0');
  insert into public.delivery_codes (delivery_id, code)
  values (v_delivery_id, v_code);

  -- 7. Audit and Event log
  insert into public.delivery_events (delivery_id, event_type, actor_id, metadata)
  values (
    v_delivery_id,
    'dispatcher_created',
    auth.uid(),
    jsonb_build_object(
      'caller_phone', p_caller_phone,
      'receiver_phone', p_receiver_phone,
      'fare', p_fare
    )
  );

  insert into public.audit_log (actor_id, action, target, reason, metadata)
  values (
    auth.uid(),
    'dispatcher_create_order',
    v_delivery_id::text,
    'Phone order booked by dispatcher',
    jsonb_build_object('fare', p_fare, 'vehicle', p_vehicle)
  );

  return jsonb_build_object(
    'ok', true,
    'delivery_id', v_delivery_id,
    'code', v_code,
    'fare', p_fare
  );
end;
$$;

-- Function: admin_assign_rider (Manual assignment)
create or replace function public.admin_assign_rider(
  p_delivery_id uuid,
  p_rider_id uuid,
  p_reason text
)
returns void
language plpgsql security definer
set search_path = public, pg_temp as $$
declare
  v_deliv public.deliveries;
  v_rider public.riders;
begin
  if not public.is_staff() then
    raise exception 'Unauthorized';
  end if;

  select * into v_deliv from public.deliveries where id = p_delivery_id for update;
  if not found or v_deliv.status not in ('searching', 'unassigned') then
    raise exception 'Delivery is not available for assignment';
  end if;

  select * into v_rider from public.riders where profile_id = p_rider_id for update;
  if not found or v_rider.verification <> 'approved' or not v_rider.is_online then
    raise exception 'Rider is not approved or not online';
  end if;

  -- Close any open offers
  update public.delivery_offers set status = 'withdrawn' where delivery_id = p_delivery_id and status = 'offered';

  -- Assign rider
  update public.deliveries
  set rider_id = p_rider_id, status = 'accepted', accepted_at = now()
  where id = p_delivery_id;

  insert into public.delivery_events (delivery_id, event_type, actor_id, metadata)
  values (p_delivery_id, 'staff_assigned', auth.uid(), jsonb_build_object('rider_id', p_rider_id, 'reason', p_reason));

  insert into public.audit_log (actor_id, action, target, reason, metadata)
  values (auth.uid(), 'admin_assign_rider', p_delivery_id::text, p_reason, jsonb_build_object('rider_id', p_rider_id));
end;
$$;

-- Function: admin_cancel_delivery
create or replace function public.admin_cancel_delivery(
  p_delivery_id uuid,
  p_reason text
)
returns void
language plpgsql security definer
set search_path = public, pg_temp as $$
begin
  if not public.is_staff() then
    raise exception 'Unauthorized';
  end if;

  if coalesce(length(trim(p_reason)), 0) < 3 then
    raise exception 'Cancellation reason required';
  end if;

  update public.deliveries
  set status = 'cancelled', cancelled_at = now(), cancelled_by = auth.uid(), cancel_reason = p_reason
  where id = p_delivery_id and status not in ('delivered', 'cancelled');

  if not found then
    raise exception 'Delivery cannot be cancelled in its current state';
  end if;

  -- Withdraw any active offers
  update public.delivery_offers set status = 'withdrawn' where delivery_id = p_delivery_id and status = 'offered';

  insert into public.delivery_events (delivery_id, event_type, actor_id, metadata)
  values (p_delivery_id, 'cancelled', auth.uid(), jsonb_build_object('reason', p_reason));

  insert into public.audit_log (actor_id, action, target, reason)
  values (auth.uid(), 'admin_cancel_delivery', p_delivery_id::text, p_reason);
end;
$$;

-- Permissions
revoke execute on function public.dispatcher_create_order from public, anon;
grant execute on function public.dispatcher_create_order to authenticated;

revoke execute on function public.admin_assign_rider from public, anon;
grant execute on function public.admin_assign_rider to authenticated;

revoke execute on function public.admin_cancel_delivery from public, anon;
grant execute on function public.admin_cancel_delivery to authenticated;
