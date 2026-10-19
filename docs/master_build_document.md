# Tamale Delivery App — Master Build Document
Revised edition v2.2 | 17 October 2026 | Prepared for Michael  
Status: Product specification and implementation plan — not yet production-ready code

## Executive Summary
Build a reliable local delivery service for Tamale, initially supported by the existing customer acquisition channel, five riders (including one Moto King), and a dispatcher/admin team. Customers can request a delivery from the app or through a dispatcher taking an order by phone or WhatsApp. The backend quotes the fare, dispatches to an eligible rider, tracks delivery progress, verifies handover using a four-digit code, and records the platform commission.

Core business model: customers pay cash on delivery. Riders collect the full fare and the platform's commission is deducted from a rider wallet. The wallet is a ledger-backed credit system with a configurable limit; it is not automatically a strict prepaid wallet. Staff confirm manual top-ups in v1.

Primary launch principle: prove that the business can quote, assign, complete, support, and reconcile real deliveries before polishing every screen or building v1.1 features.

---

## Architecture Overview
- **Customer Mobile App**: Flutter (Android/iOS)
- **Rider Mobile App**: Flutter (Android/iOS)
- **Staff Operations & Admin**: Next.js / React
- **Public Website**: Static site
- **Authoritative Backend**: Supabase (PostgreSQL 15+, PostGIS, Supabase Auth, Storage, Edge Functions, Realtime)

---

## Design System Tokens
- **Midnight Navy**: `#10264B` (Brand, headings, nav emphasis)
- **Clear Blue**: `#2463EB` (Primary buttons, active controls, routes)
- **Warm Ivory**: `#F6F4EE` (Main app background)
- **White**: `#FFFFFF` (Inputs, bottom sheets, cards)
- **Primary Text**: `#172033`
- **Secondary Text**: `#667085`
- **Border**: `#DADDE3`
- **Divider**: `#E5E7EB`
- **Map Neutral**: `#E6E9E4`
- **Success**: `#16805D`
- **Error**: `#B42318`
- **Typography**: Manrope (400, 500, 600, 700)

---

## State Transition Matrix
| Current State | Action | Next State | Required Controls |
|---|---|---|---|
| `searching` | Rider accepts current offer | `accepted` | Offer valid, rider eligible, atomic lock |
| `searching` | No eligible riders remain | `unassigned` | Dispatch lock, event & staff alert |
| `searching` | Customer or staff cancels | `cancelled` | Caller authorized, reason logged |
| `accepted` | Rider arrives at pickup | `arrived_pickup` | Assigned rider, proximity check (~150m) |
| `arrived_pickup` | Rider confirms pickup | `picked_up` | Assigned rider, valid status |
| `picked_up` | Rider arrives at drop-off | `arrived_dropoff` | Assigned rider, proximity check (~150m) |
| `arrived_dropoff` | Rider completes with code | `delivered` | Code match, lockout check, atomic wallet deduction |
| `accepted`/active | Rider cancels | `searching` or `unassigned` | Reason, exclusion list, release & re-dispatch |
| any permitted | Staff cancels | `cancelled` | Staff permission, reason & audit trail |

---

## Core Financial Model
- Cash on delivery (sender at pickup or receiver at dropoff).
- Rider keeps full cash.
- Commission deducted from rider wallet upon verified completion with 4-digit code.
- Configurable negative credit limit (default -GH₵20.00).
- All wallet movements are signed ledger transactions with idempotency keys.
