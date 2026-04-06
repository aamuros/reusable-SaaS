# SaaS Starter Template — Design Spec

**Date:** 2026-04-06  
**Status:** Approved

---

## Overview

A reusable, full-featured SaaS starter template built with a feature-based folder structure. Designed to be dropped into future software projects that are sold to customers. Covers auth, billing, user dashboard, admin panel, email, file storage plumbing, monitoring, and CI/CD.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Frontend + API | Next.js 14 (App Router) |
| Styling | Tailwind CSS + shadcn/ui |
| Auth | Supabase Auth |
| Database | Supabase (Postgres) |
| Storage | Supabase Storage (plumbing only) |
| Payments | Paymongo (subscriptions + one-time) |
| Email | Resend |
| Monitoring | Sentry |
| Hosting | Railway (single service) |
| CI/CD | GitHub Actions |

---

## Architecture

### Approach
Single Next.js monolith deployed to Railway as one service. Business logic is organized into self-contained feature modules so individual features can be lifted and dropped into future projects.

### Folder Structure

```
src/
  app/
    (marketing)/              # Public landing page
    (auth)/                   # Clerk sign-in/sign-up pages
    (dashboard)/              # Protected user area
    (admin)/                  # Protected admin area
    (moderator)/              # Protected moderator area
    api/                      # API route handlers
  features/
    auth/                     # Clerk hooks, middleware, role helpers
    billing/                  # Paymongo logic, webhooks, plan config
    users/                    # User profile, role management
    admin/                    # Admin panel logic, feature flags, coupons
    email/                    # Resend templates and send helpers
    storage/                  # Supabase Storage setup and helpers
  lib/                        # Shared clients (supabase, clerk, sentry, resend)
  components/                 # Shared UI components (shadcn/ui base)
  types/                      # Shared TypeScript types
```

### Data Flow
1. Clerk issues a JWT on login
2. Next.js middleware validates JWT on every request and reads role from `publicMetadata`
3. User's Clerk ID is stored in Supabase `users` table
4. All DB queries are scoped by Clerk user ID
5. Paymongo webhooks hit `/api/billing/webhook` → update subscription status in Supabase
6. Clerk webhooks hit `/api/auth/webhook` → sync user to Supabase, send welcome email

---

## Authentication & Roles

**Provider:** Supabase Auth handles all auth — sign up, sign in, forgot password, email verification, OAuth (Google, GitHub optional), session management. Built into Supabase, no extra cost or third-party service.

### Role System

Roles are stored in the `profiles` table in Supabase. The `profiles` table row is auto-created on sign-up via a database trigger. Role is read server-side on protected routes.

| Role | Access |
|---|---|
| `user` | Dashboard, own profile, billing, file uploads |
| `moderator` | Above + view all users, suspend/ban users |
| `admin` | Above + full admin panel, feature flags, coupons, revenue dashboard |

### Role Assignment
- First sign-up → Supabase Auth trigger → `profiles` row auto-created with role `user`
- Admins can promote/demote from admin panel → server action updates `profiles.role` in Supabase

### Route Protection

```
/dashboard/*     → requires any authenticated user
/moderator/*     → requires role: moderator or admin
/admin/*         → requires role: admin
```

---

## Billing

### Payment Types
- **Subscriptions:** Monthly or annual recurring plans via Paymongo
- **One-time payments:** Lifetime access or single purchases via Paymongo

### Plans

| Plan | Billing Options |
|---|---|
| Free | No charge |
| Basic | Monthly or Annual (discounted) |
| Pro | Monthly or Annual (discounted) |
| Enterprise | Monthly or Annual (discounted) |

Plans are stored in Supabase and editable from the admin panel.

### Checkout Flow
1. User selects plan + billing period on pricing page
2. Frontend calls `/api/billing/checkout` → creates Paymongo payment intent or subscription
3. User completes payment on Paymongo-hosted page
4. Paymongo fires webhook to `/api/billing/webhook` → updates Supabase
5. User's plan is reflected in dashboard and controls feature access

### Supabase Schema

```sql
plans           — id, name, price_monthly, price_annual, features (jsonb), is_active
subscriptions   — id, user_id (→ profiles), plan_id, status, paymongo_subscription_id, period_end
purchases       — id, user_id (→ profiles), product, amount, paymongo_payment_id, created_at
```

---

## Admin Panel

**Access:** `admin` role only at `/admin/*`.

| Section | Features |
|---|---|
| **Users** | List, search/filter, view profile, change role, suspend/ban |
| **Payments** | View all subscriptions and purchases, filter by plan/status |
| **Emails** | Send bulk emails to user segments |
| **Audit Log** | Timestamped log of all admin actions |
| **Feature Flags** | Toggle features on/off per user or per plan |
| **Coupons** | Create discount codes (% or fixed), expiry, usage limits |
| **Revenue Dashboard** | MRR, total revenue, new subscribers chart, churn |

**Moderator panel** at `/moderator/*` — users list + suspend/ban only. No billing, flags, or coupons.

### Supabase Schema

```sql
audit_logs      — id, admin_id (→ profiles), action, target_id, metadata (jsonb), created_at
feature_flags   — id, name, enabled_for_plans (jsonb), enabled_for_users (jsonb)
coupons         — id, code, discount_type, discount_value, expires_at, max_uses, use_count
```

---

## Email

**Provider:** Resend with React Email templates.

### Triggers & Templates

| Trigger | Template |
|---|---|
| Sign up (Supabase Auth trigger) | Welcome email |
| Subscription started | Payment confirmation + plan details |
| Subscription renewed | Renewal receipt |
| Subscription cancelled | Cancellation confirmation |
| Payment failed | Failed payment notice + retry link |
| One-time purchase | Purchase receipt |
| Admin bulk email | Custom message to user segment |
| Password reset | Handled natively by Supabase Auth |

### Structure

```
features/email/
  templates/
    welcome.tsx
    payment-confirmation.tsx
    renewal-receipt.tsx
    cancellation.tsx
    payment-failed.tsx
    purchase-receipt.tsx
    bulk-email.tsx
  send.ts       — typed send() helper wrapping Resend SDK
```

All emails are sent server-side only. Sending errors are caught and logged to Sentry.

---

## Landing Page

**Route:** `/` (public)

### Sections

| Section | Content |
|---|---|
| Navbar | Logo, nav links, Sign In + Get Started buttons |
| Hero | Headline, subheadline, CTA button |
| Features | 3–6 feature cards with icons |
| Pricing | Monthly/annual toggle, plan cards, CTA per plan |
| Testimonials | 3–6 quote cards with avatar, name, role |
| FAQ | Accordion, 5–8 questions |
| Footer | Logo, nav links, social links, Privacy + Terms |

### Pricing Table Behavior
- Monthly/annual toggle in local React state
- Plan data fetched from Supabase `plans` table at build time (SSG with revalidation)
- Annual prices show "Save X%" badge
- CTA routes to `/sign-up` or directly to checkout

### Additional Public Pages

```
/pricing          — standalone pricing page
/privacy          — static legal page
/terms            — static legal page
```

---

## Monitoring & CI/CD

### Sentry
- Installed in client and server via Next.js SDK
- Captures unhandled exceptions, API errors, slow transactions
- Custom error boundary wraps dashboard and admin panel
- Webhook errors explicitly caught and sent to Sentry with context

### GitHub Actions

```yaml
On pull request:
  - Install dependencies
  - Type check (tsc --noEmit)
  - Lint (eslint)
  - Run tests (vitest)

On merge to main:
  - All of the above
  - Deploy to Railway
```

### Testing
- `vitest` for unit tests
- Example tests for: billing webhook handler, role middleware, email send helper
- No E2E tests in v1

---

## Environment Variables

```bash
# Supabase (Auth + Database + Storage)
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# Paymongo
PAYMONGO_SECRET_KEY=
PAYMONGO_WEBHOOK_SECRET=

# Resend
RESEND_API_KEY=

# Sentry
SENTRY_DSN=

# App
NEXT_PUBLIC_APP_URL=
```

---

## Out of Scope (v1)

- Blog / changelog
- Mobile app
- Multi-tenancy (organizations)
- E2E tests
- Internationalization (i18n)
