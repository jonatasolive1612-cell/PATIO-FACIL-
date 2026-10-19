-- PÁTIO FÁCIL — esquema inicial Supabase
-- Execute no SQL Editor do projeto Supabase.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null default 'porter' check (role in ('porter','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.movements (
  id uuid primary key default gen_random_uuid(),
  plate text not null check (length(plate) between 6 and 7),
  model text,
  color text,
  os_number text,
  odometer integer check (odometer is null or odometer >= 0),
  notes text,
  entry_at timestamptz not null default now(),
  exit_at timestamptz,
  entry_user uuid not null references auth.users(id),
  exit_user uuid references auth.users(id),
  entry_user_name text,
  exit_user_name text,
  exit_notes text,
  created_at timestamptz not null default now(),
  check (exit_at is null or exit_at >= entry_at)
);

-- Impede duas entradas abertas para a mesma placa.
create unique index if not exists one_open_movement_per_plate
on public.movements (plate) where exit_at is null;
create index if not exists movements_entry_at_idx on public.movements(entry_at desc);
create index if not exists movements_plate_idx on public.movements(plate);

create table if not exists public.vehicle_photos (
  id uuid primary key default gen_random_uuid(),
  movement_id uuid not null references public.movements(id) on delete cascade,
  stage text not null check (stage in ('entry','exit')),
  photo_type text not null check (photo_type in ('plate','front','rear','side')),
  storage_path text not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists vehicle_photos_movement_idx on public.vehicle_photos(movement_id);

-- Função SECURITY DEFINER evita recursão de RLS ao verificar o perfil admin.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$ select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin') $$;
grant execute on function public.is_admin() to authenticated;

alter table public.profiles enable row level security;
alter table public.movements enable row level security;
alter table public.vehicle_photos enable row level security;

-- Perfis: cada usuário autenticado pode ler os perfis necessários à operação;
-- apenas administrador pode alterar perfis.
drop policy if exists "profiles read authenticated" on public.profiles;
create policy "profiles read authenticated" on public.profiles for select to authenticated using (true);
drop policy if exists "profiles admin update" on public.profiles;
create policy "profiles admin update" on public.profiles for update to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Porteiro e administrador podem consultar e registrar movimentações.
drop policy if exists "movements read authenticated" on public.movements;
create policy "movements read authenticated" on public.movements for select to authenticated using (true);
drop policy if exists "movements insert authenticated" on public.movements;
create policy "movements insert authenticated" on public.movements for insert to authenticated with check (entry_user=auth.uid());
drop policy if exists "movements update authenticated" on public.movements;
create policy "movements update authenticated" on public.movements for update to authenticated
using (public.is_admin() or exit_at is null)
with check (true);
drop policy if exists "movements delete admin" on public.movements;
create policy "movements delete admin" on public.movements for delete to authenticated
using (public.is_admin());

-- Fotos: usuários autenticados podem registrar/consultar metadados; remoção só admin.
drop policy if exists "photos read authenticated" on public.vehicle_photos;
create policy "photos read authenticated" on public.vehicle_photos for select to authenticated using (true);
drop policy if exists "photos insert authenticated" on public.vehicle_photos;
create policy "photos insert authenticated" on public.vehicle_photos for insert to authenticated with check (created_by=auth.uid());
drop policy if exists "photos delete admin" on public.vehicle_photos;
create policy "photos delete admin" on public.vehicle_photos for delete to authenticated
using (public.is_admin());

-- Bucket privado para fotos de veículos.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('patio-photos','patio-photos',false,10485760,array['image/jpeg','image/png','image/webp','image/heic'])
on conflict (id) do update set public=false, file_size_limit=10485760;

drop policy if exists "patio photos read authenticated" on storage.objects;
create policy "patio photos read authenticated" on storage.objects for select to authenticated using (bucket_id='patio-photos');
drop policy if exists "patio photos upload authenticated" on storage.objects;
create policy "patio photos upload authenticated" on storage.objects for insert to authenticated with check (bucket_id='patio-photos');
drop policy if exists "patio photos delete admin" on storage.objects;
create policy "patio photos delete admin" on storage.objects for delete to authenticated
using (bucket_id='patio-photos' and public.is_admin());

-- Depois de criar os usuários em Authentication > Users, insira os perfis:
-- insert into public.profiles (id, full_name, role)
-- select id, 'Nome do Administrador', 'admin' from auth.users where email='admin@empresa.com';
-- insert into public.profiles (id, full_name, role)
-- select id, 'Nome do Porteiro', 'porter' from auth.users where email='porteiro@empresa.com';
