# Phase 1: Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the full Next.js project with feature-based folder structure, shared library clients (Supabase, Resend, Sentry), Supabase database schema with auth tables, and all environment variable plumbing — ready for feature development.

**Architecture:** A single Next.js 14 App Router monolith using a feature-based folder structure under `src/features/`. Shared third-party clients live in `src/lib/`. Authentication is handled by Supabase Auth (built-in). No business logic in this phase — only wiring and schema.

**Tech Stack:** Next.js 14, TypeScript, Tailwind CSS, shadcn/ui, Supabase (Postgres + Auth), Resend, Sentry, Vitest

---

### Task 1: Initialize Next.js Project

**Files:**
- Create: `package.json`, `tsconfig.json`, `next.config.ts`, `tailwind.config.ts`, `postcss.config.mjs`, `src/app/layout.tsx`, `src/app/page.tsx`

- [ ] **Step 1: Scaffold Next.js app**

```bash
npx create-next-app@latest . \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --no-turbopack
```

Accept all defaults when prompted.

- [ ] **Step 2: Verify it runs**

```bash
npm run dev
```

Expected: Server starts at `http://localhost:3000` with no errors.

- [ ] **Step 3: Commit**

```bash
git add .
git commit -m "chore: initialize Next.js 14 project with TypeScript and Tailwind"
```

---

### Task 2: Install Core Dependencies

**Files:**
- Modify: `package.json`

- [ ] **Step 1: Install all dependencies**

```bash
npm install \
  @supabase/supabase-js \
  @supabase/ssr \
  resend \
  @sentry/nextjs \
  @react-email/components \
  react-email

npm install -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/jest-dom
```

- [ ] **Step 2: Verify installation**

```bash
npm ls @supabase/supabase-js @supabase/ssr resend @sentry/nextjs
```

Expected: All packages listed with version numbers, no peer dependency errors.

- [ ] **Step 3: Commit**

```bash
git add package.json package-lock.json
git commit -m "chore: install core dependencies (supabase, supabase-ssr, resend, sentry, vitest)"
```

---

### Task 3: Install and Initialize shadcn/ui

**Files:**
- Create: `components.json`, `src/lib/utils.ts`, `src/components/ui/` (populated by shadcn)

- [ ] **Step 1: Initialize shadcn/ui**

```bash
npx shadcn@latest init
```

When prompted:
- Style: **Default**
- Base color: **Slate**
- CSS variables: **Yes**

- [ ] **Step 2: Install base components used throughout the project**

```bash
npx shadcn@latest add button card input label badge separator avatar dropdown-menu dialog accordion table tabs toast
```

- [ ] **Step 3: Verify components exist**

```bash
ls src/components/ui/
```

Expected: `button.tsx`, `card.tsx`, `input.tsx`, etc.

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "chore: initialize shadcn/ui with base components"
```

---

### Task 4: Set Up Folder Structure

**Files:**
- Create: All directories and placeholder `index.ts` files listed below

- [ ] **Step 1: Create feature-based folder structure**

```bash
mkdir -p src/features/auth
mkdir -p src/features/billing
mkdir -p src/features/users
mkdir -p src/features/admin
mkdir -p src/features/email/templates
mkdir -p src/features/storage
mkdir -p src/lib
mkdir -p src/types
mkdir -p src/app/\(marketing\)
mkdir -p src/app/\(auth\)
mkdir -p src/app/\(dashboard\)
mkdir -p src/app/\(admin\)
mkdir -p src/app/\(moderator\)
mkdir -p src/app/api/auth
mkdir -p src/app/api/billing
```

- [ ] **Step 2: Add placeholder barrel files so TypeScript resolves imports**

```bash
touch src/features/auth/index.ts
touch src/features/billing/index.ts
touch src/features/users/index.ts
touch src/features/admin/index.ts
touch src/features/email/index.ts
touch src/features/storage/index.ts
touch src/types/index.ts
```

- [ ] **Step 3: Commit**

```bash
git add .
git commit -m "chore: scaffold feature-based folder structure"
```

---

### Task 5: Configure Environment Variables

**Files:**
- Create: `.env.local`, `.env.example`, `.gitignore` (modify)

- [ ] **Step 1: Create `.env.example`**

Create file `/.env.example`:

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
NEXT_PUBLIC_SENTRY_DSN=

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

- [ ] **Step 2: Create `.env.local` from the example**

```bash
cp .env.example .env.local
```

Fill in real values in `.env.local` for local development. Leave blank if you don't have the key yet — clients will be initialized lazily.

- [ ] **Step 3: Ensure `.env.local` is in `.gitignore`**

Open `.gitignore` and verify this line exists (it should be there by default from create-next-app):

```
.env.local
```

- [ ] **Step 4: Commit**

```bash
git add .env.example .gitignore
git commit -m "chore: add environment variable template"
```

---

### Task 6: Create Shared Library Clients

**Files:**
- Create: `src/lib/supabase/client.ts`
- Create: `src/lib/supabase/server.ts`
- Create: `src/lib/supabase/admin.ts`
- Create: `src/lib/resend.ts`
- Create: `src/types/index.ts`

- [ ] **Step 1: Write the test first**

Create `src/lib/__tests__/clients.test.ts`:

```typescript
import { describe, it, expect } from 'vitest'

describe('lib clients', () => {
  it('supabase browser client is defined', async () => {
    process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://test.supabase.co'
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = 'test-anon-key'
    const { createBrowserClient } = await import('../supabase/client')
    const client = createBrowserClient()
    expect(client).toBeDefined()
  })

  it('resend client is defined', async () => {
    process.env.RESEND_API_KEY = 'test-resend-key'
    const { resend } = await import('../resend')
    expect(resend).toBeDefined()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run src/lib/__tests__/clients.test.ts
```

Expected: FAIL — modules not found.

- [ ] **Step 3: Create Supabase browser client**

Create `src/lib/supabase/client.ts`:

```typescript
import { createBrowserClient as createSupabaseBrowserClient } from '@supabase/ssr'
import type { Database } from '@/types'

export function createBrowserClient() {
  return createSupabaseBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

- [ ] **Step 4: Create Supabase server client (for Server Components and API routes)**

Create `src/lib/supabase/server.ts`:

```typescript
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/types'

export async function createServerSupabaseClient() {
  const cookieStore = await cookies()
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Ignore: called from Server Component where cookies can't be set
          }
        },
      },
    }
  )
}
```

- [ ] **Step 5: Create Supabase admin client (service role — bypasses RLS)**

Create `src/lib/supabase/admin.ts`:

```typescript
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types'

export function createAdminSupabaseClient() {
  return createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  )
}
```

- [ ] **Step 6: Create Resend client**

Create `src/lib/resend.ts`:

```typescript
import { Resend } from 'resend'

export const resend = new Resend(process.env.RESEND_API_KEY)
```

- [ ] **Step 7: Create shared TypeScript types**

Create `src/types/index.ts`:

```typescript
export type UserRole = 'user' | 'moderator' | 'admin'

export type PlanName = 'free' | 'basic' | 'pro' | 'enterprise'

export type BillingPeriod = 'monthly' | 'annual'

export type SubscriptionStatus = 'active' | 'cancelled' | 'past_due' | 'trialing'

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          email: string
          role: UserRole
          is_suspended: boolean
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['profiles']['Row'], 'created_at' | 'updated_at'>
        Update: Partial<Database['public']['Tables']['profiles']['Insert']>
      }
      plans: {
        Row: {
          id: string
          name: PlanName
          price_monthly: number
          price_annual: number
          features: string[]
          is_active: boolean
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['plans']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['plans']['Insert']>
      }
      subscriptions: {
        Row: {
          id: string
          user_id: string
          plan_id: string
          status: SubscriptionStatus
          paymongo_subscription_id: string | null
          period_end: string | null
          billing_period: BillingPeriod
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['subscriptions']['Row'], 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Database['public']['Tables']['subscriptions']['Insert']>
      }
      purchases: {
        Row: {
          id: string
          user_id: string
          product: string
          amount: number
          paymongo_payment_id: string
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['purchases']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['purchases']['Insert']>
      }
      audit_logs: {
        Row: {
          id: string
          admin_id: string
          action: string
          target_id: string | null
          metadata: Record<string, unknown>
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['audit_logs']['Row'], 'id' | 'created_at'>
        Update: never
      }
      feature_flags: {
        Row: {
          id: string
          name: string
          enabled_for_plans: PlanName[]
          enabled_for_users: string[]
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['feature_flags']['Row'], 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Database['public']['Tables']['feature_flags']['Insert']>
      }
      coupons: {
        Row: {
          id: string
          code: string
          discount_type: 'percent' | 'fixed'
          discount_value: number
          expires_at: string | null
          max_uses: number | null
          use_count: number
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['coupons']['Row'], 'id' | 'use_count' | 'created_at'>
        Update: Partial<Database['public']['Tables']['coupons']['Insert']>
      }
    }
  }
}
```

- [ ] **Step 8: Run test to verify it passes**

```bash
npx vitest run src/lib/__tests__/clients.test.ts
```

Expected: PASS — both tests green.

- [ ] **Step 9: Commit**

```bash
git add src/lib/ src/types/
git commit -m "feat: add shared supabase (browser/server/admin), resend clients and TypeScript types"
```

---

### Task 7: Configure Vitest

**Files:**
- Create: `vitest.config.ts`
- Modify: `package.json`

- [ ] **Step 1: Create vitest config**

Create `vitest.config.ts`:

```typescript
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    globals: true,
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
})
```

- [ ] **Step 2: Create test setup file**

```bash
mkdir -p src/test
```

Create `src/test/setup.ts`:

```typescript
import '@testing-library/jest-dom'
```

- [ ] **Step 3: Add test scripts to package.json**

Open `package.json` and add to the `"scripts"` section:

```json
"test": "vitest run",
"test:watch": "vitest",
"test:ui": "vitest --ui"
```

- [ ] **Step 4: Run all tests**

```bash
npm test
```

Expected: PASS — the 2 client tests from Task 6 pass.

- [ ] **Step 5: Commit**

```bash
git add vitest.config.ts src/test/ package.json
git commit -m "chore: configure vitest with jsdom and testing-library"
```

---

### Task 8: Configure Sentry

**Files:**
- Create: `sentry.client.config.ts`
- Create: `sentry.server.config.ts`
- Modify: `next.config.ts`

- [ ] **Step 1: Run Sentry wizard**

```bash
npx @sentry/wizard@latest -i nextjs
```

When prompted:
- Select: **Next.js**
- Create new Sentry project or use existing — use your DSN
- Enable performance monitoring: **Yes**
- Enable session replay: **No** (keeps it lean)

This will auto-create `sentry.client.config.ts`, `sentry.server.config.ts`, and update `next.config.ts`.

- [ ] **Step 2: Verify Sentry files exist**

```bash
ls sentry.*.config.ts
```

Expected: `sentry.client.config.ts  sentry.server.config.ts`

- [ ] **Step 3: Verify `NEXT_PUBLIC_SENTRY_DSN` is used in the config**

Open `sentry.client.config.ts` and confirm it reads from `process.env.NEXT_PUBLIC_SENTRY_DSN` or `process.env.SENTRY_DSN`.

- [ ] **Step 4: Commit**

```bash
git add sentry.client.config.ts sentry.server.config.ts next.config.ts
git commit -m "chore: configure Sentry for Next.js"
```

---

### Task 9: Create Supabase Database Schema

**Files:**
- Create: `supabase/migrations/001_initial_schema.sql`

- [ ] **Step 1: Create migrations folder**

```bash
mkdir -p supabase/migrations
```

- [ ] **Step 2: Write the initial schema migration**

Create `supabase/migrations/001_initial_schema.sql`:

```sql
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Profiles table (extends Supabase Auth's auth.users)
-- id matches auth.users.id — no separate sync needed
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  role text not null default 'user' check (role in ('user', 'moderator', 'admin')),
  is_suspended boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Plans table
create table public.plans (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique check (name in ('free', 'basic', 'pro', 'enterprise')),
  price_monthly integer not null default 0, -- in cents
  price_annual integer not null default 0,  -- in cents
  features jsonb not null default '[]',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Subscriptions table
create table public.subscriptions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan_id uuid not null references public.plans(id),
  status text not null check (status in ('active', 'cancelled', 'past_due', 'trialing')),
  billing_period text not null check (billing_period in ('monthly', 'annual')),
  paymongo_subscription_id text,
  period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Purchases table (one-time payments)
create table public.purchases (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product text not null,
  amount integer not null, -- in cents
  paymongo_payment_id text not null unique,
  created_at timestamptz not null default now()
);

-- Audit logs table
create table public.audit_logs (
  id uuid primary key default uuid_generate_v4(),
  admin_id uuid not null references public.profiles(id),
  action text not null,
  target_id uuid,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- Feature flags table
create table public.feature_flags (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  enabled_for_plans jsonb not null default '[]',
  enabled_for_users jsonb not null default '[]',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Coupons table
create table public.coupons (
  id uuid primary key default uuid_generate_v4(),
  code text not null unique,
  discount_type text not null check (discount_type in ('percent', 'fixed')),
  discount_value integer not null, -- percent: 0-100, fixed: in cents
  expires_at timestamptz,
  max_uses integer,
  use_count integer not null default 0,
  created_at timestamptz not null default now()
);

-- Seed default plans
insert into public.plans (name, price_monthly, price_annual, features, is_active) values
  ('free',       0,      0,      '["Up to 3 projects", "Community support"]', true),
  ('basic',      999,    9990,   '["Up to 10 projects", "Email support", "Basic analytics"]', true),
  ('pro',        2999,   29990,  '["Unlimited projects", "Priority support", "Advanced analytics", "API access"]', true),
  ('enterprise', 9999,   99990,  '["Everything in Pro", "SSO", "SLA", "Dedicated support"]', true);

-- Auto-update updated_at timestamps
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at before update on public.profiles
  for each row execute function update_updated_at();

create trigger subscriptions_updated_at before update on public.subscriptions
  for each row execute function update_updated_at();

create trigger feature_flags_updated_at before update on public.feature_flags
  for each row execute function update_updated_at();

-- Auto-create profile on sign-up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.plans enable row level security;
alter table public.subscriptions enable row level security;
alter table public.purchases enable row level security;
alter table public.audit_logs enable row level security;
alter table public.feature_flags enable row level security;
alter table public.coupons enable row level security;

-- Plans are publicly readable (for pricing page)
create policy "Plans are publicly readable" on public.plans
  for select using (is_active = true);

-- Service role bypasses RLS (used by server-side Supabase client)
-- All other access goes through the service role key server-side
-- No additional RLS policies needed for this template — all queries run server-side
```

- [ ] **Step 3: Apply migration to your Supabase project**

In the Supabase dashboard for your project, go to **SQL Editor** and paste + run the contents of `supabase/migrations/001_initial_schema.sql`.

Alternatively, if you have the Supabase CLI installed:

```bash
supabase db push
```

- [ ] **Step 4: Verify tables exist in Supabase dashboard**

Go to **Table Editor** in Supabase and confirm these tables exist:
`profiles`, `plans`, `subscriptions`, `purchases`, `audit_logs`, `feature_flags`, `coupons`

Also confirm `plans` table has 4 rows (free, basic, pro, enterprise).

- [ ] **Step 5: Commit**

```bash
git add supabase/
git commit -m "feat: add initial Supabase database schema with all tables and seed data"
```

---

### Task 10: Final Push to GitHub

- [ ] **Step 1: Verify all tests pass**

```bash
npm test
```

Expected: All tests PASS.

- [ ] **Step 2: Verify build passes**

```bash
npm run build
```

Expected: Build completes with no type errors.

- [ ] **Step 3: Push to GitHub**

```bash
git push -u origin main
```

Expected: All commits pushed to `https://github.com/aamuros/reusable-SaaS`.

---

## Self-Review

**Spec coverage:**
- ✅ Next.js 14 App Router project
- ✅ Feature-based folder structure
- ✅ Supabase client (browser + server + admin)
- ✅ Supabase Auth (built-in, no external provider needed)
- ✅ Resend client
- ✅ Sentry
- ✅ TypeScript types for all DB tables
- ✅ Full Supabase schema (all 7 tables + seed data)
- ✅ `.env.example` with all keys
- ✅ Vitest configured
- ✅ shadcn/ui initialized with base components
- ✅ Git + GitHub push

**Placeholder scan:** None found — all steps have explicit commands and code.

**Type consistency:** `Database` type in `src/types/index.ts` is referenced consistently in `src/lib/supabase/client.ts`, `server.ts`, and `admin.ts`. `profiles` table uses `id` referencing `auth.users(id)` — no `clerk_id` column. `UserRole`, `PlanName`, `BillingPeriod`, `SubscriptionStatus` match SQL constraints exactly.
