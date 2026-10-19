# Tamale Delivery Service (Pilot Platform)

Local delivery platform engineered for Tamale, Ghana. Built for motorbikes & Moto King couriers with cash on delivery and a ledger-backed credit wallet.

## Monorepo Architecture

```text
DeliveryService/
├── apps/
│   ├── customer/        # Flutter customer mobile app (Uber/Bolt-style booking)
│   ├── rider/           # Flutter rider app (Offers, live status, wallet)
│   └── admin/           # Next.js staff dispatcher & operations dashboard
├── packages/
│   ├── ui/              # Shared Flutter UI tokens & components
│   └── core/            # Shared business models, pricing & contracts
├── supabase/
│   ├── migrations/      # Authoritative database migrations & PostGIS
│   └── tests/           # Automated database & security tests
└── docs/                # Architecture specifications & decisions
```

## Quick Start (Database Migration)

1. Open your project on [Supabase Dashboard](https://supabase.com/dashboard).
2. Go to the **SQL Editor**.
3. Copy and run [`supabase/migrations/20261019000001_initial_schema.sql`](file:///c:/Users/User/Desktop/DeliveryService/supabase/migrations/20261019000001_initial_schema.sql).
4. Verify all tables, views, and stored functions are created in the `public` schema.
