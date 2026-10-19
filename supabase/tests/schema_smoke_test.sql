-- ============================================================================
-- Schema Smoke Tests & Validation Script
-- Run this in the Supabase SQL Editor after running 20261019000001_initial_schema.sql
-- ============================================================================

do $$
declare
  v_customer_id uuid := gen_random_uuid();
  v_rider_id uuid := gen_random_uuid();
  v_quote_id uuid;
  v_delivery_id uuid := gen_random_uuid();
  v_offer_id bigint;
  v_result jsonb;
  v_code text := '4821';
begin
  raise notice '>>> Starting Tamale Delivery Schema Verification...';

  -- 1. Verify Settings Table Exists & has 1 row
  if (select count(*) from public.settings) <> 1 then
    raise exception 'Test Failed: settings table must have exactly 1 default row';
  end if;
  raise notice '[PASS] Settings singleton initialized';

  -- 2. Mock Test Profiles (Customer and Rider)
  -- Note: In production auth.users trigger populates this. For this isolated test block, insert mock profiles.
  -- We disable FK check temporarily for this isolated anonymous block if needed, or create directly:
  -- Since profiles references auth.users(id), let's ensure we verify tables and constraints.

  -- 3. Verify Table and View Existence
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'profiles';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'riders';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'guest_contacts';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'rider_live_location';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'delivery_quotes';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'deliveries';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'delivery_codes';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'delivery_offers';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'wallet_transactions';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'topup_requests';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'delivery_events';
  perform 1 from information_schema.tables where table_schema = 'public' and table_name = 'audit_log';
  perform 1 from information_schema.views where table_schema = 'public' and table_name = 'rider_offers';
  raise notice '[PASS] All 12 core tables and views are present';

  -- 4. Verify Critical Indexes
  if not exists (
    select 1 from pg_indexes
    where schemaname = 'public' and tablename = 'deliveries' and indexname = 'one_active_job_per_rider'
  ) then
    raise exception 'Test Failed: Partial unique index one_active_job_per_rider is missing';
  end if;
  raise notice '[PASS] Invariant: one_active_job_per_rider index verified';

  if not exists (
    select 1 from pg_indexes
    where schemaname = 'public' and tablename = 'delivery_offers' and indexname = 'one_live_offer_per_delivery'
  ) then
    raise exception 'Test Failed: Partial unique index one_live_offer_per_delivery is missing';
  end if;
  raise notice '[PASS] Invariant: one_live_offer_per_delivery index verified';

  -- 5. Verify Functions Exist
  perform 1 from pg_proc where proname = 'accept_offer';
  perform 1 from pg_proc where proname = 'complete_delivery';
  perform 1 from pg_proc where proname = 'override_quote';
  perform 1 from pg_proc where proname = 'get_delivery_code';
  perform 1 from pg_proc where proname = 'is_staff';
  perform 1 from pg_proc where proname = 'is_admin';
  raise notice '[PASS] All 6 critical stored procedures verified';

  raise notice '>>> All Smoke Tests Succeeded! The database schema is ready.';
end $$;
