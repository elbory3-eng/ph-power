-- PH Power Coach — esquema inicial multiusuario para Supabase/PostgreSQL.
-- Ejecutar en un proyecto Supabase antes de conectar la PWA al backend.

create extension if not exists pgcrypto;

create type public.app_role as enum ('coach', 'client', 'admin');
create type public.client_status as enum ('active', 'paused', 'archived');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.app_role not null default 'client',
  full_name text not null default '',
  phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.coach_clients (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.profiles(id) on delete cascade,
  client_id uuid references public.profiles(id) on delete set null,
  display_name text not null,
  phone text,
  status public.client_status not null default 'active',
  goal text,
  current_weight_lb numeric(6,2),
  plan_name text,
  next_checkin date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (coach_id, client_id)
);

create table public.workout_templates (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  description text,
  routine jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.workout_assignments (
  id uuid primary key default gen_random_uuid(),
  coach_client_id uuid not null references public.coach_clients(id) on delete cascade,
  template_id uuid references public.workout_templates(id) on delete set null,
  routine jsonb not null default '[]'::jsonb,
  starts_on date not null default current_date,
  ends_on date,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.body_metrics (
  id uuid primary key default gen_random_uuid(),
  coach_client_id uuid not null references public.coach_clients(id) on delete cascade,
  recorded_on date not null default current_date,
  weight_lb numeric(6,2),
  body_fat_percent numeric(5,2),
  waist_cm numeric(6,2),
  notes text,
  created_at timestamptz not null default now(),
  unique (coach_client_id, recorded_on)
);

alter table public.profiles enable row level security;
alter table public.coach_clients enable row level security;
alter table public.workout_templates enable row level security;
alter table public.workout_assignments enable row level security;
alter table public.body_metrics enable row level security;

create policy "profiles_read_own" on public.profiles for select using (id = auth.uid());
create policy "profiles_update_own" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

create policy "coach_manage_clients" on public.coach_clients for all
  using (coach_id = auth.uid()) with check (coach_id = auth.uid());
create policy "client_read_relationship" on public.coach_clients for select
  using (client_id = auth.uid());

create policy "coach_manage_templates" on public.workout_templates for all
  using (coach_id = auth.uid()) with check (coach_id = auth.uid());

create policy "relationship_read_assignments" on public.workout_assignments for select
  using (exists (select 1 from public.coach_clients cc where cc.id = coach_client_id and (cc.coach_id = auth.uid() or cc.client_id = auth.uid())));
create policy "coach_manage_assignments" on public.workout_assignments for all
  using (exists (select 1 from public.coach_clients cc where cc.id = coach_client_id and cc.coach_id = auth.uid()))
  with check (exists (select 1 from public.coach_clients cc where cc.id = coach_client_id and cc.coach_id = auth.uid()));

create policy "relationship_read_metrics" on public.body_metrics for select
  using (exists (select 1 from public.coach_clients cc where cc.id = coach_client_id and (cc.coach_id = auth.uid() or cc.client_id = auth.uid())));
create policy "relationship_add_metrics" on public.body_metrics for insert
  with check (exists (select 1 from public.coach_clients cc where cc.id = coach_client_id and (cc.coach_id = auth.uid() or cc.client_id = auth.uid())));
create policy "coach_update_metrics" on public.body_metrics for update
  using (exists (select 1 from public.coach_clients cc where cc.id = coach_client_id and cc.coach_id = auth.uid()));

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, role, full_name)
  -- Nunca confiar en el rol enviado por el navegador durante el registro.
  -- Un administrador promoverá las cuentas verificadas a coach.
  values (new.id, 'client', coalesce(new.raw_user_meta_data->>'full_name', ''));
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();
