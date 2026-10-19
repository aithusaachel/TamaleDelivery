-- ============================================================================
-- Migration: 20261019000001_initial_schema.sql
-- Description: Tamale Delivery Service v1 Core Database Schema (Idempotent)
-- Reference: Master Build Document v2.2 (Parts A, B, and C)
-- ============================================================================

-- 1. Extensions
create extension if not exists postgis;
create extension if not exists pgcrypto;

-- 2. Enumerated Types (Protected against duplicate definition)
do $$ begin
  create type user_role as enum ('customer', 'rider', 'dispatcher', 'admin');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type vehicle_type as enum ('motorbike', 'moto_king');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type verification_status as enum ('incomplete', 'pending', 'approved', 'rejected', 'suspended');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type delivery_status as enum (
    'searching',
    'unassigned',
    'accepted',
    'arrived_pickup',
    'picked_up',
    'arrived_dropoff',
    'delivered',
    'cancelled'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type offer_status as enum ('offered', 'accepted', 'declined', 'expired', 'withdrawn');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type wallet_tx_type as enum ('topup', 'commission', 'adjustment', 'refund');
exception when duplicate_object then null;
end $$;

-- 3. Typed Global Settings (Single row pattern)
create table if not exists public.settings (
  id boolean primary key default true check (id),
  commission_rate numeric(5,4) not null default 0.15 check (commission_rate between 0 and 0.5),
  credit_limit numeric(10,2) not null default 20 check (credit_limit >= 0),
  offer_timeout_seconds int not null default 30,
  search_radius_m int not null default 5000,
  location_max_age_seconds int not null default 120,
  max_active_deliveries_per_customer int not null default 3,
  max_price_override numeric(10,2) not null default 100,
  max_dispatcher_credit numeric(10,2) not null default 100,
  min_app_version text not null default '1.0.0',
  maintenance boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table public.settings enable row level security;
insert into public.settings (id) values (true) on conflict (id) do nothing;

-- 4. People: Profiles, Riders, Guest Contacts, Live Location
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'customer',
  full_name text,
  phone text unique,
  push_token text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

create table if not exists public.riders (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  vehicle vehicle_type,
  plate_number text,
  vehicle_photo_path text,
  ghana_card_front_path text,
  ghana_card_back_path text,
  selfie_path text,
  licence_path text,
  momo_number text,
  momo_network text,
  verification verification_status not null default 'incomplete',
  rejection_reason text,
  is_online boolean not null default false,
  wallet_balance numeric(12,2) not null default 0,
  rating_avg numeric(3,2) not null default 0,
  rating_count int not null default 0,
  completed_trips int not null default 0,
  cancelled_trips int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.riders enable row level security;

-- Guest contacts for telephone/WhatsApp caller orders
create table if not exists public.guest_contacts (
  id uuid primary key default gen_random_uuid(),
  full_name text,
  phone text not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.guest_contacts enable row level security;
create index if not exists idx_guest_contacts_phone on public.guest_contacts (phone);

-- Real-time rider location tracking (GiST spatial indexed)
create table if not exists public.rider_live_location (
  rider_id uuid primary key references public.riders(profile_id) on delete cascade,
  location geography(point, 4326) not null,
  accuracy_m real,
  heading real,
  updated_at timestamptz not null default now()
);
alter table public.rider_live_location enable row level security;
create index if not exists idx_rider_live_location_gis on public.rider_live_location using gist (location);

-- 5. Quotes, Deliveries, Handover Codes, and Offers
create table if not exists public.delivery_quotes (
  id uuid primary key default gen_random_uuid(),
  requested_by uuid not null references public.profiles(id),
  vehicle vehicle_type not null,
  pickup geography(point, 4326) not null,
  dropoff geography(point, 4326) not null,
  distance_km numeric(6,2) not null,
  fare numeric(10,2) not null check (fare >= 0),
  commission_rate numeric(5,4) not null,
  route_source text not null,                  -- 'google' or 'staff_override'
  override_by uuid references public.profiles(id),
  override_reason text,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  check (override_by is null or override_reason is not null)
);
alter table public.delivery_quotes enable row level security;

create table if not exists public.deliveries (
  id uuid primary key,                         -- Client-generated UUID (idempotency key)
  quote_id uuid not null references public.delivery_quotes(id),
  customer_id uuid references public.profiles(id),
  guest_contact_id uuid references public.guest_contacts(id),
  created_by uuid not null references public.profiles(id),
  rider_id uuid references public.riders(profile_id),
  status delivery_status not null default 'searching',
  vehicle vehicle_type not null,
  pickup geography(point, 4326) not null,
  pickup_text text,
  pickup_note text,
  dropoff geography(point, 4326) not null,
  dropoff_text text,
  dropoff_note text,
  receiver_name text not null,
  receiver_phone text not null,
  package_size text not null default 'small' check (package_size in ('small', 'medium', 'large')),
  package_description text,
  package_photo_path text,
  distance_km numeric(6,2) not null,
  fare numeric(10,2) not null check (fare >= 0),
  commission_rate numeric(5,4) not null,
  commission_amount numeric(10,2),
  rider_earning numeric(10,2),
  payer text not null default 'sender' check (payer in ('sender', 'receiver')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  picked_up_at timestamptz,
  delivered_at timestamptz,
  cancelled_at timestamptz,
  cancelled_by uuid references public.profiles(id),
  cancel_reason text,
  -- Integrity check: exactly one customer owner (app customer OR guest contact)
  check ((customer_id is not null)::int + (guest_contact_id is not null)::int = 1)
);
alter table public.deliveries enable row level security;

create index if not exists idx_deliveries_status on public.deliveries (status, created_at desc);
create index if not exists idx_deliveries_customer on public.deliveries (customer_id, created_at desc);
create index if not exists idx_deliveries_rider on public.deliveries (rider_id, created_at desc);

-- Critical concurrency invariant: only one active in-progress job per rider
create unique index if not exists one_active_job_per_rider on public.deliveries (rider_id)
  where status in ('accepted', 'arrived_pickup', 'picked_up', 'arrived_dropoff');

-- 4-Digit Handover code table (Strictly hidden from riders & app clients)
create table if not exists public.delivery_codes (
  delivery_id uuid primary key references public.deliveries(id) on delete cascade,
  code char(4) not null,
  failed_attempts int not null default 0,
  locked_until timestamptz
);
alter table public.delivery_codes enable row level security;

-- Delivery dispatch offers
create table if not exists public.delivery_offers (
  id bigint generated always as identity primary key,
  delivery_id uuid not null references public.deliveries(id) on delete cascade,
  rider_id uuid not null references public.riders(profile_id),
  status offer_status not null default 'offered',
  attempt int not null,
  offered_at timestamptz not null default now(),
  expires_at timestamptz not null,
  responded_at timestamptz,
  unique (delivery_id, rider_id),              -- Do not offer same rider twice
  unique (delivery_id, attempt)
);
alter table public.delivery_offers enable row level security;

-- Invariant: at most one active offer per delivery
create unique index if not exists one_live_offer_per_delivery on public.delivery_offers (delivery_id)
  where status = 'offered';

-- 6. Financial Ledger, Top-ups, Events, and Auditing
create table if not exists public.wallet_transactions (
  id bigint generated always as identity primary key,
  rider_id uuid not null references public.riders(profile_id),
  type wallet_tx_type not null,
  amount numeric(12,2) not null check (amount <> 0),   -- Signed amount: commission is negative
  balance_after numeric(12,2) not null,
  delivery_id uuid references public.deliveries(id),
  idempotency_key text not null unique,        -- e.g. 'commission:' || delivery_id
  reference text unique,                       -- MoMo external reference for topups
  created_by uuid references public.profiles(id),
  reason text,
  created_at timestamptz not null default now()
);
alter table public.wallet_transactions enable row level security;
create index if not exists idx_wallet_transactions_rider on public.wallet_transactions (rider_id, created_at desc);

create table if not exists public.topup_requests (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references public.riders(profile_id),
  amount numeric(10,2) not null check (amount > 0),
  momo_reference text not null unique,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'rejected')),
  submitted_at timestamptz not null default now(),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  review_reason text
);
alter table public.topup_requests enable row level security;

create table if not exists public.delivery_events (
  id bigint generated always as identity primary key,
  delivery_id uuid not null references public.deliveries(id) on delete cascade,
  event_type text not null,
  actor_id uuid,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);
alter table public.delivery_events enable row level security;

create table if not exists public.audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid not null,
  action text not null,
  target text,
  reason text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);
alter table public.audit_log enable row level security;

-- 7. Role Helper Functions
create or replace function public.is_staff() returns boolean
language sql stable security definer
set search_path = public, pg_temp as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and is_active and role in ('dispatcher', 'admin')
  );
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer
set search_path = public, pg_temp as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and is_active and role = 'admin'
  );
$$;

-- 8. Row Level Security Policies & Privileges
drop policy if exists settings_read on public.settings;
create policy settings_read on public.settings for select to authenticated using (true);

revoke insert, update, delete on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, push_token) on public.profiles to authenticated;
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select using (id = auth.uid() or public.is_staff());
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

revoke insert, update, delete on public.riders from anon, authenticated;
grant select on public.riders to authenticated;
grant update (
  vehicle, plate_number, vehicle_photo_path, ghana_card_front_path,
  ghana_card_back_path, selfie_path, licence_path, momo_number, momo_network
) on public.riders to authenticated;
drop policy if exists riders_select on public.riders;
create policy riders_select on public.riders for select using (profile_id = auth.uid() or public.is_staff());
drop policy if exists riders_update_own on public.riders;
create policy riders_update_own on public.riders for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

drop policy if exists guest_contacts_staff_only on public.guest_contacts;
create policy guest_contacts_staff_only on public.guest_contacts for all using (public.is_staff());

drop policy if exists rider_live_location_select on public.rider_live_location;
create policy rider_live_location_select on public.rider_live_location for select to authenticated using (true);
drop policy if exists rider_live_location_upsert on public.rider_live_location;
create policy rider_live_location_upsert on public.rider_live_location for all
  using (rider_id = auth.uid()) with check (rider_id = auth.uid());

revoke insert, update, delete on public.deliveries from anon, authenticated;
grant select on public.deliveries to authenticated;
drop policy if exists deliveries_select on public.deliveries;
create policy deliveries_select on public.deliveries for select
  using (customer_id = auth.uid() or rider_id = auth.uid() or public.is_staff());

revoke insert, update, delete on public.wallet_transactions from anon, authenticated;
grant select on public.wallet_transactions to authenticated;
drop policy if exists wallet_select on public.wallet_transactions;
create policy wallet_select on public.wallet_transactions for select
  using (rider_id = auth.uid() or public.is_staff());

revoke insert, update, delete on public.delivery_events from anon, authenticated;
grant select on public.delivery_events to authenticated;
drop policy if exists events_select on public.delivery_events;
create policy events_select on public.delivery_events for select using (
  public.is_staff() or exists (
    select 1 from public.deliveries d
    where d.id = delivery_id and (d.customer_id = auth.uid() or d.rider_id = auth.uid())
  )
);

grant select, insert on public.topup_requests to authenticated;
drop policy if exists topup_requests_select on public.topup_requests;
create policy topup_requests_select on public.topup_requests for select
  using (rider_id = auth.uid() or public.is_staff());
drop policy if exists topup_requests_insert on public.topup_requests;
create policy topup_requests_insert on public.topup_requests for insert
  with check (rider_id = auth.uid());

-- Delivery quotes policy
revoke insert, update, delete on public.delivery_quotes from anon, authenticated;
grant select on public.delivery_quotes to authenticated;
drop policy if exists delivery_quotes_select on public.delivery_quotes;
create policy delivery_quotes_select on public.delivery_quotes for select
  using (requested_by = auth.uid() or public.is_staff());

-- Delivery offers policy
revoke insert, update, delete on public.delivery_offers from anon, authenticated;

-- Delivery codes & Audit log: revoked from client roles completely
revoke all on public.delivery_codes from anon, authenticated;
revoke all on public.audit_log from anon, authenticated;

-- 9. Secure Views for App Roles
create or replace view public.rider_offers as
select
  o.id as offer_id,
  o.delivery_id,
  o.expires_at,
  d.vehicle,
  d.package_size,
  d.distance_km,
  round(d.fare - (d.fare * d.commission_rate), 2) as rider_earning,
  st_distance(l.location, d.pickup) as pickup_distance_m
from public.delivery_offers o
join public.deliveries d on d.id = o.delivery_id
left join public.rider_live_location l on l.rider_id = o.rider_id
where o.rider_id = auth.uid()
  and o.status = 'offered'
  and o.expires_at > now();

grant select on public.rider_offers to authenticated;

-- 10. Core Transactional Functions (High Risk Operations)

-- A. Accept Offer (Atomic concurrency control)
create or replace function public.accept_offer(p_offer bigint)
returns void
language plpgsql security definer
set search_path = public, pg_temp as $$
declare
  o public.delivery_offers;
  d public.deliveries;
  r public.riders;
  s public.settings;
begin
  select * into s from public.settings limit 1;
  select * into o from public.delivery_offers where id = p_offer for update;
  if not found or o.rider_id <> auth.uid() then
    raise exception 'job no longer available';
  end if;

  select * into d from public.deliveries where id = o.delivery_id for update;
  select * into r from public.riders where profile_id = auth.uid() for update;

  if o.status <> 'offered' or o.expires_at <= now()
     or d.status <> 'searching' or d.rider_id is not null
     or r.verification <> 'approved' or not r.is_online
     or (r.wallet_balance - round(d.fare * d.commission_rate, 2)) < -s.credit_limit then
    raise exception 'job no longer available';
  end if;

  update public.delivery_offers set status = 'accepted', responded_at = now() where id = o.id;
  update public.deliveries set rider_id = r.profile_id, status = 'accepted', accepted_at = now()
    where id = d.id;

  insert into public.delivery_events (delivery_id, event_type, actor_id)
    values (d.id, 'accepted', auth.uid());
end;
$$;

-- B. Complete Delivery (Atomic handover code validation and commission deduction)
create or replace function public.complete_delivery(p_delivery uuid, p_code text)
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp as $$
declare
  d public.deliveries;
  c public.delivery_codes;
  comm numeric(10,2);
  new_balance numeric(12,2);
begin
  select * into d from public.deliveries where id = p_delivery for update;
  if not found or d.rider_id is distinct from auth.uid() or d.status <> 'arrived_dropoff' then
    raise exception 'cannot complete this delivery';
  end if;

  select * into c from public.delivery_codes where delivery_id = d.id for update;
  if not found then
    raise exception 'no handover code found';
  end if;

  -- Brute-force lockout check
  if c.locked_until is not null and c.locked_until > now() then
    return jsonb_build_object('ok', false, 'error', 'locked');
  end if;

  -- Code mismatch: increment failed counter and return without raising exception
  if c.code <> p_code then
    update public.delivery_codes
      set failed_attempts = failed_attempts + 1,
          locked_until = case when failed_attempts + 1 >= 5 then now() + interval '15 minutes' else null end
      where delivery_id = d.id;
    return jsonb_build_object('ok', false, 'error', 'wrong_code');
  end if;

  -- Code verified: calculate commission and deduct from wallet ledger
  comm := round(d.fare * d.commission_rate, 2);

  update public.riders
    set wallet_balance = wallet_balance - comm,
        completed_trips = completed_trips + 1,
        updated_at = now()
    where profile_id = d.rider_id
    returning wallet_balance into new_balance;

  insert into public.wallet_transactions
    (rider_id, type, amount, balance_after, delivery_id, idempotency_key)
    values (d.rider_id, 'commission', -comm, new_balance, d.id, 'commission:' || d.id::text);

  update public.deliveries
    set status = 'delivered',
        delivered_at = now(),
        commission_amount = comm,
        rider_earning = d.fare - comm
    where id = d.id;

  insert into public.delivery_events (delivery_id, event_type, actor_id)
    values (d.id, 'delivered', auth.uid());

  return jsonb_build_object('ok', true, 'commission', comm, 'balance', new_balance);
end;
$$;

-- C. Staff Quote Price Override
create or replace function public.override_quote(p_quote uuid, p_fare numeric, p_reason text)
returns void
language plpgsql security definer
set search_path = public, pg_temp as $$
declare
  s public.settings;
begin
  if not public.is_staff() then
    raise exception 'not allowed';
  end if;

  select * into s from public.settings limit 1;

  if coalesce(length(trim(p_reason)), 0) < 5 then
    raise exception 'reason required';
  end if;

  if p_fare <= 0 or p_fare > s.max_price_override then
    raise exception 'fare outside the allowed range';
  end if;

  update public.delivery_quotes
    set fare = p_fare,
        route_source = 'staff_override',
        override_by = auth.uid(),
        override_reason = p_reason
    where id = p_quote and expires_at > now();

  if not found then
    raise exception 'quote not found or expired';
  end if;

  insert into public.audit_log (actor_id, action, target, reason, metadata)
    values (auth.uid(), 'price_override', p_quote::text, p_reason, jsonb_build_object('fare', p_fare));
end;
$$;

-- D. Customer Handover Code Retrieval
create or replace function public.get_delivery_code(p_delivery uuid)
returns text
language plpgsql security definer
set search_path = public, pg_temp as $$
declare
  v_code text;
begin
  -- Only owning customer or staff can view the code
  select c.code into v_code
  from public.delivery_codes c
  join public.deliveries d on d.id = c.delivery_id
  where c.delivery_id = p_delivery
    and (d.customer_id = auth.uid() or public.is_staff());

  if not found then
    raise exception 'access denied or code not found';
  end if;

  return v_code;
end;
$$;

-- 11. Profile Creation Trigger on Auth Sign-Up
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp as $$
begin
  insert into public.profiles (id, phone, full_name)
  values (
    new.id,
    new.phone,
    coalesce(new.raw_user_meta_data->>'full_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 12. Function Execution Grants
revoke execute on function public.accept_offer(bigint) from public, anon;
grant execute on function public.accept_offer(bigint) to authenticated;

revoke execute on function public.complete_delivery(uuid, text) from public, anon;
grant execute on function public.complete_delivery(uuid, text) to authenticated;

revoke execute on function public.override_quote(uuid, numeric, text) from public, anon;
grant execute on function public.override_quote(uuid, numeric, text) to authenticated;

revoke execute on function public.get_delivery_code(uuid) from public, anon;
grant execute on function public.get_delivery_code(uuid) to authenticated;
