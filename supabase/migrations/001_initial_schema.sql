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
