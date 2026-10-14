-- ONE STORE, NO LOGIN: anyone who knows the public app URL can read and MODIFY all data.
-- Run this in a NEW Supabase project (or review existing policies before migration).
create extension if not exists pgcrypto;
create table if not exists public.shelves (id uuid primary key default gen_random_uuid(), name text not null unique, image_path text, updated_at timestamptz not null default now());
create table if not exists public.medicines (id uuid primary key default gen_random_uuid(), shelf_id uuid not null references public.shelves(id) on delete cascade, name text not null, strength text not null default '', note text not null default '', x numeric not null check(x>=0 and x<=100), y numeric not null check(y>=0 and y<=100), w numeric not null check(w>0 and w<=100), h numeric not null check(h>0 and h<=100), confirmed boolean not null default false, updated_at timestamptz not null default now(), check(x+w<=100.01 and y+h<=100.01));
create index if not exists medicines_name_idx on public.medicines (name);
create index if not exists medicines_shelf_idx on public.medicines (shelf_id);
alter table public.shelves enable row level security;
alter table public.medicines enable row level security;
-- Remove older policies on these two tables if you previously installed the authenticated version.
do $$ declare r record; begin for r in select schemaname,tablename,policyname from pg_policies where schemaname='public' and tablename in ('shelves','medicines') loop execute format('drop policy if exists %I on %I.%I',r.policyname,r.schemaname,r.tablename); end loop; end $$;
create policy "public shelves read" on public.shelves for select to anon using (true);
create policy "public shelves insert" on public.shelves for insert to anon with check (true);
create policy "public shelves update" on public.shelves for update to anon using (true) with check (true);
create policy "public shelves delete" on public.shelves for delete to anon using (true);
create policy "public medicines read" on public.medicines for select to anon using (true);
create policy "public medicines insert" on public.medicines for insert to anon with check (true);
create policy "public medicines update" on public.medicines for update to anon using (true) with check (true);
create policy "public medicines delete" on public.medicines for delete to anon using (true);
grant usage on schema public to anon;
grant select,insert,update,delete on public.shelves,public.medicines to anon;
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types) values ('shelf-images','shelf-images',false,10485760,array['image/jpeg','image/png','image/webp']) on conflict (id) do nothing;
do $$ declare r record; begin for r in select policyname from pg_policies where schemaname='storage' and tablename='objects' and (qual like '%shelf-images%' or with_check like '%shelf-images%') loop execute format('drop policy if exists %I on storage.objects',r.policyname); end loop; end $$;
create policy "public shelf image read" on storage.objects for select to anon using (bucket_id='shelf-images');
create policy "public shelf image insert" on storage.objects for insert to anon with check (bucket_id='shelf-images');
create policy "public shelf image update" on storage.objects for update to anon using (bucket_id='shelf-images') with check (bucket_id='shelf-images');
create policy "public shelf image delete" on storage.objects for delete to anon using (bucket_id='shelf-images');
insert into public.shelves (name) values ('棚A') on conflict (name) do nothing;
